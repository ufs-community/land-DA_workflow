module tile2tile_restart_mod

  use namelist_mod
  use netcdf
  implicit none
 
  type JEDI_tile_type
    double precision, allocatable :: swe                (:,:,:)
    double precision, allocatable :: snow_depth         (:,:,:)
    double precision, allocatable :: active_snow_layers (:,:,:)
    double precision, allocatable :: swe_previous       (:,:,:)
    double precision, allocatable :: snow_soil_interface(:,:,:,:)
    double precision, allocatable :: temperature_snow   (:,:,:,:)
    double precision, allocatable :: snow_ice_layer     (:,:,:,:)
    double precision, allocatable :: snow_liq_layer     (:,:,:,:)
    double precision, allocatable :: temperature_soil   (:,:,:,:)
    real,             allocatable :: land_frac          (:,:,:)
    double precision, allocatable :: soil_moisture_total(:,:,:,:)
    double precision, allocatable :: vegetation_type(:,:,:)
! needed by add increments
    double precision, allocatable :: slmsk              (:, :, :)
! needed for JEDI QC of SMAP data
    double precision, allocatable :: soil_moisture_liquid        (:,:,:,:)
    double precision, allocatable :: temperature_ground (:,:,:) 
  end type JEDI_tile_type    

  type UFS_tile_type
    double precision, allocatable :: swe                (:,:,:)
    double precision, allocatable :: snow_depth         (:,:,:)
    double precision, allocatable :: active_snow_layers (:,:,:)
    double precision, allocatable :: swe_previous       (:,:,:)
    double precision, allocatable :: snow_soil_interface(:,:,:,:)
    double precision, allocatable :: temperature_snow   (:,:,:,:)
    double precision, allocatable :: snow_ice_layer     (:,:,:,:)
    double precision, allocatable :: snow_liq_layer     (:,:,:,:)
    double precision, allocatable :: temperature_soil   (:,:,:,:)
    real,             allocatable :: land_frac          (:,:,:)
    double precision, allocatable :: soil_moisture_total(:,:,:,:)
    double precision, allocatable :: vegetation_type(:,:,:)
! needed by add increments
    double precision, allocatable :: slmsk              (:, :, :)
! needed for JEDI QC of SMAP data
    double precision, allocatable :: soil_moisture_liquid        (:,:,:,:)
    double precision, allocatable :: temperature_ground (:,:,:)
  end type UFS_tile_type
  
