module outer
    use kind_type
    use global 
    implicit none
    complex(DP), save, allocatable, private, protected :: outer_f(:)
contains 
    

subroutine mat_f 
    use math_const, only: i => math_i
    real   (DP) :: k, tmp1, tmp2 
    integer(I4) :: j 

    k = (2.d0*Mass*Kinet)**0.50
    do j = 0, L 
        tmp1 = aimag(S(j))/2.d0 
        tmp2 = (1.d0 -real(S(j)))/2.d0 
        outer_f(j) = (2.d0*dble(j) +1.d0)/k*(tmp1 +i*tmp2)
    end do 
end subroutine mat_f 


! function outer_u(l, r)
!     integer(I4), intent(in) :: l 
!     real   (DP), intent(in) :: r 
!     real   (DP) :: kr
!     complex(DP) :: outer_u

!     kr      = (2.d0*Mass*Kinet)**0.5d0*r
!     outer_u = A(l)*(bessel_jn(l, kr) -K(l)*bessel_yn(l, kr))*r 
! end function outer_u
function outer_u(l, r)
    use nr, only: sphbes_s
    integer(I4), intent(in) :: l 
    real   (DP), intent(in) :: r 
    real   (SP) :: kr, sb_j, sb_y, diff_j, diff_y 
    complex(DP) :: outer_u

    kr = (2.d0*Mass*Kinet)**0.5d0*r
    call sphbes_s(l, kr, sb_j, sb_y, diff_j, diff_y)

    outer_u = A(l)*(sb_j -K(l)*sb_y)*r 
end function outer_u










! ==================================================
! PROCESS
! ==================================================


subroutine PROC_CS_plot 
    use math_const,  only: pi => math_pi, degree => math_degree
    use hamiltonian, only: coord_r, coord_theta
    use nr, only: plgndr_s
    integer (I1), parameter :: file_dcs = 101,           file_tcs = 102 
    character(30), parameter :: form_dcs = '(30ES25.10)', form_tcs = '(30ES25.10)'
    character(30), parameter :: form_out = '(1A15, 5X, 1ES25.10)'
    real     (DP), parameter :: radian_to_degree = 1.d0/degree 
    real     (DP) :: k
    complex  (DP) :: tmp1 
    real     (SP) :: tmp2 
    complex  (QP) :: sum
    integer  (I4) :: i, j 

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
            sum  = sum +outer_f(i)*plgndr_s(i, 0, tmp2)
!             sum  = sum +outer_f(i)*1.d0 
        end do 
        write(file_dcs, form_dcs) coord_theta(j)*radian_to_degree, abs(sum)**2.d0/(4.d0*pi)
!         write(file_dcs, form_dcs) coord_theta(j)*radian_to_degree, real(sum), aimag(sum)
    end do 
!     do i = 0, L 
!         write(file_dcs, form_dcs) dble(i), abs(outer_f(i))
! !         write(file_dcs, form_dcs) dble(i), real(outer_f(i)), aimag(outer_f(i))
!     end do 
    close(file_dcs)
    deallocate(outer_f)
end subroutine PROC_CS_plot


subroutine PROC_outer_plot 
    use math_const,  only: pi => math_pi
    use hamiltonian, only: coord_r, coord_theta
    use nr, only: plgndr_s
    integer  (I1), parameter :: file_psi1 = 101, file_psi2 = 102
    character(30), parameter :: form_psi  = '(30ES25.10)'
    real     (SP) :: tmp 
    complex  (QP) :: sum 
    integer  (I4) :: i, j, k 

    open(file_psi1, file = "output/outer_u0.d")
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
                sum = sum +outer_u(k, coord_r(i))/coord_r(i)*plgndr_s(k, 0, tmp)
            end do 
            write(file_psi2, form_psi) coord_r(i), coord_theta(j), dble(abs(sum))**2.d0 
        end do 
        write(file_psi2, form_psi) 
    end do 
    close(file_psi2)
end subroutine PROC_outer_plot
end module outer
