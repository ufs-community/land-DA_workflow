module vector2tile_perturbation_mod

  use netcdf
  use namelist_mod
  implicit none

contains   

  subroutine mapping_perturbation(namelist)
  type(namelist_type) :: namelist
  real, allocatable   :: var_vector(:), lon_vector(:), lat_vector(:)
  real, allocatable   :: var_tile(:,:,:), lon_tile(:,:,:), lat_tile(:,:,:)
  real, allocatable   :: land_frac_tile(:,:,:)
  character*256       :: vector_filename
  character*256       :: tile_filename
  character*256       :: input_filename
  character*256       :: output_filename
  character*2         :: tile1, tile2
  real, allocatable   :: tmp2d(:,:)
  integer             :: filename_length
  integer             :: vector_length = 0
  integer             :: layout_x, layout_y, nx, ny
  integer             :: itile, ix, iy, iloc, ivar
  integer             :: i, j, m, n, i1, i2, j1, j2, t2
  integer             :: ncid, dimid, varid, status
  integer             :: dim_id_xdim, dim_id_ydim, dim_id_time
  integer             :: ncid_landp, ncid_vec, ncid_tile(6)
  logical             :: file_exists

  if(trim(namelist%lndp_layout) == '1x4') then
    layout_x = 1
    layout_y = 4
  else if(trim(namelist%lndp_layout) == '2x2') then
    layout_x = 2
    layout_y = 2
  else if(trim(namelist%lndp_layout) == '4x1') then
    layout_x = 4
    layout_y = 1
  else if(trim(namelist%lndp_layout) == '1x1') then
    layout_x = 1
    layout_y = 1
  else
    print*, "layout: ",namelist%lndp_layout, " not recognized"
    stop 10
  endif

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Allocate tile variables
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  allocate(var_tile(      namelist%tile_size,namelist%tile_size,6))
  allocate(lon_tile(      namelist%tile_size,namelist%tile_size,6))
  allocate(lat_tile(      namelist%tile_size,namelist%tile_size,6))
  allocate(land_frac_tile(namelist%tile_size,namelist%tile_size,6))

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Read FV3 tile information
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  do itile = 1, 6

    if(namelist%tile_size < 100) then
      write(tile_filename,'(a5,i2,a11,i1,a3)') "oro_C", namelist%tile_size, ".mx100.tile", itile, ".nc"
    elseif(namelist%tile_size < 1000) then
      write(tile_filename,'(a5,i3,a11,i1,a3)') "oro_C", namelist%tile_size, ".mx100.tile", itile, ".nc"
    elseif(namelist%tile_size < 10000) then
      write(tile_filename,'(a5,i4,a11,i1,a3)') "oro_C", namelist%tile_size, ".mx100.tile", itile, ".nc"
    else
      print *, "unknown tile size"
      stop 10
    end if

    tile_filename = trim(namelist%tile_path)//trim(tile_filename)

    inquire(file=tile_filename, exist=file_exists)

    if(.not.file_exists) then
      print*, trim(tile_filename), " does not exist"
      print*, "In routine mapping_perturbation: check paths and file name"
      stop 10
    end if

    status = nf90_open(tile_filename, NF90_NOWRITE, ncid)
      if (status /= nf90_noerr) call handle_err(status)

    status = nf90_inq_varid(ncid, "land_frac", varid)
    status = nf90_get_var(ncid, varid , land_frac_tile(:,:,itile))

    status = nf90_close(ncid)

    vector_length = vector_length + count(land_frac_tile(:,:,itile) > 0)

  end do

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Allocate vector variables
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  allocate(var_vector(vector_length))
  allocate(lon_vector(vector_length))
  allocate(lat_vector(vector_length))

  nx = namelist%tile_size/layout_x
  ny = namelist%tile_size/layout_y

  if(namelist%n_var_lndp > 0) then

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Define the output file
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
     if(trim(namelist%direction) == "lndp2vector") then

        output_filename = namelist%lndp_output_file
        status = nf90_create(output_filename, NF90_CLOBBER, ncid_vec)
           if (status /= nf90_noerr) call handle_err(status)

! Define dimensions in the file.

        status = nf90_def_dim(ncid_vec, "location", vector_length, dim_id_xdim)
           if (status /= nf90_noerr) call handle_err(status)
        status = nf90_def_dim(ncid_vec, "Time", NF90_UNLIMITED, dim_id_time)
           if (status /= nf90_noerr) call handle_err(status)

