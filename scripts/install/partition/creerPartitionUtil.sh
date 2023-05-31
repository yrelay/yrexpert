#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Créer les répertoires pour les routines, les objets, les globals,
# les Journaux, les fichiers temporaires de la partition $partition
# Cet utilitaire nécessite privliges root
#
# 22 mars 2023
#

# Assurez-vous que nous sommes en root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root" 1>&2
    exit 1
fi

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
      -r    Supprimer et réinstaller la partition
      -t    Mode test
EOF
}

while getopts "hi:p:rt" option
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
        r)
            reInstall=true
            ;;
        t)
            modeTest=true
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

if [[ -z $reInstall ]]; then
    reInstall=false
fi

if [[ -z $modeTest ]]; then
    modeTest=false
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
echo "                                    creerInstanceYRExpert.sh"
echo "i- Installer l'instance nommée    : $instance"
echo "p - Créer la partition nommée     : $partition"
echo "r - Réinstallation                : $reInstall"
echo "t - Mode test                     : $modeTest"
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

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 04 ] Installer icu-config s'il n'est pas installé" 
# Si icu-config n'est pas installé
apt-get install -y libicu-dev -qq

set +e # Ne pas fermeture lors d'un code retour différent de 0
echo "[ 05 ] Supprimer l'instance $instance si elle existe." 
if [[ -d $basedir/partitions/$yre_db ]]; then
    if [[ -e $basedir/scripts/supprimerPartitionUtil.sh ]]; then
        echo "Supprimer la partition $partition"
        $basedir/scripts/supprimerPartitionUtil.sh -p $partition
    else
        if [[ -e $repScript/ydb/scripts/supprimerPartitionUtil.sh ]]; then
            echo "Supprimer l'instance $instance"
            $repScript/ydb/scripts/supprimerPartitionUtil.sh -i $partition
        else
            echo
            echo "L'outil de supression de la partition est introuvable !"
            echo "Suprimer la partition $partition manuellement."
            exit 1
        fi
    fi
    if [[ "$?" != 0 ]];then
        echo
        echo "La supression de la partition $partition est impossible !"
        echo "Ajouter l'option -f pour forcer la suppression de la partition $partition."
        exit 2
    fi 
fi

# Si le test de création n'est pas OK, alors sortir
if [[ $? != 0 ]]; then
    set -e # Fermeture lors d'un code retour différent de 0
    echo
    # Afficher le fichier log
    cat ./log/creerPartitionUtil.log
    exit  1
fi

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 05 ] Créer les répertoires de l'instance $instance et le la partition $partition"
# Créer les répertoires de l'instance
su $instance -c "mkdir -p $partdir/{routines,routines/$gtm_rel,globals,journals,etc,etc/xinetd.d,log,tmp,scripts,libraries,backup,partitions,src}"

# Copier les répertoires standards du dépot yrexpert-dmo
su $instance -c "cp -R $basedir/src/yrexpert-dmo/scripts $partdir"

echo "[ 06 ] Créer le fichier env de la partition $partition"
# Créer le fichier env

