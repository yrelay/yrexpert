#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script supprime une partition YRExpert
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
      -p    Nom de la partition
EOF
}

while getopts "hfi:p:" option
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
        p)
            partition=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
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

if [[ -z $partition ]]
then
    echo
    echo "Le nom de la partition à supprimer est requis !"
    echo
    usage
    exit 1
fi

if [[ -z $basedir ]]
then
    export basedir=/home/$instance
fi

# Résumer des options
echo "!--------------------------------------------------------------------------!"
echo "                                  supprimerPartitionUtil.sh"
echo "Nom de l'instance à supprimer     : $instance"
echo "Nom de la partition à supprimer   : $partition"
echo "Forcer la suppression             : $forcerSuppresion"
echo "!--------------------------------------------------------------------------!"

if [[ $forcerSuppresion = true ]]; then
    # Supprimer proprement les services
    echo "Supprimer proprement les services."
    if [[ -e /etc/init.d/${instance}-yrexpert-js ]]; then
        echo "Fermer d'une manière douce ${instance}-yrexpert-js"
        /etc/init.d/${instance}-yrexpert-js stop
    fi

    if [[ -e /etc/init.d/${instance}-yrexpert ]]; then
        echo "Fermer d'une manière douce ${instance}-yrexpert-js"
        /etc/init.d/${instance}-yrexpert stop
    fi

    if [[ -e /home/$instance/etc/yrexpert-release ]] ; then
        echo "L'instance" $instance "est reconnue comme une instance de YRExpert."
        # TODO: Fermer/supprimer d'une manière plus douce
        echo "Les processus liés à l'instance $instance seront fermer de force !"
        echo "Tuer les process de l'instance $instance"
        pkill -u $instance
        pkill -u $instance"util"
        pkill -u $instance"prog"

        echo "10 seconds d'attente"
        sleep 10

        # Supprimer la partition
        if [[ -d /home/$instance/partitions/$partition ]]; then
            rm -rf /home/$instance/partitions/$partition
        else
            echo
            echo "La partition $partition de l'instance" $instance "n'est pas reconnue ou n'existe pas !"
            echo "Vous devez suprimer la partition $partition manuellement."
        exit 1
        fi
    else
        echo
        echo "L'instance" $instance "n'est pas reconnue comme une instance de YRExpert."
        echo "Vous devez suprimer la partition $partition manuellement."
        exit 1
    fi

    # Vérifier existance de l'instance si non sortir
    if [[ -e /home/$instance/etc/yrexpert-release ]] ; then
        echo "L'instance" $instance "est reconnue comme une instance de YRExpert."
    else
        echo
        echo "L'instance" $instance "n'est pas reconnue comme une instance de YRExpert."
        echo "Vous devez suprimer la partition $partition manuellement."
        exit 1
    fi
fi

# Supprimer proprement les utilisateurs
echo "Les processus liés à l'instance $instance seront fermer de force !"
echo "Tuer les process de l'instance $instance"
pkill -u $instance
pkill -u $instance"util"
pkill -u $instance"prog"

# Supprimer la partition
if [[ -d /home/$instance/partitions/$partition ]]; then
    rm -rf /home/$instance/partitions/$partition
else
    echo
    echo "La partition $partition de l'instance" $instance "n'est pas reconnue ou n'existe pas !"
    echo "Vous devez suprimer la partition $partition manuellement."
    exit 1
fi

echo "[OK] La partition $partition de l'instance $instance est supprimé..."

