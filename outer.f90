module outer
    use kind_type
    use global 
    implicit none
    complex(dp), save, allocatable, private, protected :: outer_f(:)
contains 
    

subroutine mat_f 
    use math_const, only: i => math_i
    real   (dp) :: k, tmp1, tmp2 
    integer(i4) :: j 

    k = (2.d0*Mass*Kinet)**0.50
    do j = 0, L 
        tmp1 = aimag(S(j))/2.d0 
        tmp2 = (1.d0 -real(S(j)))/2.d0 
        outer_f(j) = (2.d0*dble(j) +1.d0)/k*(tmp1 +i*tmp2)
!         outer_f(j) = 1.d0/(2.d0*i*k)*(2.d0*dble(j) +1.d0)*(S(j) -1.d0)
    end do 
end subroutine mat_f 


function outer_u(l, r)
    use gsl_special, only: gsl_sf_bessel_jsl, gsl_sf_bessel_ysl
    integer(i4), intent(in) :: l 
    real   (dp), intent(in) :: r 
    real   (dp) :: kr, sb_j, sb_y
    complex(dp) :: outer_u

    kr = (2.d0*Mass*Kinet)**0.5d0*r
    sb_j = gsl_sf_bessel_jsl(l, kr)
    sb_y = gsl_sf_bessel_ysl(l, kr)

    outer_u = A(l)*(sb_j -K(l)*sb_y)*r 
end function outer_u










! ==================================================
! PROCESS
! ==================================================


subroutine PROC_CS_achive(j)
    use math_const, only: pi => math_pi
    character(30), parameter  :: form_out = '(1A15, 5X, 1ES25.10)'
    integer  (i4), intent(in) :: j 
    real     (dp) :: k 
    complex  (qp) :: sum 
    complex  (dp) :: tmp 
    integer  (i4) :: i

    allocate(outer_f(0:L))
    call mat_f 

    sum = 0.d0 
    k   = (2.d0*Mass*Kinet)**0.50
    do i = 0, L 
        tmp = 4.d0*pi/k*outer_f(i)
        sum = sum +tmp 
    end do 
    tmp   = sum 
    CS(j) = aimag(tmp)
    write(file_log, form_out) "total sigma: ", aimag(tmp)
    deallocate(outer_f)
end subroutine PROC_CS_achive


subroutine PROC_CS_plot 
    use math_const,  only: pi => math_pi, degree => math_degree
    use hamiltonian, only: coord_r, coord_theta
    use gsl_special, only: gsl_sf_legendre_Pl
    integer  (i1), parameter :: file_dcs = 101,           file_tcs = 102 
    character(30), parameter :: form_dcs = '(30ES25.10)', form_tcs = '(30ES25.10)'
    character(30), parameter :: form_out = '(1A15, 5X, 1ES25.10)'
    real     (dp), parameter :: radian_to_degree = 1.d0/degree 
    complex  (dp) :: tmp1 
    real     (dp) :: unit_theta, k, tmp2 
    complex  (qp) :: sum
    integer  (i4) :: i, j 

    unit_theta = 1_dp 
    if(op_degree == "Y") unit_theta = radian_to_degree

    allocate(outer_f(0:L))
    call mat_f 

    open(file_tcs, file = "output/total_cs.d")
    sum = 0.d0 
    k   = (2.d0*Mass*Kinet)**0.50
    do i = 0, L 
        tmp1 = 4.d0*pi/k*outer_f(i)
        sum  = sum +tmp1 
        write(file_tcs, form_tcs) dble(i), aimag(tmp1)
    end do 
    tmp1 = sum 
    write(file_log, form_out) "total sigma: ", aimag(tmp1)
    close(file_tcs)

    open(file_dcs, file = "output/diff_cs.d")
    do j = 0, ptheta 
        sum = 0.d0 
        do i = 0, L 
            tmp2 = cos(coord_theta(j))
            sum  = sum +outer_f(i)*gsl_sf_legendre_Pl(i, tmp2)
        end do 
        write(file_dcs, form_dcs) coord_theta(j)*unit_theta, abs(sum)**2.d0/(4.d0*pi)
    end do 
!     do i = 0, L 
!         write(file_dcs, form_dcs) dble(i), abs(outer_f(i))
! !         write(file_dcs, form_dcs) dble(i), real(outer_f(i)), aimag(outer_f(i))
!     end do 
    close(file_dcs)
    deallocate(outer_f)
end subroutine PROC_CS_plot


subroutine PROC_outer_plot 
    use math_const,  only: pi => math_pi, degree => math_degree
    use hamiltonian, only: coord_r, coord_theta
    use gsl_special, only: gsl_sf_legendre_Pl
    integer  (i1), parameter :: file_psi1 = 101, file_psi2 = 102
    character(30), parameter :: form_psi  = '(30ES25.10)'
    real     (dp), parameter :: radian_to_degree = 1.d0/degree 
    real     (dp) :: unit_theta, tmp 
    complex  (qp) :: sum 
    integer  (i4) :: i, j, k 

    unit_theta = 1_dp 
    if(op_degree == "Y") unit_theta = radian_to_degree

    open(file_psi1, file = "output/outer_u_0.d")
    sum = 0.d0 
    do i = N +1, 2*N
        sum = outer_u(0, coord_r(i))
        write(file_psi1, form_psi) coord_r(i), dble(abs(sum)**2.d0)
    end do 
    close(file_psi1)

    open(file_psi2, file = "output/outer_psi.d")
    do i = N +1, 2*N, N/pr 
        do j = 0, ptheta
            sum = 0.d0 
            do k = 0, L 
                tmp = cos(coord_theta(j))
                sum = sum +outer_u(k, coord_r(i))/coord_r(i)*gsl_sf_legendre_Pl(k, tmp)
            end do 
            write(file_psi2, form_psi) coord_r(i), coord_theta(j)*unit_theta, dble(abs(sum))**2.d0 
        end do 
        write(file_psi2, form_psi) 
    end do 
    close(file_psi2)
end subroutine PROC_outer_plot


subroutine PROC_E_vs_CS_plot
    use unit_const,  only: other_e_eV, au_hartree
    use hamiltonian, only: coord_E 
    integer  (i1), parameter :: file_cs  = 101
    character(30), parameter :: form_cs  = '(30ES25.10)'
    real     (dp), parameter :: au_to_eV = au_hartree/other_e_ev
    real     (dp) :: unit_e 
    integer  (i4) :: j 

    unit_e = 1_dp 
    if(op_ev == "Y") unit_e = au_to_eV

    open(file_cs, file = "output/energy_vs_cs.d")
    do j = 1, M 
        write(file_cs, form_cs) coord_E(j)*unit_e, CS(j) 
    end do 
    close(file_cs)
end subroutine PROC_E_vs_CS_plot
end module outer
