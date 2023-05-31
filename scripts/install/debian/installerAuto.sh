#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script permet de créer automatiquement une instance YRExpert
#
# 22 mars 2023
#

# Assurez-vous que nous sommes en root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root" 1>&2
    exit 1
fi

# Sur mon système, j’initialise les variables LANG et LC_MESSAGES à,
# respectivement, fr_FR.utf8 et en_US.utf8. Ainsi, les différents programmes
# appliquent les paramètres régionaux français à l’exception des messages qui
# sont affichés en anglais. Cela implique de bien inclure ces deux « locales »
# dans le fichier /etc/locale.gen. Toutefois, celles-ci peuvent être
# indisponibles sur certains systèmes distants. La plupart des applications se
# rabattent sur la locale C sans broncher. Une exception notable est Perl qui
# se plaint très bruyamment.
# La documentation de Perl explique comment se débarasser de ce message.

export PERL_BADLANG=0

# Si fr_FR.UTF-8 n'est pas installé,
# lancer "sudo dpkg-reconfigure locales"
# choisir UTF8 en_US.UTF-8 + fr_FR.UTF-8

# Options
# instance = nom de l'instance
# utilisation http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
# documentation à titre indicatif

usage()
{
    cat << EOF
    usage: $0 options

    Ce script permet de créer automatiquement une instance YRExpert

    Exemple : ./installerAuto.sh -r -e -i yrexpert -m ydb
              installer en automatique yrexpert
              -e installer yrexpert-js (interface web)
              -i créer une instance nommée yrexpert
              -m créer/utiliser la base de données nommée ydb

    DEFAULTS:

          Source = https://github.com/yrelay/yrexpert.git

      a - Dépôt yrexpert-m alternatif =
          https://github.com/yrelay/yrexpert-m.git
      b - Dépôt yrexpert-js alternatif =
          https://github.com/yrelay/yrexpert-js.git
      c - Dépôt de la partition utilisateur alternatif (dmo) =
          https://github.com/yrelay/yrexpert-dmo.git
      d - Créer les répertoires de développement (s & p) = false
      e - Installer yrexpert-js (interface web) = false
      i - Nom de l'instance = yrexpert
      j - Nom de la partition utilisateur = dmo
      m - Base de données mumps alternatif = ydb
      n - Réinstaller la base de données mumps = false
      r - Réinstaller l'instance = false
      s - Passer les tests = false

    OPTIONS:
      -h    Afficher ce message
      -a    Dépôt yrexpert-m alternatif (Doit être au format Yrelay)
      -b    Dépôt yrexpert-js alternatif (doit être au format Yrelay)
      -c    Dépôt yrexpert-dmo alternatif (doit être au format Yrelay)
      -d    Créer les répertoires de développement (s & p)
      -e    Installer yrexpert-js (interface web)
      -i    Nom de l'instance
      -j    Nom de la partition utilisateur (dmo)
      -m    Base de données alternatif (ydb ou gtm)
      -n    Réinstaller la base de données mumps (ydb ou gtm)
      -r    Réinstaller l'instance (supprimera les données !!!)
      -s    Passer les tests

EOF
}

while getopts "ha:b:c:dei:j:m:nrs" option
do
    case $option in
        h)
            usage
            exit 0
            ;;
        a)
            cheminDepotM=$OPTARG
            ;;
        b)
            cheminDepotJS=$OPTARG
            ;;
        c)
            cheminDepotPartUtil=$OPTARG
            ;;
        d)
            repertoireDev=true
            devInstallation=true
            ;;
        e)
            installerJS=true
            ;;
        i)
            instance=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            ;;
        j)
            partitionUtil=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            ;;
        m)
            yre_db=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            if [[ $yre_db != gtm ]] && [[ $yre_db != ydb ]]; then
                echo "La base de données $yre_db n'est pas reconnue !"
                echo
                usage
                exit 1
            fi
            ;;
        n)
            reInstallBDD=true
            ;;
        r)
            reInstall=true
            ;;
        s)
            passerLesTests=true
            ;;
    esac
done

# Paramètres par défaut pour les options
if [[ -z $cheminDepot ]]; then 
    cheminDepot="https://github.com/yrelay/"
fi

if [[ -z $cheminDepotYRE ]]; then
    cheminDepotYRE="https://github.com/yrelay/yrexpert.git"
fi

