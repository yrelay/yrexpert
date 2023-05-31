#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Importer YRexpert Globals et Routines dans l'instance $instance
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

echo "[02] Importer les routines dans l'instance $instance"
# Importer les routines
echo "Copier les routines"
OLDIFS=$IFS
IFS=$'\n'
git config --global --add safe.directory "*" # Désactiver les contrôles de dépôt car le référentiel est stocké localement
for routine in $(cd $basedir/src/yrexpert-m && git ls-files -- \*.m); do
    cp $basedir/src/yrexpert-m/${routine} $basedir/routines
done
echo "Copie des routines terminée"

# Compiler les routines
echo "Compiler les routines"
cd $basedir/routines/$ydb_rel
for routine in $basedir/routines/*.m; do
    mumps ${routine} >> $basedir/log/compilerRoutines.log 2>&1
done
echo "Compilation des routines terminée"

echo "[03] Importer les globals dans l'instance $instance"
# Import globals
echo "Importer les globals"
for global in $(cd $basedir/src/yrexpert-m && git ls-files -- \*.zwr); do
    mupip load \"$basedir/src/yrexpert-m/${global}\" >> $basedir/log/importerGloabls.log 2>&1
done
echo "Importation des globals terminée"

# reset IFS
IFS=$OLDIFS

echo "[OK] Les routines m de YRExpert sont importées..."


