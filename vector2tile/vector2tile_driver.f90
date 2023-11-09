program vector2tile_driver

  use namelist_mod
  use vector2tile_restart_mod
  use vector2tile_perturbation_mod
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
  
  if(namelist%direction /= "tile2vector" .and. namelist%direction /= "vector2tile" .and. &
     namelist%direction /= "lndp2vector" .and. namelist%direction /= "lndp2tile") then
    print*, "conversion direction: ",namelist%direction, " not recognized"
    stop 10 
  end if

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Decide the pathway
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  select case (namelist%direction)
  
    case ("tile2vector", "vector2tile")

      write(*,*) "Option: "//trim(namelist%direction)
      call vector2tile_restart(namelist)
    
    case ("lndp2vector", "lndp2tile")

      write(*,*) "Option: "//trim(namelist%direction)
      call mapping_perturbation(namelist)
    
    case default
    
      write(*,*) "choose a valid conversion direction"
  
  end select 
end program vector2tile_driver
