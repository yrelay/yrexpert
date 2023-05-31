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

# Options
# Utilisation http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
# Documentation à titre indicatif

usage()
{
    cat << EOF
    usage: $0 options

    Ce script permet de créer une partititon DMO pour YRexpert

    OPTIONS:
      -h    Afficher ce message
      -i    Nom de l'instance
EOF
}

while getopts "hi:" option
do
    case $option in
        h)
            usage
            exit 0
            ;;
        i)
            instance=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            basedir=/home/$instance
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

echo "[ 01 ] Parser les variables d'environnement de yrexpert-release"
cheminYRErelease=/home/$instance/etc/yrexpert-release

# Parser les variables d'environnement de yrexpert-release
variables=$(grep "=" $cheminYRErelease)
if [ ! -z "${variables}" ] ; then
    # "Parser les variables d'environnement de yrexpert-release"
    for i in ${variables}
    do
        ligne=${i}
        variable=$(echo $i | cut -f1 -d=)
        valeur=$(echo $i | grep = | cut -d= -f2-)
        if [[ $variable = yre_db ]];                  then export yre_db=$valeur ;fi       
    done
fi

echo "[ 02 ] S'assurer la présence des variables requises"
# Déterminer l'architecture du processeur
arch=$(uname -m | tr -d _)
if [ $arch == "x8664" ]; then
    ydb_arch="x86_64"
else
    ydb_arch="i386"
fi

# Rechercher si une version $BDD est installéé
if ! [[ -d /usr/lib/fis-gtm ]] && [[ $yre_db = "gtm" ]] ||
   ! [[ -d /usr/local/lib/yottadb ]] && [[ $yre_db = "ydb" ]]; then
    echo
    echo "La base de données $yre_db est requise !"
    exit 1
fi

if [[ $yre_db == gtm ]]; then
    gtm_rel=$(ls -1 /usr/lib/fis-gtm | tail -1)
    gtmver=$(echo $gtm_rel | cut -f1 -d'_')
    gtm_dist=/usr/lib/fis-gtm/$gtm_rel
    yre_rel=$gtm_rel
    basedist=$gtm_dist
else
    ydbver=$(ls -1 /usr/local/lib/yottadb | tail -1)
    ydb_dist=/usr/local/lib/yottadb/$ydbver
    ydb_rel=$ydbver"_$ydb_arch"
    yre_rel=$ydb_rel
    basedist=$ydb_dist
fi

echo "[ 03 ] Importer les routines pour l'instance $instance"
# Importer les routines
OLDIFS=$IFS
IFS=$'\n'
for routine in $(cd $basedir/src/yrexpert-m && git ls-files -- \*.m); do
    cp $basedir/src/yrexpert-m/${routine} $basedir/routines
done

echo "[ 04 ] Compiler les routines" 
# Compiler les routines
cd $basedir/routines/$yre_rel
for routine in $basedir/routines/*.m; do
    mumps ${routine} >> $basedir/log/compilerRoutines.log 2>&1
done

echo "[ 05 ] Importer les globals pour l'instance $instance"
# Import globals
for global in $(cd $basedir/src/yrexpert-m && git ls-files -- \*.zwr); do
    mupip load \"$basedir/src/yrexpert-m/${global}\" >> $basedir/log/importerGloabls.log 2>&1
done

# reset IFS
IFS=$OLDIFS

echo "[ OK ] Les routines et les globals pour l'instance $instance sont importées..."

