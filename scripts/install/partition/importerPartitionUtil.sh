#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Importer la partition utilisateur Globals et Routines dans l'instance $instance
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
            basedir=/home/$instance
            ;;
        p)
            partition=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            partdir=$basedir/partitions/$partition
            ;;
        *)
            usage
            exit 0
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

if [[ -z $debian ]]; then
    if [[ `lsb_release -d` =~ Debian ]]; then
        # Indiquer au scripts que nous sommes sur une distribution debian
        echo `lsb_release -d`
        debian=true
    else
        # TODO: tester pour RHEL
        echo
        echo `lsb_release -d`
        echo "Impossible de déterminer la distribution !"
        exit 1
    fi
fi

# Résumer des options
echo "!--------------------------------------------------------------------------!"
echo "                              importerPartitionUtil.sh"
echo "i - Installer l'instance nommée   : $instance"
echo "p - Importer la partition nommée  : $partition"
echo "!--------------------------------------------------------------------------!"

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 01 ] Initialiser les variables de l'environnement de YRExpert"
# Parser les variables d'environnement de yrexpert-release
cheminYRErelease=/home/$instance/etc/yrexpert-release
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
else    
    echo
    echo "L'instance $instance n'est pas reconnue comme une instance YRExpert !"
    exit 1
fi

# Déterminer l'architecture du processeur
arch=$(uname -m | tr -d _)
if [ $arch == "x8664" ]; then
    yre_arch="x86_64"
else
    yre_arch="i386"
fi

# $basedir est le répertoire de base de l'instance
# exemples d'installation possibles : /home/$instance, /opt/$instance, /var/db/$instance
basedir=/home/$instance

# Se posionner sur le répertoire ou se trouve le fichier courant
cd $(readlink -f $(dirname $0))
cd ..
cd ..
repScript=`pwd`

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 02 ] Vérifier l'installation la base de données $yre_db" 
cd $repScript
# Rechercher si une version est installée
if [[ -d /usr/lib/fis-gtm ]] && [[ $yre_db == "gtm" ]] ||
   [[ -d /usr/local/lib/yottadb ]] && [[ $yre_db == "ydb" ]]; then
    # Rechercher la version installée
    if [[ $yre_db == "gtm" ]]; then dirs=$(find /usr/lib/fis-gtm -maxdepth 1 -type d -printf '%P\n') ;fi
    if [[ $yre_db == "ydb" ]]; then dirs=$(find /usr/local/lib/yottadb -maxdepth 1 -type d -printf '%P\n') ;fi
    # Nous pouvons lister les répertoires si > 1 erreur de répertoire
    if [[ $dirs -gt 2 ]]; then
        echo "Plus d'une version de $yre_db installée !"
        echo "Impossible de déterminer quelle version de $Byre_db à utiliser !"
        exit 1
    fi
    echo
    echo "La version $yre_db" $dirs "est déjà installée"
fi

# Rechercher si une version $yre_db est installéé
if ! [[ -d /usr/lib/fis-gtm ]] && [[ $yre_db == "gtm" ]] ||
   ! [[ -d /usr/local/lib/yottadb ]] && [[ $yre_db == "ydb" ]]; then
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
    ydb_rel=$ydbver"_$yre_arch"
    yre_rel=$ydb_rel
    basedist=$ydb_dist
fi

echo "[ 03 ] Importer les routines" 
# Importer les routines
#TODO : Simplifier par $partdir
OLDIFS=$IFS
IFS=$'\n'
#for routine in $(cd $basedir/src/yrexpert-${partition^^} && git ls-files -- \*.m); do
for routine in $(cd $basedir/src/yrexpert-${partition} && git ls-files -- \*.m); do
    cp $basedir/src/yrexpert-${partition}/${routine} $basedir/partitions/${partition,,}/routines
done

echo "[ 04 ] Compiler les routines" 
# Compiler les routines
cd $basedir/partitions/${partition,,}/routines/$yre_rel
#for routine in $basedir/partitions/${partition,,}/routines/*.m; do
#    mumps ${routine} >> $basedir/partitions/${partition,,}/log/compilerRoutines.log 2>&1
#done

echo "[ 05 ] Import globals" 
# Import globals
for global in $(cd $basedir/src/yrexpert-${partition} && git ls-files -- \*.zwr); do
    mupip load \"$basedir/src/yrexpert-${partition}/${global}\" >> $basedir/partitions/${partition,,}/log/importerGloabls.log 2>&1
done

# reset IFS
IFS=$OLDIFS

echo "[ OK ] Les routines et les globals pour la partition $partition de l'instance $instance sont importées..."

