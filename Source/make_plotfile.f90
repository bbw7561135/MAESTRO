module make_plotfile_module

  use bl_error_module
  use bl_string_module
  use bl_IO_module
  use bl_types
  use fab_module
  use fabio_module
  use boxarray_module
  use ml_boxarray_module
  use multifab_module
  use parallel
  use vort_module
  use geometry
  use variables
  use plot_variables_module

  use variables

  implicit none

contains

  subroutine get_plot_names(dm,ntrac,plot_names,plot_spec,plot_trac)

    integer          , intent(in   ) :: dm,ntrac
    logical          , intent(in   ) :: plot_spec,plot_trac
    character(len=20), intent(inout) :: plot_names(:)

    ! Local variables
    integer :: n

    plot_names(icomp_vel  ) = "x_vel"
    plot_names(icomp_vel+1) = "y_vel"
    if (dm > 2) &
      plot_names(icomp_vel+2) = "z_vel"
    plot_names(icomp_rho)  = "density"
    plot_names(icomp_rhoh) = "rhoh"

    if (plot_spec) then
      do n = 1, nspec
         plot_names(icomp_spec+n-1) = "X(" // trim(short_spec_names(n)) // ")"
      enddo
    end if

    if (plot_trac) then
      do n = 1, ntrac
       plot_names(icomp_trac+n-1) = "tracer"
      enddo
    end if

    plot_names(icomp_magvel)   = "magvel"
    plot_names(icomp_mom)      = "momentum"
    plot_names(icomp_vort)     = "vort"
    plot_names(icomp_enthalpy) = "enthalpy"
    plot_names(icomp_rhopert)  = "rhopert"
    plot_names(icomp_tfromrho) = "tfromrho"
    plot_names(icomp_tfromH)   = "tfromH"
    plot_names(icomp_tpert)    = "tpert"
    plot_names(icomp_machno)   = "Machnumber"
    plot_names(icomp_dp)       = "deltap"
    plot_names(icomp_dg)       = "deltagamma"
    plot_names(icomp_spert)    = "spert"
    plot_names(icomp_dT)       = "deltaT"
    plot_names(icomp_sponge)   = "sponge"
    plot_names(icomp_gp)       = "gpx"
    plot_names(icomp_gp+1)     = "gpy"
    if (dm > 2) plot_names(icomp_gp+2) = "gpz"

    if (plot_spec) then
      do n = 1, nspec
         plot_names(icomp_omegadot+n-1) = "omegadot(" // trim(short_spec_names(n)) // ")"
      enddo
      plot_names(icomp_enuc) = "enucdot"
    end if

  end subroutine get_plot_names

  subroutine make_plotfile(istep,plotdata,u,s,gp,rho_omegadot,sponge, &
                           mba,plot_names,time,dx, &
                           the_bc_tower, &
                           s0,p0,temp0,ntrac,plot_spec,plot_trac)

    integer          , intent(in   ) :: istep
    integer          , intent(in   ) :: ntrac
    type(multifab)   , intent(inout) :: plotdata(:)
    type(multifab)   , intent(inout) :: u(:)
    type(multifab)   , intent(in   ) :: s(:)
    type(multifab)   , intent(in   ) :: gp(:)
    type(multifab)   , intent(in   ) :: rho_omegadot(:)
    type(multifab)   , intent(in   ) :: sponge(:)
    type(ml_boxarray), intent(in   ) :: mba
    character(len=20), intent(in   ) :: plot_names(:)
    real(dp_t)       , intent(in   ) :: time,dx(:,:)
    type(bc_tower)   , intent(in   ) :: the_bc_tower
    real(dp_t)       , intent(in   ) :: s0(0:,:),p0(0:)
    real(dp_t)       , intent(inout) :: temp0(0:)
    logical          , intent(in   ) :: plot_spec,plot_trac

    integer :: n,dm,nlevs
    character(len=7) :: sd_name

    dm = get_dim(mba)
    nlevs = size(plotdata)

    do n = 1,nlevs

       ! VELOCITY 
       call multifab_copy_c(plotdata(n),icomp_vel,u(n),1,dm)

       ! DENSITY AND (RHO H) 
       call multifab_copy_c(plotdata(n),icomp_rho,s(n),rho_comp,2)

       ! SPECIES
       if (plot_spec) &
         call make_XfromrhoX(plotdata(n),icomp_spec,s(n))

       ! TRACER
       if (plot_trac .and. ntrac .ge. 1) then
         call multifab_copy_c(plotdata(n),icomp_trac,s(n),trac_comp,ntrac)
       end if

       ! MAGVEL & MOMENTUM
       call make_magvel (plotdata(n),icomp_magvel,icomp_mom,u(n),s(n))

       ! VORTICITY
       call make_vorticity (plotdata(n),icomp_vort,u(n),dx(n,:), &
                            the_bc_tower%bc_tower_array(n))

       ! ENTHALPY 
       call make_enthalpy  (plotdata(n),icomp_enthalpy,s(n))

    end do

    if (spherical .eq. 1) then

      do n = 1,nlevs

       ! RHOPERT & TEMP (FROM RHO) & TPERT & MACHNO & (GAM1 - GAM10)
       call make_tfromrho  (plotdata(n),icomp_tfromrho,icomp_tpert,icomp_rhopert, &
                            icomp_machno,icomp_dg,icomp_spert, &
                            s(n),u(n),s0,temp0,p0,dx(n,:))

       ! TEMP (FROM H) & DELTA_P
       call make_tfromH    (plotdata(n),icomp_tfromH,icomp_dp,s(n),p0,temp0,dx(n,:))

       ! DIFF BETWEEN TFROMRHO AND TFROMH
       call make_deltaT (plotdata(n),icomp_dT,icomp_tfromrho,icomp_tfromH)

      end do

    else

      do n = 1,nlevs

       ! RHOPERT & TEMP (FROM RHO) & TPERT & MACHNO & (GAM1 - GAM10)
       call make_tfromrho  (plotdata(n),icomp_tfromrho,icomp_tpert,icomp_rhopert, &
                            icomp_machno,icomp_dg,icomp_spert, &
                            s(n),u(n),s0,temp0,p0,dx(n,:))

       ! TEMP (FROM H) & DELTA_P
       call make_tfromH    (plotdata(n),icomp_tfromH,icomp_dp,s(n),p0,temp0,dx(n,:))

       ! DIFF BETWEEN TFROMRHO AND TFROMH
       call make_deltaT (plotdata(n),icomp_dT,icomp_tfromrho,icomp_tfromH)

      end do

    end if

    do n = 1,nlevs

      ! PRESSURE GRADIENT
      call multifab_copy_c(plotdata(n),icomp_gp,gp(n),1,dm)

    end do


    if (plot_spec) then
      ! OMEGADOT
      do n = 1,nlevs
       call make_omegadot(plotdata(n),icomp_omegadot,icomp_enuc,s(n),rho_omegadot(n))
      enddo
    end if

    do n = 1,nlevs

       ! SPONGE
       call multifab_copy_c(plotdata(n),icomp_sponge,sponge(n),1,1)

    enddo

    write(unit=sd_name,fmt='("plt",i4.4)') istep
    call fabio_ml_multifab_write_d(plotdata, mba%rr(:,1), sd_name, plot_names, &
                                   mba%pd(1), time, dx(1,:))

  end subroutine make_plotfile

end module make_plotfile_module