if [[ -z $cheminDepotM ]]; then
    cheminDepotM="https://github.com/yrelay/yrexpert-m.git"
fi

if [[ -z $cheminDepotJS ]]; then
    cheminDepotJS="https://github.com/yrelay/yrexpert-js.git"
fi

if [[ -z $cheminDepotPartUtil ]]; then
    cheminDepotPartUtil="https://github.com/yrelay/yrexpert-dmo.git"
fi

if [[ -z $repertoireDev ]]; then
    repertoireDev=false
    devInstallation=false
fi

if [[ -z $installerJS ]]; then
    installerJS=false
fi

if [[ -z $devInstallation ]]; then
    devInstallation=false
fi

if [[ -z $instance ]]; then
    instance=yrexpert
fi

if [[ -z $partitionUtil ]]; then
    partitionUtil=dmo
fi

if [[ -z $yre_db ]]; then
    yre_db=ydb
fi

if [[ -z $reInstallBDD ]]; then
    reInstallBDD=false
fi

if [[ -z $reInstall ]]; then
    reInstall=false
fi

if [[ -z $passerLesTests ]]; then
    passerLesTests=false
fi

basedir=/home/$instance

# Résumer des options
echo "!--------------------------------------------------------------------------!"
echo "                                                installerAuto.sh"
echo "Utiliser $cheminDepot pour les routines et globales"
echo "a - Utiliser $cheminDepotM pour yrexpert-m"
echo "b - Utiliser $cheminDepotJS pour yrexpert-js"
echo "c - Utiliser $cheminDepotPartUtil pour yrexpert-dmo"
echo "d - Créer les répertoires de développement    : $repertoireDev"
echo "e - Installer yrexpert-js                     : $installerJS"
echo "i - Installer l'instance nommée               : $instance"
echo "j - Installer la partition utilisateur nommée : $partitionUtil"
echo "m - Base de données mumps alternatif          : $yre_db"
echo "n - Réinstaller la base de données            : $reInstallBDD"
echo "r - Réinstaller l'instance                    : $reInstall"
echo "s - Passer les tests                          : $passerLesTests"
echo "!--------------------------------------------------------------------------!"

echo "[ 01 ] Mettre à jour le système d'exploitation"
# le contrôle de l'interactivité des outils de Debian
export DEBIAN_FRONTEND="noninteractive"

# Indiquer au scripts que nous sommes sur une distribution debian
export debian=true;

# Déterminer l'architecture du processeur - utilisé pour déterminer si nous pouvons utiliser YDB
arch=$(uname -m | tr -d _)
if [ $arch == "x8664" ]; then
    ydb_arch="x86_64"
else
    ydb_arch="i386"
fi

# utilitaires supplémentaires - utilisé pour les clones initiaux
# Remarque: Amazon EC2 nécessite deux commandes apt-get update pour fonctionner
apt-get update -qq
apt-get update -qq
apt-get install -qq

echo "[ 02 ] Amorcer le sytème" 
if [[ -d /vagrant ]]; then
    # Se posionner sur le répertoire ou se trouve le fichier amorcerServeurDebian.sh
    repScript=/vagrant
    cd /vagrant/debian
else
    # Se posionner sur le répertoire ou se trouve le fichier courant
    cd $(readlink -f $(dirname $0))
fi
# Amorcer le sytème
./amorcerServeurDebian.sh

echo "[ 03 ] Cloner le dépôt yrexpert" 
# Voir si le dossier vagrant existe si oui l'utiliser. si non cloner le dépôt
if [[ -d /vagrant ]]; then
    repScript=/vagrant

    # Convertir les fins de lignes
    find /vagrant -name \"*.sh\" -type f -print0 | xargs -0 dos2unix
    dos2unix /vagrant/$yre_db/etc/init.d/yrexpert
    dos2unix /vagrant/$yre_db/etc/init.d/yrexpert-js

else
    if [[ -d /usr/local/src/yrexpert ]]; then
        rm -rf /usr/local/src/yrexpert
    fi
    # Tester l'existance du dépôt
    a=$(echo $cheminDepotYRE | grep / | cut -d/ -f4-)
    b=$(echo $a | cut -f1 -d'.')
    c=$(echo "https://api.github.com/repos/$b")
    curl -v --silent $c 2>&1 | grep "Not Found" > /dev/null
    if ! [[ $? = 0 ]]; then
        cd /usr/local/src
        git clone -q $cheminDepotYRE yrexpert
        repScript=/usr/local/src/yrexpert
    else
        # Se posionner sur le répertoire ou se trouve le fichier courant
        cd $(readlink -f $(dirname $0))
        # Reculer à la racine du dépôt
        cd ..
        repScript=`pwd`
    fi
