#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script permet d'importer une partititon utilisateur pour YRexpert
#
# 22 mars 2023
#

# Assurez-vous que nous sommes en root
#if [[ $EUID -ne 0 ]]; then
#    echo "Ce script doit être exécuté en tant que root" 1>&2
#    exit 1
#fi

# Options
# Utilisation http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
# Documentation à titre indicatif

usage()
{
    cat << EOF
    usage: $0 options

    Ce script permet d'importer une partititon utilisateur pour YRexpert

    OPTIONS:
      -h    Afficher ce message
      -i    Nom de l'instance
      -p    Nom de la partition
EOF
}

while getopts "hi:p:" option
do
    case $option in
        h)
            usage
            exit 0
            ;;
        i)
            instance=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            ;;
        p)
            partition=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            ;;
    esac
done

if [[ -z $instance ]]; then
    echo
    echo "L'instance est requis !"
    echo
    usage
    exit 1
fi

if [[ -z $partition ]]; then
    echo
    echo "La partition est requis !"
    echo
    usage
    exit 1
fi

echo "[01] S'assurer la présence des variables requises"
# S'assurer la présence de variables requises
if [[ -z $partition ]]; then
    echo
    echo "La variable \$partition est requise."
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

if [[ -z $partdir ]]; then
    partdir=$basedir/partitions/$partition
fi




ydb_rel=$ydbver"_$ydb_arch"

echo "[02] Importer les routines"
# Importer les routines
#TODO : Simplifier par $partdir + permettre l'import d'une partition tiers
OLDIFS=$IFS
IFS=$'\n'
for routine in $(cd $basedir/src/yrexpert-${partition} && git ls-files -- \*.m); do
    cp $basedir/src/yrexpert-${partition}/${routine} $partdir/routines
done
echo "Importation des routines terminée"

echo "[03] Compiler les routines"
# Compiler les routines
cd $partdir/routines/$ydb_rel
for routine in $basedir/partitions/${partition,,}/routines/*.m; do
    mumps ${routine} >> $partdir/log/compilerRoutines.log 2>&1
done
echo "Compilation des routines terminée"

echo "[02] Importer les globals"
# Importer globals
for global in $(cd $basedir/src/yrexpert-${partition} && git ls-files -- \*.zwr); do
    mupip load \"$basedir/src/yrexpert-${partition}/${global}\" >> $partdir/log/importerGloabls.log 2>&1
done
echo "Importation des globals terminée"

# reset IFS
IFS=$OLDIFS

echo "[OK] L'importation des Globals et des Routines de la partition utilisateur $partition est terminé"


