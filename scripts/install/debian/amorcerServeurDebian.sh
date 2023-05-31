#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script installe les dépandnaces nécessaires
#
# 22 mars 2023
#

# Assurez-vous que nous sommes en root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root" 1>&2
    exit 1
fi

# Mettre à jour le serveur avec les dépôts
apt-get -y -qq update > /dev/null
apt-get -y -qq upgrade > /dev/null

# Installer les paquets de base
apt-get install -y -qq git dos2unix xinetd perl wget curl python ssh maven sshpass libicu-dev apt-utils > /dev/null

