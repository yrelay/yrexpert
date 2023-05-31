#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce fichier contient tous les paramètres du projet
# et la démarche à suivre pour le construire
#
# 22 mars 2023
#

cmake_minimum_required(VERSION 3.12)
# https://docs.microsoft.com/fr-fr/windows/wsl/install
set(CMAKE_LEGACY_CYGWIN_WIN32 0)
project(YREXPERT LANGUAGES NONE)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

include(CTest)

# Nous n'installons rien, alors masquez l'option de préfixe d'installation.
set(CMAKE_INSTALL_PREFIX "/" CACHE INTERNAL "Ceci n'est pas une install")

# Nous n'avons pas d'outil de construction.
set(YREXPERT_HAVE_BUILD_TOOL 0)

set(BUILD_TESTING "ON" CACHE INTERNAL "Toujours construire les tests")

if(TEST_YREXPERT OR DOCUMENT_YREXPERT)
  set(YREXPERT_CMAKE_DIR "${YREXPERT_SOURCE_DIR}/cmake")
  set(YREXPERT_TESTING_DIR "${YREXPERT_SOURCE_DIR}/tests")

  find_package(Git REQUIRED)
  
  # TODO: CMake Warning (dev)
  find_package(Python 3 REQUIRED)
  
  if(NOT Python_FOUND)
     mark_as_advanced(CLEAR Python_EXECUTABLE)
  endif()

  # https://fr.wikipedia.org/wiki/Liste_de_ports_logiciels
  set(YREXPERT_TCP_HOST "127.0.0.1" CACHE STRING "Adresse du serveur de la machine qui aura le listener TCP YREXPERT")
  set(YREXPERT_TCP_PORT "9210" CACHE STRING "Numéro de port de l'écouteur TCP ouvert" )

  option(VIRTUAL_ENV "Lancer dans un environnement virtuel ?" OFF)
  if (NOT ${VIRTUAL_ENV})
    set(PIP_USER_OPTION "--user")
  endif()
  execute_process(COMMAND "${Python_EXECUTABLE}" "-m" "pip" "install" "future" ${PIP_USER_OPTION} RESULT_VARIABLE return OUTPUT_VARIABLE ERROR)
  include(FindCacheOrGTM)
endif()

#-----------------------------------------------------------------------------#
##### SECTION POUR CONFIGURER LE PROCESSUS DE TEST AUTOMATISÉ YREXPERT    #####
#-----------------------------------------------------------------------------#
option(TEST_YREXPERT "Utilisez cette option pour créer et utiliser le processus de test automatisé YREXPERT" OFF)
if(TEST_YREXPERT)
  add_subdirectory(tests)
endif()

#-----------------------------------------------------------------------------#
##### SECTION POUR GÉNÉRER LA DOCUMENTATION VISUELLE DE RÉFÉRENCE         #####
#-----------------------------------------------------------------------------#
option(DOCUMENT_YREXPERT "Utilisez cette option pour générer la documentation YREXPERT (ViViaN et DOX)" OFF)
if(DOCUMENT_YREXPERT)
  add_subdirectory(utilitaires/dox)
endif()

#-----------------------------------------------------------------------------#
# Comme nous n'avons pas d'outil de construction, dites à ctest_build
# d'exécuter une construction via un script CMake.
# 
set(cmake_build_script ${YREXPERT_BINARY_DIR}/cmake/Build.cmake)
get_property(cmake_build_scripts GLOBAL PROPERTY YREXPERT_BUILD_SCRIPTS)
if(NOT YREXPERT_HAVE_BUILD_TOOL)
  configure_file(cmake/Build.cmake.in ${cmake_build_script} @ONLY)
  set(MAKECOMMAND "${CMAKE_COMMAND} -P \"${cmake_build_script}\""
    CACHE INTERNAL "Construction de base sans outil de construction natif")
  string(REPLACE "\"" "\\\"" mc_escaped "${MAKECOMMAND}")
  set(YREXPERT_CTEST_BUILD_COMMAND_CODE "set(CTEST_BUILD_COMMAND \"${mc_escaped}\")")
else()
  file(REMOVE ${cmake_build_script})
  get_property(type CACHE MAKECOMMAND PROPERTY TYPE)
  if("${type}" STREQUAL "INTERNAL")
    build_command(MAKECOMMAND_DEFAULT_VALUE CONFIGURATION "\${CTEST_CONFIGURATION_TYPE}")
    set(MAKECOMMAND "${MAKECOMMAND_DEFAULT_VALUE}" CACHE STRING "Commande pour construire le projet" FORCE)
  endif()
  set(YREXPERT_CTEST_BUILD_COMMAND_CODE "")
endif()
configure_file(cmake/CTestCustom.cmake.in CTestCustom.cmake)
