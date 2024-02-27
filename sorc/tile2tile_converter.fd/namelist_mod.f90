module namelist_mod
  implicit none

  integer, parameter   :: max_n_var_lndp = 20
  type namelist_type
    character*256      :: namelist_name = ""
    character*11       :: direction = ""
    character*256      :: tile_path = ""
    character*256      :: tile_fstub = ""
    integer            :: tile_size
    character*19       :: restart_date = ""
    character*256      :: vector_restart_path = ""
    character*256      :: tile_restart_path = ""
    character*256      :: output_path = ""
    character*256      :: static_filename = ""
    character*3        :: lndp_layout = ""
    character*256      :: lndp_input_file = ""
    character*256      :: lndp_output_file = ""
    character(len=128) :: lndp_var_list(max_n_var_lndp)
    integer            :: n_var_lndp
  end type namelist_type

contains

  subroutine ReadNamelist(namelist)

    type(namelist_type) :: namelist
    character*11        :: direction
    character*256       :: tile_path
    character*256       :: tile_fstub
    integer             :: tile_size
    character*19        :: restart_date
    character*256       :: vector_restart_path
    character*256       :: tile_restart_path
    character*256       :: output_path
    character*256       :: static_filename
    character*3         :: lndp_layout
    character*256       :: lndp_input_file
    character*256       :: lndp_output_file
    character(len=128)  :: lndp_var_list(max_n_var_lndp)
    integer             :: n_var_lndp
    integer             :: k

    namelist / run_setup  / direction, tile_path, tile_fstub, tile_size,  restart_date, vector_restart_path, &
                            tile_restart_path, output_path, static_filename, lndp_layout,       &
                            lndp_input_file, lndp_output_file, lndp_var_list, n_var_lndp

    lndp_var_list = 'XXX'

    open(30, file=namelist%namelist_name, form="formatted")
     read(30, run_setup)
    close(30)

    namelist%direction           = direction
    namelist%tile_path           = tile_path
    namelist%tile_fstub           = tile_fstub
    namelist%tile_size           = tile_size
    namelist%restart_date        = restart_date
    namelist%vector_restart_path = vector_restart_path
    namelist%tile_restart_path   = tile_restart_path
    namelist%output_path         = output_path
    namelist%static_filename     = static_filename

    namelist%lndp_layout         = lndp_layout
    namelist%lndp_input_file     = lndp_input_file
    namelist%lndp_output_file    = lndp_output_file

    n_var_lndp= 0
    do k =1,size(lndp_var_list)
       if (trim(lndp_var_list(k)) .EQ. 'XXX') then
          cycle
       else
          n_var_lndp=n_var_lndp+1
          namelist%lndp_var_list(n_var_lndp) = lndp_var_list(k)
       endif
    enddo
    namelist%n_var_lndp = n_var_lndp
    if (n_var_lndp > max_n_var_lndp) then
       print*, 'ERROR: land perturbation requested for too many parameters', &
                       'increase max_n_var_lndp'
       stop 10
    endif

  end subroutine ReadNamelist

end module namelist_mod
