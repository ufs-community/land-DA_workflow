# test for creating pseudo ensemble for use in letkfoi
add_test(NAME test_create_ens
         COMMAND ${PROJECT_SOURCE_DIR}/test/create_bkg_ens.sh ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}
         WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/test)
set_tests_properties(test_create_ens
    PROPERTIES
    ENVIRONMENT "FIXlandda=$ENV{FIXlandda}") 

# test for running letkfoi to assimilate snow DA
add_test(NAME test_letkfoi_snowda
         COMMAND ${PROJECT_SOURCE_DIR}/test/test_letkfoi_snowda.sh ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}
         WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/test)
set_tests_properties(test_letkfoi_snowda
    PROPERTIES
    DEPENDS "test_create_ens"
    ENVIRONMENT "FIXlandda=$ENV{FIXlandda}")

# test for adding jedi increment
add_test(NAME test_apply_jediincr
         COMMAND ${PROJECT_SOURCE_DIR}/test/apply_jedi_incr.sh ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}
         WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/test)
set_tests_properties(test_apply_jediincr
    PROPERTIES
    DEPENDS "test_letkfoi_snowda"
    ENVIRONMENT "FIXlandda=$ENV{FIXlandda}")

# test for ufs-datm-lnd model
add_test(NAME test_ufs_datm_land
         COMMAND ${PROJECT_SOURCE_DIR}/test/run_ufs_datm_lnd.sh ${PROJECT_BINARY_DIR} ${PROJECT_SOURCE_DIR}
         WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/test)

