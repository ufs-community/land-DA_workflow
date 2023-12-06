program tile2tile_driver

  use namelist_mod
  use tile2tile_restart_mod
  implicit none

  type(namelist_type)  :: namelist
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Get namelist file name from command line
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  call get_command_argument(1, namelist%namelist_name)
  if(namelist%namelist_name == "") then 
        print *,  "add namelist to the command line: "
        stop 10  
  endif
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read namelist information
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  call ReadNamelist(namelist)

  print*, "conversion direction: ",namelist%direction
  
  if(namelist%direction /= "ufs2jedi" .and. namelist%direction /= "jedi2ufs") then
    print*, "conversion direction: ",namelist%direction, " not recognized"
    stop 10 
  end if

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Decide the pathway
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  select case (namelist%direction)
  
    case ("ufs2jedi", "jedi2ufs")

      write(*,*) "Option: "//trim(namelist%direction)
      call tile2tile_restart(namelist)
    
    case default
    
      write(*,*) "choose a valid conversion direction"
  
  end select 
end program tile2tile_driver
