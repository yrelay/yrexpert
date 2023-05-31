#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script liste les instances YRExpert présentent sur ce serveur
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

    Ce script liste les instances YRExpert présentent sur ce serveur

    Exemple : ./listerInstance.sh

    DEFAULTS:

    OPTIONS:
      -h    Afficher ce message

EOF
}

while getopts "h:" option
do
    case $option in
        h)
            usage
            exit 0
            ;;
    esac
done

if [[ -z $affLigne ]]; then
    affLigne=true
fi

if $affLigne; then
    # Rechercher les instances YRExpert
    instances=`ls /home`
    if [ ! -z "${instances}" ] ; then
        instancesYRExpert=""
        for instance in ${instances}; do
            if [[ -e /home/$instance/etc/yrexpert-release ]]; then
                instancesYRExpert=$instancesYRExpert" "$instance
            fi
        done
        # Affiche chaque instance YRExpert
        echo $instancesYRExpert
    fi
fi
