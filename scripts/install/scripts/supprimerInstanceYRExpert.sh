#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script supprime une instance YRExpert et en option sa base de données
# Par exemple : Supprimer des répertoires Routines, Objects, Globals, Journals,
# Temp Files
#
# 22 mars 2023
#


# Assurez-vous que nous sommes en root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root" 1>&2
    exit 1
fi

# Options
# instance = nom de l'instance
# Utilisation http://rsalveti.wordpress.com/2007/04/03/bash-parsing-arguments-with-getopts/
# Documentation à titre indicatif

usage()
{
    cat << EOF
    usage: $0 options

    Ce script supprime une instance YRExpert et en option sa base de données

    DEFAULTS:
      Forcer la supression              = false
      Supprimer la base de données liée = false

    OPTIONS:
      -h    Afficher ce message
      -f    Forcer la supression
      -i    Nom de l'instance
      -s    Supprimer la base de données liée
EOF
}

while getopts "fhi:s" option
do
    case $option in
        h)
            usage
            exit 1
            ;;
        f)
            forcerSuppresion=true
            ;;
        i)
            instance=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
            ;;
        s)
            suprimerDB=true
            ;;
    esac
done

if [[ -z $forcerSuppresion ]]; then
    forcerSuppresion=false
fi

if [[ -z $instance ]]
then
    echo
    echo "Le nom de l'instance à supprimer est requis !"
    echo
    usage
    exit 1
fi

if [[ -z $suprimerDB ]]; then
    suprimerDB=false
fi

if [[ -z $basedir ]]
then
    export basedir=/home/$instance
fi

# Résumer des options
echo "!--------------------------------------------------------------------------!"
echo "                                    supprimerInstanceYRExpert.sh"
echo "Nom de l'instance à supprimer     : $instance"
echo "Forcer la suppression             : $forcerSuppresion"
echo "Supprimer la base de données liée : $suprimerDB"
echo "!--------------------------------------------------------------------------!"

### set -e # Fermeture lors d'un code retour différent de 0
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


echo "[ 02 ]($forcerSuppresion) Forcer la supression de l'instance $instance"
if [[ $forcerSuppresion = true ]]; then
    if [[ -e /home/$instance/etc/yrexpert-release ]] ; then
        echo "L'instance" $instance "est reconnue comme une instance de YRExpert."
        echo "Essayer de supprimer proprement les services."
        if [[ -d /etc/init.d/${instance}-yrexpert ]]; then
            # Fermer d'une manière douce
            /etc/init.d/${instance}-yrexpert-js stop
            rm /etc/init.d/${instance}-yrexpert-js
            /etc/init.d/${instance}-yrexpert stop
            rm /etc/init.d/${instance}-yrexpert
        fi

        # Rechercher les processus $instance qui sont encore en cours d'exécution
        # TODO: Fermer d'une manière plus douce
        echo "Les processus liés à l'instance $instance seront fermer de force !"
        echo "Tuer les process de l'instance $instance"
        pkill -u $instance"util"
        pkill -u $instance"prog"
        pkill -u $instance

        echo "10 seconds d'attente"
        sleep 10

        echo "Lister les process de $instance*"
        ps -u $instance"util"
        ps -u $instance"prog"
        ps -u $instance

        echo "Supprimer l'instance $instance"
        # Supprimer proprement les utilisateurs
        if grep "^${instance}util:" /etc/passwd > /dev/null; then
            deluser --remove-home ${instance}util
        fi
        if grep "^${instance}prog:" /etc/passwd > /dev/null; then
            deluser --remove-home ${instance}prog
        fi
        if grep "^${instance}:" /etc/passwd > /dev/null; then
            deluser --remove-home ${instance}
        fi
        if grep "^${instance}:" /etc/group > /dev/null; then
            delgroup ${instance}
        fi

        # Si $instance n'est pas encore supprimée
        if [[ -d /home/$instance ]]; then
            rm -rf /home/$instance
        fi
    else
        echo "L'instance" $instance "n'est pas reconnue comme une instance de YRExpert."
        echo "Vous devez suprimer cette instance manuellement."
        exit 1
    fi
fi

echo "[ 03 ] Vérifier la supression de l'instance $instance"
# Vérifier existance de l'instance si non sortir
if grep "^$instance:" /etc/passwd > /dev/null ||
   grep "^${instance}util:" /etc/passwd > /dev/null ||
   grep "^${instance}prog:" /etc/passwd > /dev/null ; then
    if [[ -e /home/$instance/etc/yrexpert-release ]] ; then
        echo "L'instance" $instance "est reconnue comme une instance de YRExpert."
    else
        echo
        echo "L'instance" $instance "n'est pas reconnue comme une instance de YRExpert."
        echo "Ajouter l'option -f pour forcer la suppression de l'instance $instance."
        exit 1
    fi
fi

echo "[ 04 ]($forcerSuppresion) Suprimer proprement l'instance $instance"
# Supprimer proprement les services
echo "Supprimer proprement les services."
if [[ -e /etc/init.d/${instance}-yrexpert-js ]]; then
    echo "Fermer d'une manière douce ${instance}-yrexpert-js"
    /etc/init.d/${instance}-yrexpert-js stop
    rm /etc/init.d/${instance}-yrexpert-js
fi

if [[ -e /etc/init.d/${instance}-yrexpert ]]; then
    echo "Fermer d'une manière douce ${instance}-yrexpert"
    /etc/init.d/${instance}-yrexpert stop
    ls /etc/init.d/${instance}-yrexpert
    rm /etc/init.d/${instance}-yrexpert
fi

# Supprimer proprement les utilisateurs
echo "Les processus liés à l'instance $instance seront fermer de force !"
echo "Tuer les process de l'instance $instance"
pkill -9 -u $instance"util"
pkill -9 -u $instance"prog"
pkill -9 -u $instance

echo "10 seconds d'attente"
sleep 10

echo "Lister les process yrelay*"
ps -u ${instance}util
ps -u ${instance}prog
ps -u ${instance}

# Supprimer proprement les utilisateurs
echo "Supprimer l'instance $instance"
if grep "^${instance}util:" /etc/passwd > /dev/null; then
    deluser --remove-home ${instance}util
fi
if grep "^${instance}prog:" /etc/passwd > /dev/null; then
    deluser --remove-home ${instance}prog
fi
if grep "^${instance}:" /etc/passwd > /dev/null; then
    deluser --remove-home ${instance}
fi
if grep "^${instance}:" /etc/group > /dev/null; then
    delgroup ${instance}
fi

# Si $instance n'est pas encore supprimée
if [[ -d /home/$instance ]]; then
    rm -rf /home/$instance
fi

echo "[ 05 ]($supprimerDB) Supprimer la base de données $yre_db si elle existe"
# Supprimer la base de données si elle existe.
if [[ $supprimerDB = true ]]; then
    if [[ -e $basedir/scripts/deinstaller$yre_db.sh ]]; then
        echo "Supprimer la base données $yre_db"
        $basedir/scripts/deinstaller$yre_db.sh
    else
        echo
        echo "L'outil de supression de la base de données est introuvable !"
        echo "Suprimer la base de données $yre_db manuellement."
        exit 1
    fi
    if [[ "$?" != 0 ]];then
        echo
        echo "La supression de la base de données est impossible !"
        echo "Suprimer la base de données $yre_db manuellement."
        exit 2
    fi 
fi

echo "[OK] L'instance $instance est supprimé..."
