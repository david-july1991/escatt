module global 
    use kind_type 
   implicit none
    integer (i1), parameter :: file_input = 5, file_log = 6 
    real    (dp), save :: Scatt, ra, dr_p_drho
    integer (i4), save :: N, M, L 
    integer (i4), save :: pr, ptheta 
    real    (dp), save, allocatable :: coord_rho(:), coord_weight(:), coord_dshape(:, :)
    real    (dp), save, allocatable :: H(:, :), E(:), R(:), K(:)
    complex (dp), save, allocatable :: S(:), A(:)
    character(1), save :: &
        op_ev, op_degree, op_aa, & 
        op_poten, op_basis, op_dcs, op_inner, op_outer, &
        op_tcs, op_phase, op_lt
end module
