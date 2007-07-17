module thermal_conduct_module

  use bl_types
  use bc_module
  use multifab_module
  use boxarray_module
  use stencil_module
  use macproject_module

  implicit none

contains 

! Crank-Nicholson solve for enthalpy, taking into account only the
! enthalpy-diffusion terms in the temperature conduction term.
! See paper IV, steps 4a and 8a.
subroutine thermal_conduct(mla,dx,s2)

  type(ml_layout), intent(inout) :: mla
  real(dp_t)     , intent(in   ) :: dx(:,:)
  type(multifab) , intent(inout) :: s2(:)

! Local
  type(multifab), allocatable :: rh(:),phi(:),alpha(:),beta(:)
  integer                     :: n,nlevs

  print *,'... Entering thermal_conduct ...'

  nlevs = mla%nlevel

  allocate(rh(nlevs),phi(nlevs),alpha(nlevs),beta(nlevs))
  do n = 1,nlevs
     call multifab_build(   rh(n), mla%la(n), 1, 0)
     call multifab_build(  phi(n), mla%la(n), 1, 1)
     call multifab_build(alpha(n), mla%la(n), 1, 1)
     call multifab_build( beta(n), mla%la(n), 1, 1)
  end do

  print *,'... Setting alpha = rho ...'
  ! Copy rho directly into alpha


  print *,'... Setting beta ...'
  ! Compute kappa


  ! Compute c_p


  ! Create beta


  print *,'... Making RHS ...'
  ! Compute kappa (if needed)


  ! Compute c_p (if needed)


  ! Create RHS

  print *,'... Calling solver ...'
  ! Call the big solve to get updated h



  ! Compute updated \rho h



end subroutine thermal_conduct

end module thermal_conduct_module
