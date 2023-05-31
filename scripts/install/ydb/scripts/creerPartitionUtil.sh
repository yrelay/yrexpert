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

ydb_rel=$ydbver"_$ydb_arch"

echo "[02] Créer les répertoires de l'instance $instance et le la partition $partition"
# Créer les répertoires de l'instance
su $instance -c "mkdir -p $partdir/{routines,routines/$ydb_rel,globals,journals,etc,etc/xinetd.d,log,tmp,scripts,libraries,backup,partitions,src}"

# Copier les répertoires standards du dépot yrexpert-dmo
su $instance -c "cp -R $basedir/src/yrexpert-dmo/scripts $partdir"

echo "[03] Créer le fichier env de la partition $partition"
# Créer le fichier env
# Rechercher la version d'YDB
ydbver=$(ls -1 /usr/local/lib/yottadb | tail -1)
ydb_rel=$ydbver"_$ydb_arch"

echo "# Fichier des variables d'environnement créer par creerPartitionUtil.sh" >> $partdir/etc/env
echo "export ydb_gbldir=$partdir/globals/${partition^^}.gld"                   >> $partdir/etc/env
echo "export ydb_dir=$basedir"                  >> $partdir/etc/env
echo "export ydb_rel=$ydb_rel"	                >> $partdir/etc/env
#TODO: traiter le cas autre que 64bit
# YDB 64bit peut utiliser une bibliothèque partagée
echo "export ydb_routines=\"$partdir/routines/$ydb_rel($partdir/routines) /usr/local/lib/yottadb/$ydbver/utf8/libyottadbutil.so\"" >> $partdir/etc/env
echo "export ydb_dist=/usr/local/lib/yottadb/$ydbver"	        >> $partdir/etc/env
echo "export instance=$instance"                >> $partdir/etc/env
echo "export ydb_arch=$ydb_arch"                >> $partdir/etc/env
echo "export ydbver=$ydbver"                    >> $partdir/etc/env
echo "export ydb_log=$basedir/log"              >> $partdir/etc/env
echo "export ydb_tmp=$basedir/tmp"              >> $partdir/etc/env
echo "export ydb_prompt=\"${partition^^}>\""    >> $partdir/etc/env
echo "export ydb_zinterrupt='I \$\$JOBEXAM^ZU(\$ZPOSITION)'" 	>> $partdir/etc/env
echo "export ydb_lvnullsubs=2"                  >> $partdir/etc/env
echo "export PATH=\$PATH:$ydb_dist/utf8"        >> $partdir/etc/env
echo "export ydb_icu_version=`uconv --version | cut -d' ' -f5`"	>> $partdir/etc/env
echo "export ydb_chset=UTF-8"			        >> $partdir/etc/env
echo "export partition=$partition"              >> $partdir/etc/env

# Mettre les droits corrects pour env
chown $instance:$instance $partdir/etc/env

# Mettre les droits corrects pour $partdir
chown $instance:$instance $partdir

echo "[04] Créer les globals de l'utilisateur $partition"
# Créer les globals DMO
# TODO: Introduire la notion de version de ydb
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
su $instance -c "source $partdir/etc/env && $ydb_dist/mumps -run GDE < $partdir/etc/db.gde >> $partdir/log/sortieGDE.log 2>&1"

echo "[05] Créer la base de données de l'utilisateur $partition"
# Créer la base de données
echo "Créer la base de données"
su $instance -c "source $partdir/etc/env && $ydb_dist/mupip create >> $partdir/log/sortieGDE.log 2>&1"
echo "Création de la base de données terminée"

echo "[06] Mettre les droits"
chown -R $instance:$instance $basedir
chmod -R g+rw $basedir

echo "[OK] La partition DMO de YRExpert de l'instance $instance est créée..."




