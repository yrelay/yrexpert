#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
#  

# 22 mars 2023
#

#-----------------------------------------------------------------------------
#------ SET UP UNIT TEST ENV -----#
#-----------------------------------------------------------------------------
set(YREXPERT_CACHE_USERNAME "" CACHE STRING "Username for instance")
set(YREXPERT_CACHE_PASSWORD "" CACHE STRING "Password for instance")
set(VENDOR_NAME "Cache")
if(NOT YREXPERT_CACHE_INSTANCE)
  # Detect Cache instances.
  if(WIN32)
    execute_process(
      COMMAND ${CCONTROL_EXECUTABLE} qlist nodisplay
      OUTPUT_FILE ${CMAKE_BINARY_DIR}/cache_qlist.txt
      ERROR_VARIABLE err
      RESULT_VARIABLE failed
      TIMEOUT 30 # should never happen, listing is fast
      )
  else()
    execute_process(
      COMMAND ${CCONTROL_EXECUTABLE} qlist
      OUTPUT_FILE ${CMAKE_BINARY_DIR}/cache_qlist.txt
      ERROR_VARIABLE err
      RESULT_VARIABLE failed
      TIMEOUT 30
      )
  endif()
  if(failed)
    string(REPLACE "\n" "\n  " err "  ${err}")
    message(FATAL_ERROR "Failed to run \"${CCONTROL_EXECUTABLE} qlist \": ${failed}\n${err}")
  endif()
  file(STRINGS ${CMAKE_BINARY_DIR}/cache_qlist.txt qlist)
  set(YREXPERT_CACHE_INSTANCES "")
  foreach(YREXPERT_CACHE_INSTANCE ${qlist})
    string(REPLACE "^" ";" YREXPERT_CACHE_INSTANCE "${YREXPERT_CACHE_INSTANCE}")
    list(GET YREXPERT_CACHE_INSTANCE 0 name)
    list(GET YREXPERT_CACHE_INSTANCE 1 ${name}_DIRECTORY)
    list(GET YREXPERT_CACHE_INSTANCE 2 ${name}_VERSION)
    list(GET YREXPERT_CACHE_INSTANCE 6 ${name}_WEB_PORT)
    list(APPEND YREXPERT_CACHE_INSTANCES ${name})
  endforeach()

  # Select a default instance.
  set(default "")
  foreach(guess CACHEWEB TRYCACHE)
    if(${guess}_DIRECTORY)
      set(default ${guess})
      break()
    endif()
  endforeach()
  if(YREXPERT_CACHE_INSTANCES AND NOT default)
    list(GET YREXPERT_CACHE_INSTANCES 0 default)
  endif()

  # Present an INSTANCE option.
  set(YREXPERT_CACHE_INSTANCE "${default}" CACHE STRING "Cache instance name")
  set_property(CACHE YREXPERT_CACHE_INSTANCE PROPERTY STRINGS "${YREXPERT_CACHE_INSTANCES}")
endif()
message(STATUS "Using Cache instance ${YREXPERT_CACHE_INSTANCE}")

# Select a namespace for YREXPERT
set(YREXPERT_CACHE_NAMESPACE "YREXPERT" CACHE STRING "Cache namespace to store YREXPERT")

if(WIN32)
  configure_file(${YREXPERT_CMAKE_DIR}/CacheVerifyTelnet.scp.in ${CMAKE_BINARY_DIR}/CacheVerifyTelnet.scp)
  message(STATUS "Is Cache Telnet service enabled:")
  execute_process(COMMAND "${CTERM_EXECUTABLE}" "/console=cn_iptcp:127.0.0.1[23]" "${CMAKE_BINARY_DIR}/CacheVerifyTelnet.scp" "${CMAKE_BINARY_DIR}/CacheVerifyTelnet.log" TIMEOUT 5 RESULT_VARIABLE rcode)
  if(rcode EQUAL 1)
    message(STATUS "Is Cache Telnet service enabled: Connection established")
  else ( (rcode EQUAL 0) OR "${rcode}" MATCHES "timeout" )
    message(FATAL_ERROR "Error connecting to Cache ${YREXPERT_CACHE_INSTANCE} namespace ${YREXPERT_CACHE_NAMESPACE} via telnet, please enable the telnet setting via"
      " Cache Managements Portal->System->Security Management->Service to switch on %Service_telnet by checking enabled checkbox and save."
      " Also verify that telnet port is set to 23 via Configuration->Device Settings->Telnet Settings ")
  endif()
endif()

#-----------------------------------------------------------------------------#
##### SECTION TO SETUP THE REFRESH OF THE DATABASE #####
#-----------------------------------------------------------------------------#

if(TEST_YREXPERT_FRESH)
  set(TEST_YREXPERT_SETUP_VOLUME_SET "YREXPERT" CACHE STRING "Volume Set for new YREXPERT Instance")
  set(TEST_YREXPERT_FRESH_CACHE_DAT_YREXPERT "" CACHE FILEPATH "Path to the CACHE.dat file with the imported YREXPERT")
  set(TEST_YREXPERT_FRESH_CACHE_DAT_EMPTY "" CACHE FILEPATH "Path to an empty ******.DAT file for replacement")

  list(APPEND freshinfo TEST_YREXPERT_SETUP_VOLUME_SET)
  list(APPEND freshinfo TEST_YREXPERT_FRESH_CACHE_DAT_YREXPERT)
  list(APPEND freshinfo TEST_YREXPERT_FRESH_CACHE_DAT_EMPTY)

  if(TEST_YREXPERT_FRESH_CACHE_DAT_YREXPERT)
    get_filename_component(filename ${TEST_YREXPERT_FRESH_CACHE_DAT_YREXPERT} NAME)
    string(TOLOWER ${filename} filename_lower)
    if(${filename_lower} STREQUAL "cache.dat")
      get_filename_component(TEST_YREXPERT_FRESH_CACHE_DIR_YREXPERT ${TEST_YREXPERT_FRESH_CACHE_DAT_YREXPERT} PATH)
    else(${filename_lower} STREQUAL "cache.dat")
      message(SEND_ERROR "${TEST_YREXPERT_FRESH_CACHE_DAT_YREXPERT} does not point to a file called 'cache.dat'.  Fix the path to point to a correct file.")
    endif(${filename_lower} STREQUAL "cache.dat")
  endif(TEST_YREXPERT_FRESH_CACHE_DAT_YREXPERT)
endif()