contains   

  subroutine tile2tile_restart(namelist)
  type(namelist_type) :: namelist
  type(JEDI_tile_type):: JEDI_tile
  type(UFS_tile_type) :: UFS_tile
  character*300       :: tile_filename
  character*300       :: JEDI_tile_filename
  character*300       :: UFS_tile_filename
  character*19        :: date
  integer             :: yyyy,mm,dd,hh,nn,ss
  integer             :: itile, ix, iy, iloc
  integer             :: ncid, dimid, varid, status
  logical             :: file_exists
  read(namelist%restart_date( 1: 4),'(i4.4)') yyyy
  read(namelist%restart_date( 6: 7),'(i2.2)') mm
  read(namelist%restart_date( 9:10),'(i2.2)') dd
  read(namelist%restart_date(12:13),'(i2.2)') hh
  read(namelist%restart_date(15:16),'(i2.2)') nn
  read(namelist%restart_date(18:19),'(i2.2)') ss

  write(date,'(i4,a1,i2.2,a1,i2.2,a1,i2.2,a1,i2.2,a1,i2.2)') &
      yyyy, "-", mm, "-", dd, "_", hh, "-", nn, "-", ss

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Allocate tile variables
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  allocate(JEDI_tile%swe                (namelist%tile_size,namelist%tile_size,6))
  allocate(JEDI_tile%snow_depth         (namelist%tile_size,namelist%tile_size,6))
  allocate(JEDI_tile%active_snow_layers (namelist%tile_size,namelist%tile_size,6))
  allocate(JEDI_tile%swe_previous       (namelist%tile_size,namelist%tile_size,6))
  allocate(JEDI_tile%snow_soil_interface(namelist%tile_size,namelist%tile_size,7,6))
  allocate(JEDI_tile%temperature_snow   (namelist%tile_size,namelist%tile_size,3,6))
  allocate(JEDI_tile%snow_ice_layer     (namelist%tile_size,namelist%tile_size,3,6))
  allocate(JEDI_tile%snow_liq_layer     (namelist%tile_size,namelist%tile_size,3,6))
  allocate(JEDI_tile%temperature_soil   (namelist%tile_size,namelist%tile_size,4,6))
  allocate(JEDI_tile%soil_moisture_total  (namelist%tile_size,namelist%tile_size,4,6)) 
  allocate(JEDI_tile%land_frac          (namelist%tile_size,namelist%tile_size,6))
  allocate(JEDI_tile%slmsk              (namelist%tile_size,namelist%tile_size,6))
  allocate(JEDI_tile%vegetation_type    (namelist%tile_size,namelist%tile_size,6))
  allocate(JEDI_tile%soil_moisture_liquid (namelist%tile_size,namelist%tile_size,4,6))
  allocate(JEDI_tile%temperature_ground (namelist%tile_size,namelist%tile_size,6))

  allocate(UFS_tile%swe                (namelist%tile_size,namelist%tile_size,6))
  allocate(UFS_tile%snow_depth         (namelist%tile_size,namelist%tile_size,6))
  allocate(UFS_tile%active_snow_layers (namelist%tile_size,namelist%tile_size,6))
  allocate(UFS_tile%swe_previous       (namelist%tile_size,namelist%tile_size,6))
  allocate(UFS_tile%snow_soil_interface(namelist%tile_size,namelist%tile_size,7,6))
  allocate(UFS_tile%temperature_snow   (namelist%tile_size,namelist%tile_size,3,6))
  allocate(UFS_tile%snow_ice_layer     (namelist%tile_size,namelist%tile_size,3,6))
  allocate(UFS_tile%snow_liq_layer     (namelist%tile_size,namelist%tile_size,3,6))
  allocate(UFS_tile%temperature_soil   (namelist%tile_size,namelist%tile_size,4,6))
  allocate(UFS_tile%soil_moisture_total(namelist%tile_size,namelist%tile_size,4,6))
  allocate(UFS_tile%land_frac          (namelist%tile_size,namelist%tile_size,6))
  allocate(UFS_tile%slmsk              (namelist%tile_size,namelist%tile_size,6))
  allocate(UFS_tile%vegetation_type    (namelist%tile_size,namelist%tile_size,6))
  allocate(UFS_tile%soil_moisture_liquid(namelist%tile_size,namelist%tile_size,4,6))
  allocate(UFS_tile%temperature_ground (namelist%tile_size,namelist%tile_size,6))

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read FV3 tile information
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  do itile = 1, 6
    write(tile_filename,'(a5,i1,a3)')  ".tile", itile, ".nc"

    tile_filename = trim(namelist%tile_path)//trim(namelist%tile_fstub)//trim(adjustl(tile_filename))
    inquire(file=trim(tile_filename), exist=file_exists)
   
    print*, "Reading tile file: ", trim(tile_filename)
 
    if(.not.file_exists) then 
      print*, trim(tile_filename), " does not exist1"
      print*, "Check paths and file name"
      stop 10 
    end if
    
    status = nf90_open(trim(tile_filename), NF90_NOWRITE, ncid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_inq_varid(ncid, "land_frac", varid)
    status = nf90_get_var(ncid, varid , JEDI_tile%land_frac(:,:,itile))
    status = nf90_get_var(ncid, varid , UFS_tile%land_frac(:,:,itile))
 
    status = nf90_close(ncid)

  end do

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Direction of transfer branch
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  if(namelist%direction == "ufs2jedi") then

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read UFS NoahMP restart file
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    call UFS_ReadTileRestart(namelist, date, UFS_tile)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Transfer
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    ! explicitly initialize to 0.
    JEDI_tile%slmsk=0.

    do itile = 1, 6
    do iy = 1, namelist%tile_size
    do ix = 1, namelist%tile_size

      if(UFS_tile%land_frac(ix,iy,itile) > 0.0) then
        JEDI_tile%swe(ix,iy,itile)                   = UFS_tile%swe(ix,iy,itile)
        JEDI_tile%vegetation_type(ix,iy,itile)       = UFS_tile%vegetation_type(ix,iy,itile)
        JEDI_tile%snow_depth(ix,iy,itile)            = UFS_tile%snow_depth(ix,iy,itile)
        JEDI_tile%active_snow_layers(ix,iy,itile)    = UFS_tile%active_snow_layers(ix,iy,itile)
        JEDI_tile%swe_previous(ix,iy,itile)          = UFS_tile%swe_previous(ix,iy,itile)
        JEDI_tile%snow_soil_interface(ix,iy,:,itile) = UFS_tile%snow_soil_interface(ix,iy,:,itile)
        JEDI_tile%temperature_snow(ix,iy,:,itile)    = UFS_tile%temperature_snow(ix,iy,:,itile)
        JEDI_tile%snow_ice_layer(ix,iy,:,itile)      = UFS_tile%snow_ice_layer(ix,iy,:,itile)
        JEDI_tile%snow_liq_layer(ix,iy,:,itile)      = UFS_tile%snow_liq_layer(ix,iy,:,itile)
        JEDI_tile%temperature_soil(ix,iy,:,itile)    = UFS_tile%temperature_soil(ix,iy,:,itile)
        JEDI_tile%soil_moisture_total(ix,iy,:,itile) = UFS_tile%soil_moisture_total(ix,iy,:,itile)
        JEDI_tile%slmsk(ix,iy,itile)                 = 1.
        JEDI_tile%soil_moisture_liquid(ix,iy,:,itile)= UFS_tile%soil_moisture_liquid(ix,iy,:,itile)
        JEDI_tile%temperature_ground(ix,iy,itile)    = UFS_tile%temperature_ground(ix,iy,itile)
      end if

    end do
    end do
    end do
 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Write JEDI tile file
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    call JEDI_WriteTileRestart(namelist, date, JEDI_tile)
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! JEDI2UFS branch
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!  elseif(namelist%direction == "tile2vector") then
!  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Read JEDI tile restart files
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
!    call ReadTileRestart(namelist, date, JEDI_tile)
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Transfer tile to vector
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
!    iloc = 0
!    do itile = 1, 6
!    do iy = 1, namelist%tile_size
!    do ix = 1, namelist%tile_size
!    
!      if(tile%land_frac(ix,iy,itile) > 0.0) then
!        iloc = iloc + 1
!        vector%swe(iloc)                   = tile%swe(ix,iy,itile)
!        vector%snow_depth(iloc)            = tile%snow_depth(ix,iy,itile)
!        vector%active_snow_layers(iloc)    = tile%active_snow_layers(ix,iy,itile)
!        vector%swe_previous(iloc)          = tile%swe_previous(ix,iy,itile)
!        vector%snow_soil_interface(iloc,:) = tile%snow_soil_interface(ix,iy,:,itile)
!        vector%temperature_snow(iloc,:)    = tile%temperature_snow(ix,iy,:,itile)
!        vector%snow_ice_layer(iloc,:)      = tile%snow_ice_layer(ix,iy,:,itile)
!        vector%snow_liq_layer(iloc,:)      = tile%snow_liq_layer(ix,iy,:,itile)
!        vector%temperature_soil(iloc,:)    = tile%temperature_soil(ix,iy,:,itile)
!        vector%soil_moisture_total(iloc,:) = tile%soil_moisture_total(ix,iy,:,itile)
!        vector%soil_moisture_liquid(iloc,:)= tile%soil_moisture_liquid(ix,iy,:,itile)
!        vector%temperature_ground(iloc)    = tile%temperature_ground(ix,iy,itile)
!      end if
!      
!    end do
!    end do
!    end do
!      
!   print*, "Transferred ",iloc, "land grids"  
!    
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Write FV3 tile file
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
!    call WriteVectorRestart(namelist, date, vector, vector_length)
!  
  end if ! "vector2tile" or "tile2vector" branch
     
  end subroutine tile2tile_restart
  




  subroutine UFS_ReadTileRestart(namelist, date, UFS_tile)
  
  use netcdf

  type(namelist_type) :: namelist
  type(UFS_tile_type)     :: UFS_tile
  character*19        :: date
  character*256       :: UFS_tile_filename
  integer             :: ncid, dimid, varid, status
  integer             :: itile
  logical             :: file_exists
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Create tile file name
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  do itile = 1, 6
    write(UFS_tile_filename,'(a17,a19,a5,i1,a3)')  & 
         "ufs_land_restart.", date, ".tile",itile,".nc"
!        date(1:4), date(6:7), date(9:10),".",date(12:13), "0000.sfc_data.tile",itile,".nc"

    UFS_tile_filename = trim(namelist%tile_restart_path)//trim(UFS_tile_filename)
 
    print*, "Reading UFS tile file: ", trim(UFS_tile_filename)   
    
    inquire(file=UFS_tile_filename, exist=file_exists)
  
    if(.not.file_exists) then 
      print*, trim(UFS_tile_filename), " does not exist4"
      print*, "Check paths and file name"
      stop 10 
    end if

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read the UFS NoahMP tile fields
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    status = nf90_open(UFS_tile_filename, NF90_NOWRITE, ncid)
      if (status /= nf90_noerr) call handle_err(status)

! Start reading restart file
  
    status = nf90_inq_varid(ncid, "weasd", varid)
    if (status /= nf90_noerr) then
        print *, 'weasd variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%swe(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "snwdph", varid)
    if (status /= nf90_noerr) then
        print *, 'snwdph variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%snow_depth(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "snowxy", varid)
    if (status /= nf90_noerr) then
        print *, 'snowxy variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%active_snow_layers(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "sneqvoxy", varid)
    if (status /= nf90_noerr) then
        print *, 'sneqvoxy variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%swe_previous(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "zsnsoxy", varid)
    if (status /= nf90_noerr) then
        print *, 'zsnoxy variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%snow_soil_interface(:,:,:,itile) , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 7, 1/))

    status = nf90_inq_varid(ncid, "tsnoxy", varid)
    if (status /= nf90_noerr) then
        print *, 'tsnoxy variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%temperature_snow(:,:,:,itile)  , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 3, 1/))

    status = nf90_inq_varid(ncid, "snicexy", varid)
    if (status /= nf90_noerr) then
        print *, 'snicexy variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%snow_ice_layer(:,:,:,itile) , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 3, 1/))

    status = nf90_inq_varid(ncid, "snliqxy", varid)
    if (status /= nf90_noerr) then
        print *, 'snliqxy variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%snow_liq_layer(:,:,:,itile) , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 3, 1/))

    status = nf90_inq_varid(ncid, "stc", varid)
    if (status /= nf90_noerr) then
        print *, 'stc variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%temperature_soil(:,:,:,itile)   , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 4, 1/))

    status = nf90_inq_varid(ncid, "smc", varid)
    if (status /= nf90_noerr) then
        print *, 'smc variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%soil_moisture_total(:,:,:,itile)   , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 4, 1/))

    status = nf90_inq_varid(ncid, "slc", varid)
    if (status /= nf90_noerr) then
        print *, 'slc variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%soil_moisture_liquid(:,:,:,itile)   , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 4, 1/))

    status = nf90_inq_varid(ncid, "tgxy", varid)
    if (status /= nf90_noerr) then
        print *, 'tgxy variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%temperature_ground(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "vegtype", varid)
    if (status /= nf90_noerr) then
        print *, 'vegtype variable missing from tile file'
        call handle_err(status)
    endif
    status = nf90_get_var(ncid, varid , UFS_tile%vegetation_type(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_close(ncid)

  end do
  
  end subroutine UFS_ReadTileRestart


  subroutine JEDI_WriteTileRestart(namelist, date, JEDI_tile)
  
  use netcdf

  type(namelist_type) :: namelist
  type(JEDI_tile_type):: JEDI_tile
  character*19        :: date
  character*256       :: JEDI_tile_filename
  integer             :: itile
  integer             :: ncid, varid, status, i
  integer             :: dim_id_xdim, dim_id_ydim, dim_id_soil, dim_id_snow, dim_id_snso, dim_id_time
  
  do itile = 1, 6

    write(JEDI_tile_filename,'(a4,a2,a2,a1,a2,a18,i1,a3)')  & 
        date(1:4), date(6:7), date(9:10),".",date(12:13), "0000.sfc_data.tile",itile,".nc"

    JEDI_tile_filename = trim(namelist%output_path)//trim(JEDI_tile_filename)
    
    print*, "Writing tile file: ", trim(JEDI_tile_filename)

    status = nf90_create(JEDI_tile_filename, NF90_CLOBBER, ncid)
      if (status /= nf90_noerr) call handle_err(status)

! Define dimensions in the file.

    status = nf90_def_dim(ncid, "xaxis_1"          , namelist%tile_size , dim_id_xdim)
      if (status /= nf90_noerr) call handle_err(status)
    status = nf90_def_dim(ncid, "yaxis_1"          , namelist%tile_size , dim_id_ydim)
      if (status /= nf90_noerr) call handle_err(status)
    status = nf90_def_dim(ncid, "zaxis_2"   , 4                  , dim_id_soil)
      if (status /= nf90_noerr) call handle_err(status)
    status = nf90_def_dim(ncid, "zaxis_3"   , 3                  , dim_id_snow)
      if (status /= nf90_noerr) call handle_err(status)
    status = nf90_def_dim(ncid, "zaxis_4"   , 7                  , dim_id_snso)
      if (status /= nf90_noerr) call handle_err(status)
    status = nf90_def_dim(ncid, "Time"          , NF90_UNLIMITED     , dim_id_time)
      if (status /= nf90_noerr) call handle_err(status)

! define dimension variables (for JEDI) 

    status = nf90_def_var(ncid, "Time", NF90_DOUBLE,    &
      (/dim_id_time/), varid)
    if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "xaxis_1", NF90_DOUBLE,    &
      (/dim_id_xdim/), varid)
    if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "yaxis_1", NF90_DOUBLE,    &
      (/dim_id_ydim/), varid)
    if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "zaxis_2", NF90_DOUBLE,    &
      (/dim_id_soil/), varid)
    if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "zaxis_3", NF90_DOUBLE,    &
      (/dim_id_snow/), varid)
    if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "zaxis_4", NF90_DOUBLE,    &
      (/dim_id_snso/), varid)
    if (status /= nf90_noerr) call handle_err(status)

  