echo "# Fichier des variables d'environnement créer par creerPartitionUtil.sh" >> $partdir/etc/env
echo "export gtmgbldir=$partdir/globals/${partition^^}.gld"                    >> $partdir/etc/env
echo "export gtm_rel=$gtm_rel"	                >> $partdir/etc/env
#TODO: traiter le cas autre que 64bit
# GTM ou YDB 64bit peut utiliser une bibliothèque partagée
echo "export gtm_dist=$gtm_dist"	            >> $partdir/etc/env
echo "export gtm_arch=$gtm_arch"                >> $partdir/etc/env
echo "export gtmver=$gtmver"                    >> $partdir/etc/env
echo "export gtm_log=$basedir/log"              >> $partdir/etc/env
echo "export gtm_tmp=$basedir/tmp"              >> $partdir/etc/env
echo "export gtm_prompt=\"${partition^^}>\""    >> $partdir/etc/env
echo "export gtm_zinterrupt='I \$\$JOBEXAM^ZU(\$ZPOSITION)'" 	>> $partdir/etc/env
echo "export gtm_lvnullsubs=2"                  >> $partdir/etc/env
echo "export PATH=\$PATH:$gtm_dist/utf8"        >> $partdir/etc/env
echo "export gtm_icu_version=`uconv --version | cut -d' ' -f5`"	>> $partdir/etc/env
echo "export gtm_chset=UTF-8"			        >> $partdir/etc/env
echo ""			                                >> $partdir/etc/env
echo "export instance=$instance"                >> $partdir/etc/env
echo "export partition=$partition"              >> $partdir/etc/env
echo "export gtm_dir=$basedir"                  >> $partdir/etc/env
echo "export partdir=$basedir/partitions/$partition" >> $partdir/etc/env
echo "export basedist=$gtm_dist"	            >> $partdir/etc/env
echo ""			                                >> $partdir/etc/env
echo "export gtmroutines=\"\$partdir/routines/\$gtm_rel($partdir/routines) \$basedist/utf8/libgtmutil.so\"" >> $partdir/etc/env


# Mettre les droits corrects pour env
chown $instance:$instance $partdir/etc/env

# Mettre les droits corrects pour $partdir
chown $instance:$instance $partdir

echo "[ 07 ] Créer les globals de l'utilisateur $partition"
# Créer les globals DMO
# TODO: Introduire la notion de version de gtm
echo "c -s DEFAULT    -ACCESS_METHOD=BG -BLOCK_SIZE=4096 -ALLOCATION=200000 -EXTENSION_COUNT=1024 -GLOBAL_BUFFER_COUNT=4096 -LOCK_SPACE=400 -FILE=$partdir/globals/${partition^^}.dat" >> $partdir/etc/db.gde
echo "a -s TEMP       -ACCESS_METHOD=MM -BLOCK_SIZE=4096 -ALLOCATION=10000 -EXTENSION_COUNT=1024 -GLOBAL_BUFFER_COUNT=4096 -LOCK_SPACE=400 -FILE=$partdir/globals/temp.dat" >> $partdir/etc/db.gde
echo "c -r DEFAULT    -RECORD_SIZE=16368 -KEY_SIZE=1019 -JOURNAL=(BEFORE_IMAGE,FILE_NAME=\"$partdir/journals/${partition^^}.mjl\") -DYNAMIC_SEGMENT=DEFAULT" >> $partdir/etc/db.gde
echo "a -r TEMP       -RECORD_SIZE=16368 -KEY_SIZE=1019 -NOJOURNAL -DYNAMIC_SEGMENT=TEMP"   >> $partdir/etc/db.gde
echo "a -n TMP        -r=TEMP"                  >> $partdir/etc/db.gde
echo "a -n TEMP       -r=TEMP"                  >> $partdir/etc/db.gde
echo "a -n UTILITY    -r=TEMP"                  >> $partdir/etc/db.gde
echo "a -n XTMP       -r=TEMP"                  >> $partdir/etc/db.gde
echo "a -n CacheTemp* -r=TEMP"                  >> $partdir/etc/db.gde
echo "sh -a"                                    >> $partdir/etc/db.gde

# Mettre les droits corrects pour db.gde
chown $instance:$instance $partdir/etc/db.gde

# Créer db.gde
su $instance -c "source $partdir/etc/env && $basedist/mumps -run GDE < $partdir/etc/db.gde >> $partdir/log/sortieGDE.log 2>&1"

echo "[ 08 ] Créer la base de données de l'utilisateur $partition"
# Créer la base de données
echo "Créer la base de données"
su $instance -c "source $partdir/etc/env && $basedist/mupip create >> $partdir/log/sortieGDE.log 2>&1"
echo "Création de la base de données terminée"

echo "[ 09 ] Mettre les droits"
chown -R $instance:$instance $basedir
chmod -R g+rw $basedir

echo "[OK] La partition DMO de YRExpert de l'instance $instance est créée..."




