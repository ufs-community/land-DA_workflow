program lndp_apply_pert

  use netcdf
  implicit none

  integer, parameter :: max_n_var_lndp = 20

  real, allocatable :: sfc_wts(:)
  real, allocatable :: vfrac(:)

  type namelist_type
    character*256      :: namelist_name = ""
    character*256      :: lndp_input_file = ""
    character*256      :: var_input_file = ""
    character*256      :: output_file = ""
    character(len=128) :: lndp_var_list(max_n_var_lndp)
    real               :: lndp_prt_list(max_n_var_lndp)
    integer            :: n_var_lndp
    real               :: dtf
  end type namelist_type

  type(namelist_type) :: namelist
  character*256       :: cmd
  integer             :: status, system
  real                :: p, min_bound, max_bound, pert, factor
  integer             :: i, v, tstep, tsteps, vector_length
  integer             :: ncid
  logical             :: lndp_each_step

  ! initialize vector length
  vector_length = -1

  ! apply land perturbation at each step or not
  lndp_each_step = .false.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Get namelist file name from command line
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  call get_command_argument(1, namelist%namelist_name)
  if(namelist%namelist_name == "") then
        print *,  "add namelist to the command line: "
        stop 10
  endif

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read namelist information and create date string
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  call ReadNamelist(namelist)

  ! lndp_prt_list input is per hour, factor converts to per timestep
  ! Do conversion only when variables are perturbed at every time step
  if(lndp_each_step) then
    factor = namelist%dtf/3600.
  else
    factor = 1.
  endif

  ! read in vector length from the perturbation file
  call ReadVectorLength(namelist%lndp_input_file, vector_length)

  ! read in vector length from the variable file and do sanity check
  call ReadVectorLength(namelist%var_input_file, vector_length)

  ! copy the input variable file to the output file
  if(trim(namelist%var_input_file) == trim(namelist%output_file)) then
    print*, 'The input variable file and the output file are same'
    stop 10
  else
    cmd = 'cp '//trim(namelist%var_input_file)//' '//trim(namelist%output_file)
    status = system( cmd )
  endif

  do v = 1, namelist%n_var_lndp
     select case (trim(namelist%lndp_var_list(v)))
     !=================================================================
     ! State updates - performed every cycle
     !=================================================================
!    case('smc')

!    case('stc')

     !=================================================================
     ! Parameter updates
     !=================================================================
     case('vgf')  ! vegetation fraction
         p = 5.
         min_bound=0.
         max_bound=1.

         ! allocate variables
         allocate(sfc_wts(vector_length))
         allocate(vfrac(vector_length))

         ! read in perturbation pattern
         call ReadVectorVariable(namelist%lndp_input_file, namelist%lndp_var_list(v), vector_length, 1, sfc_wts)

         ! open the output file
         status = nf90_open(namelist%output_file, nf90_write, ncid)

         ! read in vegetation fraction and apply perturbation for each month
         tsteps = 12
         do tstep = 1, tsteps

           ! read in vegetation fraction
           call ReadVectorVariable(namelist%var_input_file, 'gvf_monthly', vector_length, tstep, vfrac)

           ! apply perturbation
           do i = 1, vector_length 
             pert = sfc_wts(i)*namelist%lndp_prt_list(v)
             pert = pert*factor
             call apply_pert ('vfrac', pert, vfrac(i), p, min_bound, max_bound)
           enddo

           ! output the perturbed variable
           call WriteVectorVariable(ncid, 'gvf_monthly', vector_length, tstep, vfrac)
         enddo

         ! close the output file
         status = nf90_close(ncid)

         ! deallocate variables
         deallocate(sfc_wts)
         deallocate(vfrac)

     case default
         print*, &
          'ERROR: unrecognised lndp_prt_list option in lndp_apply_pert, exiting', trim(namelist%lndp_var_list(v))
         stop 10
     end select
  enddo