fi

echo "[ 04 ] Installer la base de données $yre_db"
cd $repScript
# Installaler la base de données $yre_db
if $reInstallBDD; then
    # Désinstaller et réinstaller avec la dernière version de $yre_db
    > ./log/desinstaller$(echo $yre_db |tr '[:lower:]' '[:upper:]').log 2>&1
    ./$yre_db/scripts/desinstaller$(echo $yre_db |tr '[:lower:]' '[:upper:]').sh >> ./log/desinstaller$(echo $yre_db |tr '[:lower:]' '[:upper:]').log 2>&1
    > ./log/installer$(echo $yre_db |tr '[:lower:]' '[:upper:]').log 2>&1
    ./$yre_db/scripts/installer$(echo $yre_db |tr '[:lower:]' '[:upper:]').sh >> ./log/installer$(echo $yre_db |tr '[:lower:]' '[:upper:]').log 2>&1
fi

# Rechercher si une version est installée
if [[ -d /usr/lib/fis-gtm ]] && [[ $yre_db = "gtm" ]] ||
   [[ -d /usr/local/lib/yottadb ]] && [[ $yre_db = "ydb" ]]; then
    # Rechercher la version installée
    if [[ $yre_db = "gtm" ]]; then dirs=$(find /usr/lib/fis-gtm -maxdepth 1 -type d -printf '%P\n') ;fi
    if [[ $yre_db = "ydb" ]]; then dirs=$(find /usr/local/lib/yottadb -maxdepth 1 -type d -printf '%P\n') ;fi
    # Nous pouvons lister les répertoires si > 1 erreur de répertoire
    if [[ $dirs -gt 2 ]]; then
        echo "Plus d'une version de $yre_db installée !"
        echo "Impossible de déterminer quelle version de $yre_db à utiliser !"
        exit 1
    fi
    echo
    echo "La version $yre_db" $dirs "est déjà installée"
    echo "Vous pouvez réinstaller la base de données $yre_db en ajoutant l'option -n"
    echo "ATTENTION : avec l'option -n $yre_db sera désinstallé
 et réinstaller avec la dernière version."
else
    # Installer la dernière version de $yre_db
    > ./log/installer$(echo $yre_db |tr '[:lower:]' '[:upper:]').log 2>&1
    ./$yre_db/scripts/installer$(echo $yre_db |tr '[:lower:]' '[:upper:]').sh >> ./log/installer$(echo $yre_db |tr '[:lower:]' '[:upper:]').log 2>&1
fi

# Rechercher si une version $yre_db est installéé
if ! [[ -d /usr/lib/fis-gtm ]] && [[ $yre_db = "gtm" ]] ||
   ! [[ -d /usr/local/lib/yottadb ]] && [[ $yre_db = "ydb" ]]; then
    echo
    echo "La base de données $yre_db est requise !"
    exit 1
fi

ydbver=$(ls -1 /usr/local/lib/yottadb | tail -1)
ydb_dist=/usr/local/lib/yottadb/$ydbver
ydb_rel=$ydbver"_$ydb_arch"

gtm_rel=$(ls -1 /usr/lib/fis-gtm | tail -1)
gtmver=$(echo $gtm_rel | cut -f1 -d'_')
gtm_dist=/usr/local/lib/yottadb/$gtm_rel

set +e # Ne termine pas immédiatement si une commande s'arrête avec un code de retour non nul
echo "[ 05 ] Tester l'installation de l'instance $instance" 
cd $repScript

> ./log/creerInstanceYRExpert.log 2>&1

# Créer une instance YRExpert
if $reInstall; then
    ./$yre_db/scripts/creerInstanceYRExpert.sh -rt -i $instance >> ./log/creerInstanceYRExpert.log 2>&1
else
    ./$yre_db/scripts/creerInstanceYRExpert.sh -t -i $instance >> ./log/creerInstanceYRExpert.log 2>&1
fi

# Si le test de création n'est pas OK, alors sortir
if [[ $? != 0 ]]; then
    set -e # Termine immédiatement si une commande s'arrête avec un code de retour non nul
    echo
    # Afficher le fichier log
    cat ./log/creerInstanceYRExpert.log
    exit 1