! Define lat and lon 
       status = nf90_def_var(ncid_vec, 'lon_vec', &
                NF90_FLOAT, (/dim_id_xdim,dim_id_time/), varid)
          if (status /= nf90_noerr) call handle_err(status)
       status = nf90_def_var(ncid_vec, 'lat_vec', &
                NF90_FLOAT, (/dim_id_xdim,dim_id_time/), varid)
          if (status /= nf90_noerr) call handle_err(status)

! Define variables in the file. 
        do ivar = 1, namelist%n_var_lndp
           status = nf90_def_var(ncid_vec, namelist%lndp_var_list(ivar), &
                    NF90_FLOAT, (/dim_id_xdim,dim_id_time/), varid)
              if (status /= nf90_noerr) call handle_err(status)
        enddo
        status = nf90_enddef(ncid_vec)

     else if(trim(namelist%direction) == "lndp2tile" ) then

        filename_length = len_trim(namelist%lndp_output_file)
        do itile = 1, 6
           write(tile1,fmt='(I2.2)') itile
           output_filename = trim(namelist%lndp_output_file(1:filename_length-5))//trim(tile1)//'.nc'
           status = nf90_create(output_filename, NF90_CLOBBER, ncid_tile(itile))
              if (status /= nf90_noerr) call handle_err(status)

! Define dimensions in the file.

           status = nf90_def_dim(ncid_tile(itile), "xaxis_1", namelist%tile_size , dim_id_xdim)
              if (status /= nf90_noerr) call handle_err(status)
           status = nf90_def_dim(ncid_tile(itile), "yaxis_1", namelist%tile_size , dim_id_ydim)
              if (status /= nf90_noerr) call handle_err(status)
           status = nf90_def_dim(ncid_tile(itile), "Time", NF90_UNLIMITED, dim_id_time)
              if (status /= nf90_noerr) call handle_err(status)

