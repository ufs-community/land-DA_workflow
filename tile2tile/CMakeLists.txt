# (C) Copyright 2022 .
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.


cmake_minimum_required( VERSION 3.12)
project( tile2tile VERSION 2022.10 LANGUAGES Fortran )

# ecbuild integration
find_package(ecbuild 3.3.2 REQUIRED)
include( ecbuild_system NO_POLICY_SCOPE )
ecbuild_declare_project()

list( APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
#include( tile2tile_compiler_flags )

################################################################################
# Dependencies
################################################################################

find_package(OpenMP COMPONENTS C Fortran)
find_package(MPI REQUIRED COMPONENTS C Fortran)
find_package(NetCDF REQUIRED COMPONENTS Fortran )

################################################################################
# Sources
################################################################################

set( TILE2TILE_LINKER_LANGUAGE Fortran )

list ( APPEND src_files
./namelist_mod.f90
./tile2tile_restart_mod.f90
)

ecbuild_add_library( TARGET   tile2tile
                     SOURCES  ${src_files}
                     INSTALL_HEADERS LISTED
                     LINKER_LANGUAGE ${TILE2TILE_LINKER_LANGUAGE}
                    )


target_link_libraries(tile2tile PUBLIC NetCDF::NetCDF_Fortran)
target_link_libraries(tile2tile PUBLIC MPI::MPI_Fortran)
target_link_libraries(tile2tile PUBLIC OpenMP::OpenMP_C OpenMP::OpenMP_Fortran)

# Fortran module output directory for build and install interfaces
set(MODULE_DIR module/${PROJECT_NAME}/${CMAKE_Fortran_COMPILER_ID}/${CMAKE_Fortran_COMPILER_VERSION})
set_target_properties(${PROJECT_NAME} PROPERTIES Fortran_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/${MODULE_DIR})
install(DIRECTORY ${CMAKE_BINARY_DIR}/${MODULE_DIR}/ DESTINATION ${MODULE_DIR})
target_include_directories(${PROJECT_NAME} INTERFACE
                            $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/${MODULE_DIR}>
                            $<INSTALL_INTERFACE:${MODULE_DIR}>)

set( TILE2TILE_INCLUDE_DIRS  ${CMAKE_Fortran_MODULE_DIRECTORY} )
set( TILE2TILE_LIBRARIES tile2tile )

# tile2tile_converter.exe executable
#-------------------------------------------------------------------------------
set ( exe_files tile2tile_driver.f90 )

ecbuild_add_executable( TARGET   tile2tile_converter.exe
                        SOURCES  ${exe_files}
                        LIBS     tile2tile
                        LINKER_LANGUAGE ${TILE2TILE_LINKER_LANGUAGE}
                       )


################################################################################
# Finalise configuration
################################################################################

ecbuild_install_project( NAME tile2tile )
ecbuild_print_summary()