contains

  subroutine ReadNamelist(namelist)

    integer, parameter  :: max_n_var_lndp = 20
    type(namelist_type) :: namelist
    character*256       :: lndp_input_file
    character*256       :: var_input_file
    character*256       :: output_file
    character(len=128)  :: lndp_var_list(max_n_var_lndp)
    real                :: lndp_prt_list(max_n_var_lndp)
    integer             :: n_var_lndp
    real                :: dtf
    integer             :: k

    namelist / run_setup  / lndp_input_file, var_input_file, output_file, lndp_var_list, lndp_prt_list, n_var_lndp, dtf

    lndp_var_list = 'XXX'
    lndp_prt_list = -999.

    open(30, file=namelist%namelist_name, form="formatted")
     read(30, run_setup)
    close(30)

    namelist%lndp_input_file  = lndp_input_file
    namelist%var_input_file  = var_input_file
    namelist%output_file = output_file
    namelist%dtf         = dtf
    n_var_lndp= 0
    do k =1,size(lndp_var_list)
       if ((trim(lndp_var_list(k)) .EQ. 'XXX') .or. (lndp_prt_list(k) .LE. 0.)) then
          cycle
       else
          n_var_lndp=n_var_lndp+1
          namelist%lndp_var_list(n_var_lndp) = lndp_var_list(k)
          namelist%lndp_prt_list(n_var_lndp) = lndp_prt_list(k)
       endif
    enddo
    namelist%n_var_lndp = n_var_lndp
    if (n_var_lndp > max_n_var_lndp) then
       print*, 'ERROR: land perturbation requested for too many parameters', &
                       'increase max_n_var_lndp'
       stop 10
    endif

  end subroutine ReadNamelist

  subroutine ReadVectorLength(filename, vector_length)

  use netcdf

  implicit none

  character(len=*), intent(in)    :: filename
  integer,          intent(inout) :: vector_length
  integer                         :: ncid, dimid, varid, status, length_from_file

  status = nf90_open(filename, NF90_NOWRITE, ncid)

  status = nf90_inq_dimid(ncid, "location", dimid)
  status = nf90_inquire_dimension(ncid, dimid, len = length_from_file)

  status = nf90_close(ncid)

  if(vector_length < 1) then
    vector_length = length_from_file
  else
    if(vector_length /= length_from_file) then
      print*, "number of land points in the file not consistent with land model vector length"
      stop 10
    else
      print*, "number of land points in the file consistent with land model vector length"
    end if
  end if

  end subroutine ReadVectorLength

  subroutine ReadVectorVariable(filename, vname, vector_length, tstep, var)

  use netcdf

  implicit none

  character(len=*), intent(in)  :: filename, vname
  integer,          intent(in)  :: vector_length, tstep
  real,             intent(out) :: var(vector_length)
  integer                       :: ncid, varid, status

  status = nf90_open(filename, NF90_NOWRITE, ncid)

  status = nf90_inq_varid(ncid, vname, varid)

  status = nf90_get_var(ncid, varid , var(:), &
                              start = (/1,tstep/), count = (/vector_length, 1/))

  if (status /= nf90_noerr) then
      print *, trim(vname)//' missing from the file '//trim(filename)
      call handle_err(status)
  endif

  status = nf90_close(ncid)

  end subroutine ReadVectorVariable

  subroutine WriteVectorVariable(ncid, vname, vector_length, tstep, var)

  use netcdf

  implicit none

  integer,          intent(in) :: ncid
  character(len=*), intent(in) :: vname
  integer,          intent(in) :: vector_length, tstep
  real,             intent(in) :: var(vector_length)
  integer                      :: varid, status

  status = nf90_inq_varid(ncid, vname, varid)

  status = nf90_put_var(ncid, varid , var(:), &
                              start = (/1,tstep/), count = (/vector_length, 1/))

  if (status /= nf90_noerr) then
      call handle_err(status)
  endif

  end subroutine WriteVectorVariable

  subroutine apply_pert(vname, pert, state, p, vmin, vmax)

   ! intent in
    real, intent(in)             :: pert
    character(len=*), intent(in) :: vname ! name of variable being perturbed

    real, optional, intent(in)   :: p ! flat-top paramater, 0 = no flat-top
                                      ! flat-top function is used for bounded variables
                                      ! to reduce the magnitude of perturbations near boundaries.
    real, optional, intent(in)   :: vmin, vmax ! min,max bounds of variable being perturbed

    ! intent (inout)
    real, intent(inout)          :: state

    !local
    real :: z

       ! apply perturbation
       if (present(p) ) then
           if ( .not. (present(vmin) .and. present(vmax) )) then
              print*, 'error, flat-top function requires min & max to be specified'
           endif

           z = -1. + 2*(state  - vmin)/(vmax - vmin) ! flat-top function
           state =  state  + pert*(1-abs(z**p))
       else
          state =  state  + pert
       endif

       if (present(vmax)) state =  min( state , vmax )
       if (present(vmin)) state =  max( state , vmin )
       !state = max( min( state , vmax ), vmin )

  end subroutine apply_pert

  subroutine handle_err(status)
    use netcdf
    integer, intent ( in) :: status

    if(status /= nf90_noerr) then
      print *, trim(nf90_strerror(status))
      stop 10
    end if
  end subroutine handle_err

end program lndp_apply_pert
