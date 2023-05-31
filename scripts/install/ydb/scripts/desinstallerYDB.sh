#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Déinstaller YottaDB
# Cet utilitaire nécessite privliges root
#
# 22 mars 2023
#

# S'assurer que nous sommes en root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root" 1>&2
    exit 1
fi

# Par défaut YDB est installé sur /usr/local/lib/yottadb/{ydb_ver}

if [ -d /usr/local/lib/yottadb ];		    then sudo rm -r /usr/local/lib/yottadb; fi
if [ -d $HOME/.yottadb ]; 		   	        then sudo rm -r $HOME/.yottadb; fi
if [ -e /usr/share/pkgconfig/yottadb.pc ];  then sudo rm /usr/share/pkgconfig/yottadb.pc; fi

unset $(compgen -v | grep "ydb")
unset $(compgen -v | grep "gtm")

echo "[OK] La base de données YDB est désintallée..."

