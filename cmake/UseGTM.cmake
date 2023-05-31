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
#------ CONFIGURER L'UNITÉ TEST ENV                                     -----#
#-----------------------------------------------------------------------------
set(VENDOR_NAME "GTM")

#-----------------------------------------------------------------------------
#------ EXTRAIRE LISTE RÉPERTOIRES SOURCE GT.M DE GTMROUTINES ENV VAR   -----#
#-----------------------------------------------------------------------------
execute_process(
  COMMAND ${PYTHON_EXECUTABLE} ${YREXPERT_SOURCE_DIR}/tests/Python/ParseGTMRoutines.py
  OUTPUT_VARIABLE GTM_ROUTINE_DIRS
  )
string(STRIP "${GTM_ROUTINE_DIRS}" GTM_ROUTINE_DIRS)
set(GTM_SOURCE_DIR ${GTM_ROUTINE_DIRS} CACHE STRING
    "Liste des répertoires contenant les routines source GT.M obtenues en parsant
    la variable d'environnement 'gtmroutines'")
list(GET GTM_SOURCE_DIR 0 firstPath)
set(TEST_YREXPERT_GTM_ROUTINE_DIR ${firstPath} CACHE STRING
    "Répertoire où sont importées les routines YREXPERT GT.M.
    Les routines de test MUnit seront importées ici.
    Pour modifier la liste, modifiez GTM_SOURCE_DIR")
set_property(CACHE TEST_YREXPERT_GTM_ROUTINE_DIR PROPERTY STRINGS ${GTM_SOURCE_DIR})

#-----------------------------------------------------------------------------#
##### SECTION POUR CONFIGURER LE RAFRAÎCHISSEMENT DE LA BASE DE DONNÉES   #####
#-----------------------------------------------------------------------------#
if(TEST_YREXPERT_FRESH)
  #Trouve le programme de script pour le système basé sur Linux
  set(TEST_YREXPERT_SETUP_UCI_NAME "PLA" CACHE STRING "GTM UCI pour stocker YREXPERT")
  set(TEST_YREXPERT_SETUP_VOLUME_SET "PLA" CACHE STRING "Ensemble de volumes pour la nouvelle instance YREXPERT")

  #Crée des variables pour les routines et les répertoires globaux dans GT.M
  set(TEST_YREXPERT_FRESH_GTM_ROUTINE_DIR "" CACHE PATH
    "Répertoire où les routines YREXPERT doivent être importées lors de la 
    configuration d'une nouvelle instance YREXPERT.
    (REMARQUE : le chemin doit figurer dans la variable d'environnement 'gtmroutines')")
  if(NOT TEST_YREXPERT_FRESH_GTM_ROUTINE_DIR AND TEST_YREXPERT_GTM_ROUTINE_DIR)
    set(TEST_YREXPERT_FRESH_GTM_ROUTINE_DIR ${TEST_YREXPERT_GTM_ROUTINE_DIR})
  endif()
  set(TEST_YREXPERT_FRESH_GTM_GLOBALS_DAT "" CACHE FILEPATH " Chemin d'accès à la base de données GT.M.dat")

  list(APPEND freshinfo TEST_YREXPERT_SETUP_UCI_NAME)
  list(APPEND freshinfo TEST_YREXPERT_SETUP_VOLUME_SET)
  list(APPEND freshinfo TEST_YREXPERT_FRESH_GTM_ROUTINE_DIR)
  list(APPEND freshinfo TEST_YREXPERT_FRESH_GTM_GLOBALS_DAT)
endif()

#-----------------------------------------------------------------------------#
##### SECTION POUR EXÉCUTER LE TEST D'ANALYSE VARIABLE GTMROUTINES        #####
#-----------------------------------------------------------------------------#
if(GTM_DIST)
  configure_file("${YREXPERT_TESTS_DIR}/python/ParseGTMRoutinesTest.py.in"
                 "${CMAKE_BINARY_DIR}/python/ParseGTMRoutinesTest.py")
  add_test(PYTHON_GTMRoutinesParser ${PYTHON_EXECUTABLE}
           ${CMAKE_BINARY_DIR}/python/ParseGTMRoutinesTest.py)
  set_tests_properties(PYTHON_GTMRoutinesParser
                       PROPERTIES FAIL_REGULAR_EXPRESSION "FAILED")
endif()

