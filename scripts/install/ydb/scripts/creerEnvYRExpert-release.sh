#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script permet de créer les variables d'environnement yrexpert-release
#
# 22 mars 2023
#

cheminYRErelease=/home/yrelay/etc/yrexpert-release
#echo $cheminYRErelease

# Parser les variables d'environnement de yrexpert-release
variables=$(grep "=" $cheminYRErelease)
if [ ! -z "${variables}" ] ; then
    # "Parser les variables d'environnement de yrexpert-release"
    for i in ${variables}
    do
        ligne=${i}
        variable=$(echo $i | cut -f1 -d=)
        valeur=$(echo $i | grep = | cut -d= -f2-)
        if [[ $variable = yre_pretty_name ]];         then export yre_pretty_name=$valeur ;fi       
        if [[ $variable = yre_name ]];                then export yre_name=$valeur ;fi       
        if [[ $variable = yre_version_id ]];          then export yre_version_id=$valeur ;fi       
        if [[ $variable = yre_version ]];             then export yre_version=$valeur ;fi       
        if [[ $variable = yre_version_codename ]];    then export yre_version_codename=$valeur ;fi       
        if [[ $variable = yre_id ]];                  then export yre_id=$valeur ;fi       
        if [[ $variable = yre_db ]];                  then export yre_db=$valeur ;fi       
        if [[ $variable = yre_home_url ]];            then export yre_home_url=$valeur ;fi       
        if [[ $variable = yre_support_url ]];         then export yre_support_url=$valeur ;fi       
        if [[ $variable = yre_bug_report_url ]];      then export yre_bug_report_url=$valeur ;fi       
    done
fi

if [[ $1 = "verbeux" ]]; then
    echo "yre_pretty_name="$yre_pretty_name
    echo "yre_name="$yre_name
    echo "yre_version_id="$yre_version_id
    echo "yre_version="$yre_version
    echo "yre_version_codename="$yre_version_codename
    echo "yre_id="$yre_id
    echo "yre_db="$yre_db
    echo "yre_home_url="$yre_home_url
    echo "yre_support_url="$yre_support_url
    echo "yre_bug_report_url="$yre_bug_report_url
fi