fi
set -e # Termine immédiatement si une commande s'arrête avec un code de retour non nul

set +e # Ne termine pas immédiatement si une commande s'arrête avec un code de retour non nul
echo "[ 06 ] Créer l'instance $instance" 
# Créer une instance YRExpert $yre_db
cd $repScript
if $reInstall; then
    ./$yre_db/scripts/creerInstanceYRExpert.sh -r -i $instance >> ./log/creerInstanceYRExpert.log 2>&1
else
    ./$yre_db/scripts/creerInstanceYRExpert.sh -i $instance >> ./log/creerInstanceYRExpert.log 2>&1
fi

# Abandonner l'installation si l'instance n'a pas été créée
if ! [[ -e /home/$instance/etc/yrexpert-release ]] ; then
    echo
    # Afficher le fichier log
    cat ./log/creerInstanceYRExpert.log
    exit 0
fi

echo "[ 07 ] Importer les routines m depuis le dépôt $cheminDepotM" 
#TODO: Tester l'existance du dépôt
# Cloner le dépot yrexpert-m
# Tester l'existance du dépôt
a=$(echo $cheminDepotM | grep / | cut -d/ -f4-)
b=$(echo $a | cut -f1 -d'.')
c=$(echo "https://api.github.com/repos/$b")
curl -v --silent $c 2>&1 | grep "Not Found" > /dev/null
if ! [[ $? = 0 ]]; then
    cd $basedir/src
    git clone $cheminDepotM yrexpert-m >> $basedir/log/clonerYrexpert-m.log 2>&1
else
    # Le dépôt n'existe pas
    echo
    echo "Le dépôt $cheminDepotM n'existe pas !"
    exit 1
fi

# Retourner à $repScript
cd $repScript
# Effectuer l'importation
su $instance -c "source $basedir/etc/env && ./$yre_db/scripts/importerYRExpert-m.sh"                       >> $basedir/log/importerYRExpert-m.log 2>&1

echo "[ 08 ]($passerLesTests) Lancer les tests utilisés par Yrelay" 
cd $repScript
if $passerLesTests; then
    # Créer une chaîne aléatoire pour l'identification de la construction
    export buildID=`tr -dc "[:alpha:]" < /dev/urandom | head -c 8`

    # Importer YRExpert et lancer les tests utilisés par Yrelay
    su $instance -c "source $basedir/etc/env && ctest -S ./debian/test.cmake -V"                        >> $basedir/log/test.log 2>&1
    # Dire aux utilisateurs leur ID de construction
    echo "Votre ID de construction est: $buildID vous en aurez besoin pour identifier votre construction sur YRExpert"
fi

echo "[ 09 ] Activer la journalisation et Redémarrer xinetd" 
# Activer la journalisation
su $instance -c "source $basedir/etc/env && $basedir/scripts/activerJournal.sh -i $instance -p yxp"     >> $basedir/log/installerAuto.log 2>&1

# Redémarrer xinetd
service xinetd restart                                                                                  >> $basedir/log/installerAuto.log 2>&1

echo "[ 10 ]($repertoireDev) Ajouter P et S répertoires à la variable d'environnement gtmroutines / ydb_routines" 
# Ajouter P et S répertoires à la variable d'environnement gtmroutines / ydb_routines
if $repertoireDev; then
    if [[ $yre_db = "gtm" ]]; then
        su $instance -c "mkdir $basedir/{p,p/$gtm_rel,s,s/$gtm_rel}"
        perl -pi -e 's#export gtmroutines=\"#export gtmroutines=\"\$basedir/p/\$gtm_rel\(\$basedir/p\) \$basedir/s/\$gtm_rel\(\$basedir/s\) #' $basedir/etc/env >> $basedir/log/installerAuto.log 2>&1
    else
        su $instance -c "mkdir $basedir/{p,p/$gtm_rel,s,s/$gtm_rel}"
        perl -pi -e 's#export ydb_routines=\"#export ydb_routines=\"$basedir/p/$ydb_rel\($basedir/p\) $basedir/s/$ydb_rel\($basedir/s\) #' $basedir/etc/env >> $basedir/log/installerAuto.log 2>&1
    fi
fi

