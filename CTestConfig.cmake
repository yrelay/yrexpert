#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce fichier doit être placé dans le répertoire racine de votre projet.
# Modifiez ensuite le fichier CMakeLists.txt dans le répertoire racine
# de votre projet pour incorporer le tableau de bord de test.

# Ces éléments sont requis pour utiliser Dart et le tableau de bord Cdash :
#   ENABLE_TESTING()
#   INCLUDE(CTest)
#
# 22 mars 2023
#

set(CTEST_PROJECT_NAME "YRExpert")
set(CTEST_NIGHTLY_START_TIME "00:00:00")

set(CTEST_DROP_METHOD "https")
set(CTEST_DROP_SITE "code.yrelay.fr")
set(CTEST_DROP_LOCATION "/CDash/submit.php?project=YRExpert")
set(CTEST_DROP_SITE_CDASH TRUE)

# Éliminer la vérification du certificat pour soumettre à CDash
set(CTEST_CURL_OPTIONS
  "CURLOPT_SSL_VERIFYPEER_OFF"
  "CURLOPT_SSL_VERIFYHOST_OFF")
  