! Define variables in the file.

    status = nf90_def_var(ncid, "sheleg", NF90_DOUBLE,    & ! note: this is weasd in vector file.
      (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "snwdph", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "snowxy", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "sneqvoxy", NF90_DOUBLE, &
      (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "zsnsoxy", NF90_DOUBLE,  &
      (/dim_id_xdim,dim_id_ydim,dim_id_snso,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "tsnoxy", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_snow,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "snicexy", NF90_DOUBLE,  &
      (/dim_id_xdim,dim_id_ydim,dim_id_snow,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "snliqxy", NF90_DOUBLE,  &
      (/dim_id_xdim,dim_id_ydim,dim_id_snow,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "stc", NF90_DOUBLE,      &
      (/dim_id_xdim,dim_id_ydim,dim_id_soil,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "smc", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_soil,dim_id_time/), varid) 
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "slmsk", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)
      
    status = nf90_def_var(ncid, "vtype", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "slc", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_soil,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_def_var(ncid, "tgxy", NF90_DOUBLE,   &
      (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_enddef(ncid)


! fill dimension variables 

    status = nf90_inq_varid(ncid, "Time", varid)
    if (status /= nf90_noerr) call handle_err(status)
    status = nf90_put_var(ncid, varid ,(/1/) )

    status = nf90_inq_varid(ncid, "xaxis_1", varid)
    if (status /= nf90_noerr) call handle_err(status)
    status = nf90_put_var(ncid, varid ,(/(i, i=1, namelist%tile_size)/) )

    status = nf90_inq_varid(ncid, "yaxis_1", varid)
    if (status /= nf90_noerr) call handle_err(status)
    status = nf90_put_var(ncid, varid ,(/(i, i=1, namelist%tile_size)/) )

    status = nf90_inq_varid(ncid, "zaxis_2", varid)
    if (status /= nf90_noerr) call handle_err(status)
    status = nf90_put_var(ncid, varid ,(/(i, i=1, 4)/) )

    status = nf90_inq_varid(ncid, "zaxis_3", varid)
    if (status /= nf90_noerr) call handle_err(status)
    status = nf90_put_var(ncid, varid ,(/(i, i=1, 3)/) )

    status = nf90_inq_varid(ncid, "zaxis_4", varid)
    if (status /= nf90_noerr) call handle_err(status)
    status = nf90_put_var(ncid, varid ,(/(i, i=1, 7)/) )

! Start writing restart file
  
    status = nf90_inq_varid(ncid, "sheleg", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%swe(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "snwdph", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%snow_depth(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "snowxy", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%active_snow_layers(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "sneqvoxy", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%swe_previous(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "zsnsoxy", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%snow_soil_interface(:,:,:,itile) , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 7, 1/))

    status = nf90_inq_varid(ncid, "tsnoxy", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%temperature_snow(:,:,:,itile)  , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 3, 1/))

    status = nf90_inq_varid(ncid, "snicexy", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%snow_ice_layer(:,:,:,itile) , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 3, 1/))

    status = nf90_inq_varid(ncid, "snliqxy", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%snow_liq_layer(:,:,:,itile) , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 3, 1/))

    status = nf90_inq_varid(ncid, "stc", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%temperature_soil(:,:,:,itile)   , &
      start = (/1,1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 4, 1/))

    status = nf90_inq_varid(ncid, "smc", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%soil_moisture_total(:,:,:,itile)   , &
      start = (/1,1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 4, 1/)) 

! include in output, so can be used to id which tile grid cells are being simulated
    status = nf90_inq_varid(ncid, "slmsk", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%slmsk(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

    status = nf90_inq_varid(ncid, "vtype", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%vegetation_type(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

! include for JEDI QC of SMAP obs
    status = nf90_inq_varid(ncid, "slc", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%soil_moisture_liquid(:,:,:,itile)   , &
      start = (/1                , 1                , 1, 1/), &
      count = (/namelist%tile_size, namelist%tile_size, 4, 1/))

    status = nf90_inq_varid(ncid, "tgxy", varid)
    status = nf90_put_var(ncid, varid , JEDI_tile%temperature_ground(:,:,itile)   , &
      start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))
      
  status = nf90_close(ncid)

  end do
  
  end subroutine JEDI_WriteTileRestart

  subroutine handle_err(status)
    use netcdf
    integer, intent ( in) :: status
 
    if(status /= nf90_noerr) then
      print *, trim(nf90_strerror(status))
      stop 10
    end if
  end subroutine handle_err

end module tile2tile_restart_mod