echo "[ 11 ] Créer et importer la partition utilisateur dmo depuis le dépôt $cheminDepotPartUtil" 
# Construire un environnement pour la partition utilisateur (par défaut DMO)
# L'environnement de la partition utilisateur sera cloner depuis le dépot $partitionUtil 

# Cloner le dépot de la partition utilisateur (par défaut yrexpert-dmo)
# Tester l'existance du dépôt
a=$(echo $cheminDepotPartUtil | grep / | cut -d/ -f4-)
b=$(echo $a | cut -f1 -d'.')
c=$(echo "https://api.github.com/repos/$b")
curl -v --silent $c 2>&1 | grep "Not Found" > /dev/null
if ! [[ $? = 0 ]]; then
    cd $basedir/src
    git clone $cheminDepotPartUtil yrexpert-${partitionUtil} >> $basedir/log/clonerYrexpert-${partitionUtil}.log 2>&1
else
    # Le dépôt n'existe pas
    echo
    echo "Le dépôt $cheminDepotPartUtil n'existe pas !"
    exit 1
fi

# Retourner à $repScript
cd $repScript

# Créer une partition utilisateur
./$yre_db/scripts/creerPartitionUtil.sh -i $instance -p ${partitionUtil^^} >> $basedir/log/creerPartitionUtil.log 2>&1

# Effectuer l'importation de yrexpert-$partitionUtil
su $instance -c "source $basedir/partitions/${partitionUtil,,}/etc/env && ./$yre_db/scripts/importerPartitionUtil.sh" >> $basedir/log/importerPartitionUtil.log 2>&1

set +e # Ne termine pas immédiatement si une commande s'arrête avec un code de retour non nul
echo "[ 12 ]($installerJS) Installer yrexpert-js depuis le dépôt $cheminDepotJS" 
# Retourner à $repScript
cd $repScript

# Installer yrexpert-js
if $installerJS; then
    ./yrexpert-js/scripts/yrexpert-js.sh -i $instance >> $basedir/log/yrexpert-js.log
fi

# Si la création n'est pas OK, alors sortir
if [[ $? != 0 ]]; then
    set -e # Termine immédiatement si une commande s'arrête avec un code de retour non nul
    echo
    # Afficher le fichier log
    cat $basedir/log/yrexpert-js.log
    exit  1
fi

echo "[ 13 ]($devInstallation) Ajouter les outils de développement" 
# Ajouter les outils de développement
# Axiom - Developer tools for editing M[UMPS]/GT.M routines in Vim
if $devInstallation; then
    apt-get install vim -y                                                          >> $basedir/log/installerAuto.log 2>&1
    cd $basedir/src
    git clone https://github.com/dlwicksell/axiom.git                               >> $basedir/log/installerAuto.log 2>&1
    cd axiom
    su $instance -c "source $basedir/etc/env && ./install -q"                       >> $basedir/log/installerAuto.log 2>&1
    # Retourner à $basedir
    cd $basedir
fi

echo "[ 14 ] Relancer les services" 
# Relancer les services
# TODO: à optimiser pour ne relancer qu'une fois
echo "Redémarrer les services ${instance}-yrexpert et ${instance}-yrexpert-js"      >> $basedir/log/installerAuto.log 2>&1
echo "Et qu'ils soient lancés automatiquement au démarrage du système."             >> $basedir/log/installerAuto.log 2>&1
systemctl daemon-reload                                                             >> $basedir/log/installerAuto.log 2>&1
if [[ -e /etc/init.d/${instance}-yrexpert ]]; then
    # Démarrer le service
    service ${instance}-yrexpert restart                                            >> $basedir/log/installerAuto.log 2>&1
    # Ajouter ce service au démarrage
    update-rc.d ${instance}-yrexpert defaults 80 20                                 >> $basedir/log/installerAuto.log 2>&1
fi

if [[ -e /etc/init.d/${instance}-yrexpert-js ]]; then
    service ${instance}-yrexpert-js restart                                         >> $basedir/log/installerAuto.log 2>&1
    # Ajouter ce service au démarrage
    update-rc.d ${instance}-yrexpert-js defaults 85 15                              >> $basedir/log/installerAuto.log 2>&1
fi

echo "[ 15 ] Mettre les droits"
chown -R $instance:$instance $basedir
chmod -R g+rw $basedir

echo "[ OK ] L'installation Auto est terminée..."
echo "Les logs d'installation sont ici :"
echo $repScript/log
echo $basedir/log

