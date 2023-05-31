#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Désactiver la journalisation, pour l'instance
#
# 22 mars 2023
#

echo "[01] S'assurer la présence de variables requises"
# S'assurer la présence de variables requises
if [[ -z $instance ]]; then
    echo
    echo "La variable \$instance est requise."
    exit 1
fi

# Rechercher si une version YDB est installéé
if [ -d /usr/local/lib/yottadb ]; then
    ydbver=$(ls -1 /usr/local/lib/yottadb | tail -1)
    ydb_dist=/usr/local/lib/yottadb/$ydbver
else
    echo
    echo "La base de données YDB est requise !"
    exit 1
fi

# Déterminer l'architecture du processeur - utilisé pour déterminer si nous pouvons utiliser YDB
arch=$(uname -m | tr -d _)
if [ $arch == "x8664" ]; then
    ydb_arch="x86_64"
else
    ydb_arch="i386"
fi

ydb_rel=$ydbver"_$ydb_arch"

if [[ -z $basedir ]]; then
    basedir=/home/$instance
fi

# Déterminer l'architecture du processeur - utilisé pour déterminer si nous pouvons utiliser YDB
arch=$(uname -m | tr -d _)
if [ $arch == "x8664" ]; then
    ydb_arch="x86_64"
else
    ydb_arch="i386"
fi

ydb_rel=$ydbver"_$ydb_arch"

echo "[02] Désactiver la journalisation, pour l'instance"
$ydb_dist/mupip set -journal="disable" -file $basedir/globals/YXP.dat

echo "[OK] La journalisation, pour l'instance $instance est déactivéé..."

