# (C) Copyright 2017-2020 UCAR.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.


################################################################################
# LandDA
################################################################################

cmake_minimum_required( VERSION 3.12 )
project( LandDA VERSION 0.0.0 LANGUAGES C CXX Fortran)

if(DEFINED ENV{JEDI_INSTALL})
 set( JEDI_INSTALL  $ENV{JEDI_INSTALL}/jedi-bundle)
else()
  message(FATAL_ERROR "Define the environment variable 'JEDI_INSTALL' to point to the parent directory of fv3-bundle on your system")
endif()
find_package(ecbuild 3.3.2 REQUIRED)
enable_testing()
include( ecbuild_system NO_POLICY_SCOPE )
ecbuild_declare_project()

# Inlcude externalproject
# -----------------------
include(ExternalProject)

# Initialize bundle
# -----------------
ecbuild_bundle_initialize()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include(landda_compiler_flags)


################################################################################
# Dependencies
################################################################################
find_package(NetCDF REQUIRED COMPONENTS Fortran)
include_directories( ${NETCDF_INCLUDE_DIRS} )

################################################################################
# Sources
################################################################################
set(LANDDA_LINKER_LANGUAGE CXX)

if(NOT APP)
  set(APP "LND")
endif()

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release")
endif()

list(APPEND UFS_WEATHER_MODEL_ARGS
  "-DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}"
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DMPI=ON"
  "-DAPP=${APP}"
)

ExternalProject_Add(ufs-weather-model
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/ufs-weather-model
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ufs-weather-model
  CMAKE_ARGS ${UFS_WEATHER_MODEL_ARGS}
  INSTALL_COMMAND cmake
  )

add_subdirectory(vector2tile)
add_subdirectory(tile2tile)
add_subdirectory(ufs-land-driver-emc-dev)
add_subdirectory(DA_update/add_jedi_incr)

# Include testing.
add_subdirectory(test)

if(ECBUILD_INSTALL_FORTRAN_MODULES)
  install(DIRECTORY ${CMAKE_Fortran_MODULE_DIRECTORY}/${CMAKE_CFG_INTDIR} DESTINATION ${INSTALL_INCLUDE_DIR} )
endif()
execute_process(
     COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/DA_update/jedi/fv3-jedi/Data/make_links.sh ${JEDI_INSTALL}
     WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/DA_update/jedi/fv3-jedi/Data
)
################################################################################
# Finalise configuration
################################################################################

# prepares a tar.gz of the sources and/or binaries
ecbuild_install_project( NAME LandDA )

# print the summary of the configuration
ecbuild_print_summary()