! Define lat and lon in the file
          status = nf90_def_var(ncid_tile(itile), 'lon_tile', &
                   NF90_FLOAT, (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
             if (status /= nf90_noerr) call handle_err(status)
          status = nf90_def_var(ncid_tile(itile), 'lat_tile', &
                   NF90_FLOAT, (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
             if (status /= nf90_noerr) call handle_err(status)

! Define variables in the file. 
           do ivar = 1, namelist%n_var_lndp
              status = nf90_def_var(ncid_tile(itile), namelist%lndp_var_list(ivar), &
                       NF90_FLOAT, (/dim_id_xdim,dim_id_ydim,dim_id_time/), varid)
                 if (status /= nf90_noerr) call handle_err(status)
           enddo
           status = nf90_enddef(ncid_tile(itile))
        enddo
     endif

     allocate(tmp2d(nx,ny))

     do ivar = 1, namelist%n_var_lndp
        t2 = 1
        filename_length = len_trim(namelist%lndp_input_file)
        do itile = 1, 6
           i1=1
           i2=i1+nx-1
           j1=1
           j2=j1+ny-1
           do j=1,layout_y
              do i=1,layout_x
                 write(tile2,fmt='(I2.2)') t2
                 if(t2 > 1) then
                    i1=i1+nx
                    i2=i2+nx
                    if (i2 .GT. namelist%tile_size) then
                       i1=1
                       i2=i1+nx-1
                    endif
                 endif
                 input_filename = trim(namelist%lndp_input_file(1:filename_length-5))//trim(tile2)//'.nc'

                !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                ! Read the perturbation pattern
                !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                 status = nf90_open(input_filename, NF90_NOWRITE, ncid_landp)
                 status = nf90_inq_varid(ncid_landp, namelist%lndp_var_list(ivar), varid)
                 if (status /= nf90_noerr) then
                     print *, trim(namelist%lndp_var_list(ivar))//' variable missing from perturbation file'
                     call handle_err(status)
                 endif

                 status = nf90_get_var(ncid_landp, varid, tmp2d, start = (/1,1,1/), count = (/nx, ny, 1/))

                 do m = i1, i2
                    do n = j1, j2
                       var_tile(m,n,itile) = tmp2d(m-i1+1,n-j1+1)
                    enddo
                 enddo

                 ! get the lat and lon 
                 if ( ivar == 1 ) then
                     status = nf90_inq_varid(ncid_landp, 'grid_lon', varid)
                     if (status /= nf90_noerr) then
                         print *, trim('grid lon variable missing from perturbation file') 
                         call handle_err(status)
                     endif

                     status = nf90_get_var(ncid_landp, varid, tmp2d, start = (/1,1,1/), count = (/nx, ny, 1/))

                     do m = i1, i2
                        do n = j1, j2
                           lon_tile(m,n,itile) = tmp2d(m-i1+1,n-j1+1)
                        enddo
                     enddo

                     ! get the lat and lat
                     status = nf90_inq_varid(ncid_landp, 'grid_lat', varid)
                     if (status /= nf90_noerr) then
                         print *, trim('grid lat variable missing from perturbation file') 
                         call handle_err(status)
                     endif

                     status = nf90_get_var(ncid_landp, varid, tmp2d, start = (/1,1,1/), count = (/nx, ny, 1/))

                     do m = i1, i2
                        do n = j1, j2
                           lat_tile(m,n,itile) = tmp2d(m-i1+1,n-j1+1)
                        enddo
                     enddo

                 endif

                 t2 = t2+1

              enddo

              j1=j1+ny
              j2=j2+ny

              if (j2 .GT. namelist%tile_size) then
                 j1=1
                 j2=j1+ny-1
              endif

           enddo

           !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
           ! Write the perturbation pattern for the tile files
           !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

           if(trim(namelist%direction) == "lndp2tile") then
              status = nf90_inq_varid(ncid_tile(itile), namelist%lndp_var_list(ivar), varid)
              status = nf90_put_var(ncid_tile(itile), varid , var_tile(:,:,itile), &
                              start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))
              if (ivar==1) then 
                  status = nf90_inq_varid(ncid_tile(itile), 'lon_grid', varid)
                  status = nf90_put_var(ncid_tile(itile), varid , lon_tile(:,:,itile), &
                                  start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))
                  status = nf90_inq_varid(ncid_tile(itile), 'lat_grid', varid)
                  status = nf90_put_var(ncid_tile(itile), varid , lat_tile(:,:,itile), &
                                  start = (/1,1,1/), count = (/namelist%tile_size, namelist%tile_size, 1/))

              endif 
           endif
        
        enddo    ! for each tile


        iloc = 0
        do itile = 1, 6
           do j = 1, namelist%tile_size
              do i = 1, namelist%tile_size
                 if(land_frac_tile(i,j,itile) > 0.0) then
                    iloc = iloc + 1
                    var_vector(iloc) = var_tile(i,j,itile)
                    if (ivar==1) then
                        lon_vector(iloc) = lon_tile(i,j,itile)
                        lat_vector(iloc) = lat_tile(i,j,itile)
                    endif
                 endif
              enddo
           enddo
        enddo    ! for each tile

        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        ! Write the perturbation pattern for the vector file
        !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        if(trim(namelist%direction) == "lndp2vector") then
           status = nf90_inq_varid(ncid_vec, namelist%lndp_var_list(ivar), varid)
           status = nf90_put_var(ncid_vec, varid , var_vector(:), &
                              start = (/1,1/), count = (/vector_length, 1/))

           if (ivar == 1) then 
               status = nf90_inq_varid(ncid_vec, 'lon_vec', varid)
               status = nf90_put_var(ncid_vec, varid , lon_vector(:), &
                                  start = (/1,1/), count = (/vector_length, 1/))
               status = nf90_inq_varid(ncid_vec, 'lat_vec', varid)
               status = nf90_put_var(ncid_vec, varid , lat_vector(:), &
                                  start = (/1,1/), count = (/vector_length, 1/))
           endif
        endif

     enddo       ! for each variable

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Close the netcdf file
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

     if(trim(namelist%direction) == "lndp2vector") then
        status = nf90_close(ncid_vec)
     else if(trim(namelist%direction) == "lndp2tile") then
        do itile = 1, 6
           status = nf90_close(ncid_tile(itile))
        enddo
     endif
  endif
  end subroutine mapping_perturbation

  subroutine handle_err(status)
    use netcdf
    integer, intent ( in) :: status

    if(status /= nf90_noerr) then
      print *, trim(nf90_strerror(status))
      stop 10
    end if
  end subroutine handle_err

end module vector2tile_perturbation_mod
