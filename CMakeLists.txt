# (C) Copyright 2017-2020 UCAR.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.


################################################################################
# LandDA
################################################################################

cmake_minimum_required( VERSION 3.12 )
project( LandDA VERSION 0.0.0 LANGUAGES C CXX Fortran)

find_package(ecbuild 3.3.2 REQUIRED)
include( ecbuild_system NO_POLICY_SCOPE )
ecbuild_declare_project()

list( APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include( landda_compiler_flags )

################################################################################
# Dependencies
################################################################################
find_package( NetCDF REQUIRED COMPONENTS Fortran)
find_package( fv3-bundle REQUIRED)
find_package( ioda-bundle REQUIRED)
include_directories( ${NETCDF_INCLUDE_DIRS} )

message("HEY, features are ${fv3-bundle_FEATURES}")
message("HEY, version is ${fv3-bundle_version}")
message("${fv3-bundle_BASE_DIR} and ${ioda-bundle_BASE_DIR})")

################################################################################
# Sources
################################################################################
set( LANDDA_LINKER_LANGUAGE CXX)

add_subdirectory( vector2tile )
add_subdirectory( ufs-land-driver )
add_subdirectory( DA_update/add_jedi_incr )
add_subdirectory( DA_update/IMS_proc )

if(ECBUILD_INSTALL_FORTRAN_MODULES)
  install(DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/${CMAKE_CFG_INTDIR} DESTINATION ${INSTALL_INCLUDE_DIR} )
endif()
execute_process(
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/DA_update/jedi/fv3-jedi/Data/make_links.sh ${fv3-bundle_BASE_DIR}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/DA_update/jedi/fv3-jedi/Data
)
execute_process(
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/DA_update/jedi/ioda//make_links.sh ${ioda-bundle_BASE_DIR}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/DA_update/jedi/ioda/
)

################################################################################
# Finalise configuration
################################################################################

# prepares a tar.gz of the sources and/or binaries
ecbuild_install_project( NAME LandDA )

# print the summary of the configuration
ecbuild_print_summary()
