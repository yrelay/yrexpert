#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Ce script permet de créer une instance de YRExpert pour GTM :
# 	. créer les répertoires pour les routines, les objets, les globals,
# 	. les Journaux, les fichiers temporaires de l'instance
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

    Ce script permet de créer une instance pour YRexpert

    DEFAULTS:
      i - Nom de l'instance = yrexpert (obligatoire)
      m - Base de données mumps alternatif = ydb
      r - Supprimer et réinstaller l'instance = false
      t - Mode test tester = false

    OPTIONS:
      -h    Afficher ce message
      -i    Nom de l'instance
      -m    Base de données alternatif (ydb ou gtm)
      -r    Supprimer et réinstaller l'instance
      -t    Mode test
EOF
}

while getopts "hi:m:rt" option
do
    case $option in
        h)
            usage
            exit 0
            ;;
        i)
            instance=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
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
    echo "Le nom de l'instance est obligatoire !"
    echo
    usage
    exit 1
fi

if [[ -z $yre_db ]]; then
    echo
    echo "Le nom de la base de données est obligatoire !"
    echo "Relancer le script avec l'option -m (ydb ou gtm)"
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
        echo `lsb_release -d`
        echo "Impossible de déterminer la distribution !"
        exit 1
    fi
fi

# Résumer des options
echo "!--------------------------------------------------------------------------!"
echo "                              creerInstanceYRExpert.sh"
echo "Installer l'instance nommée   : $instance"
echo "Base de données alternatif    : $yre_db"
echo "Réinstallation                : $reInstall"
echo "Mode test                     : $modeTest"
echo "!--------------------------------------------------------------------------!"

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 01 ] Initialiser les variables d'environnement de yrexpert"
# Déterminer l'architecture du processeur - utilisé pour déterminer si nous pouvons utiliser YDB
arch=$(uname -m | tr -d _)
if [ $arch == "x8664" ]; then
    ydb_arch="x86_64"
else
    ydb_arch="i386"
fi

# $basedir est le répertoire de base de l'instance
# exemples d'installation possibles : /home/$instance, /opt/$instance, /var/db/$instance
basedir=/home/$instance

# Se posionner sur le répertoire ou se trouve le fichier courant
cd $(readlink -f $(dirname $0))
cd ..
cd ..
repScript=`pwd`

set +e # Pas de fermeture lors d'un code retour différent de 0
echo "[ 02 ] Tester s'il est possible d'installer l'instance" 
# Exit code 0 Success
# Exit code 1 General errors, Miscellaneous errors, such as "divide by zero" and other impermissible operations
# Exit code 2 Misuse of shell builtins (according to Bash documentation) Example: empty_function() {}
# Tester avec echo $?
if [[ -e /home/$instance/etc/yrexpert-release ]]; then
    echo "L'instance" $instance "est reconnue comme une instance de YRExpert."
    if $reInstall ; then
    	echo "Vous pouvez réinstaller l'instance $instance car l'option -r est activée."
    	echo "ATTENTION : avec l'option -r toutes les données seront perdues."
        if [[ $modeTest == true ]]; then
            echo
            echo "Vous pouvez installer l'instance $instance"
            exit 0
        fi
    else
        echo
    	echo "Vous pouvez réinstaller l'instance $instance en ajoutant l'option -r"
    	echo "ATTENTION : avec l'option -r toutes les données seront perdues."
        exit 1
    fi
else
    if [[ -d /home/$instance ]]
    then
        echo
        echo "L'instance" $instance "n'est pas reconnue comme une instance de YRExpert !"
        echo "Vous devez suprimer cette instance manuellement."
        exit 1
    else
        echo "L'instance" $instance "n'existe pas !"
        if [[ $modeTest == true ]]; then
            echo
            echo "Vous pouvez installer l'instance $instance"
            exit 0
        fi
    fi
fi

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 03 ] Vérifier l'installation la base de données $yre_db" 
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
    ydb_rel=$ydbver"_$ydb_arch"
    yre_rel=$ydb_rel
    basedist=$ydb_dist
fi

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 04 ] Installer icu-config s'il n'est pas installé" 
# Si icu-config n'est pas installé
apt-get install -y libicu-dev -qq

set +e # Ne pas fermeture lors d'un code retour différent de 0
echo "[ 05 ] Supprimer l'instance $instance si elle existe." 
if grep "^$instance:" /etc/passwd > /dev/null ||
   grep "^${instance}util:" /etc/passwd > /dev/null ||
   grep "^${instance}prog:" /etc/passwd > /dev/null ; then
    if [[ -e $basedir/scripts/supprimerInstanceYRExpert.sh ]]; then
        echo "Supprimer l'instance $instance"
        $basedir/scripts/supprimerInstanceYRExpert.sh -i $instance
    else
        if [[ -e $repScript/scripts/supprimerInstanceYRExpert.sh ]]; then
            echo "Supprimer l'instance $instance"
            $repScript/scripts/supprimerInstanceYRExpert.sh -i $instance
        else
            echo
            echo "L'outil de supression de l'instance est introuvable !"
            echo "Suprimer l'instance $instance manuellement."
            exit 1
        fi
    fi
    if [[ "$?" != 0 ]];then
        echo
        echo "La supression de l'instance $instance est impossible !"
        echo "Ajouter l'option -f pour forcer la suppression de l'instance $instance."
        exit 2
    fi 
fi

# Si le test de création n'est pas OK, alors sortir
if [[ $? != 0 ]]; then
    set -e # Fermeture lors d'un code retour différent de 0
    echo
    # Afficher le fichier log
    cat ./log/creerInstanceYRExpert.log
    exit  1
fi

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 06 ] Créer $instance User/Group."
cd $repScript

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

# $instance user est un user administrateur
# $instance group permet les autorisations à d'autres utilisateurs
# $instance group est automatiquement créé par le script adduser
useradd -c "Propriétaire de l'instance       $instance" -m -U    $instance -s /bin/bash
useradd -c "Compte utilisateur de l'instance $instance" -M -N -g $instance -s /home/$instance/scripts/util.sh -d /home/$instance ${instance}util
useradd -c "Compte programmeur de l'instance $instance" -M -N -g $instance -s /home/$instance/scripts/prog.sh -d /home/$instance ${instance}prog

# Changer le mot de passe pour les comptes liés
echo ${instance}:${instance} | chpasswd
echo ${instance}util:util    | chpasswd
echo ${instance}prog:prog    | chpasswd

# Obtenir le nom de l'utilisateur principal si vous utilisez sudo, default si $username n'est pas sudo ou root si $(id -u)=0
if [[ -n "$SUDO_USER" ]]; then
    utilisateurPrincipal=$SUDO_USER
elif [[ -n "$USERNAME" ]]; then
    utilisateurPrincipal=$USERNAME
elif [[ $EUID == 0 ]]; then
    utilisateurPrincipal="root"
else
    echo "Nom d'utilisateur non trouvé ou approprié à ajouter au groupe $instance"
    exit 1
fi
echo "Ce script va ajouter $utilisateurPrincipal au groupe $instance"
adduser $utilisateurPrincipal $instance

# Créer les répertoires de l'instance
su $instance -c "mkdir -p $basedir/{routines,routines/$yre_rel,globals,journals,etc,etc/xinetd.d,log,tmp,scripts,libraries,backup,partitions,src}"

# Créer un lien symbolique vers le chemin de l'instance $instance
ln -s $basedir $basedir/partitions/yxp

# Copier les répertoires standards etc et scripts du dépot
su $instance -c "cp -R $repScript/$yre_db/etc $basedir"
su $instance -c "cp -R $repScript/$yre_db/scripts $basedir"

# Mofifier les répertoires xinetd.d et scripts pour qu'ils reflètent l'instance $instance
# TODO: Voir l'utilité de xinetd.d
perl -pi -e 's/y-instance/'$instance'/g' $basedir/scripts/*.sh

# Modify init.d script to reflect $instance
perl -pi -e 's/y-instance/'$instance'/g' $basedir/etc/init.d/y-instance-yrexpert

# Créer le démmarrage du service
# TODO: Faire fonctionner avec un lien -h
if [[ -f /etc/init.d/${instance}-yrexpert ]]; then
    rm /etc/init.d/${instance}-yrexpert
fi
#ln -s $basedir/etc/init.d/yrexpert /etc/init.d/${instance}yrexpert
cp $basedir/etc/init.d/y-instance-yrexpert /etc/init.d/${instance}-yrexpert

# Installer le script init
if [[ $debian || -z $RHEL ]]; then
    update-rc.d ${instance}-yrexpert defaults 80 20
fi

if [[ $RHEL || -z $debian ]]; then
    # TODO: voir https://confluence.jaytaala.com/display/TKB/chkconfig+alternative+for+debian+based+distros
    #chkconfig --add ${instance}yrexpert
    echo
    echo "voir TODO..."
    exit 2
fi

# Lien symbolique pour YDB
su $instance -c "ln -s $basedist/utf8 $basedir/libraries/$yre_db"

# Créer le profile de l'instance
# Necessite les variables YDB
# TODO: Vérifier 'I \$\$JOBEXAM^ZU(\$ZPOSITION)'

echo "[ 07 ] Créer le fichier des variables d'environnement." 
echo "#!/usr/bin/env bash"                                            >> $basedir/etc/env
echo "# Variables d'environnement créer par creerInstanceYRExpert.sh" >> $basedir/etc/env
echo "export gtmgbldir=$basedir/partitions/yxp/globals/YXP.gld"       >> $basedir/etc/env
echo "export gtm_dir=$basedir"                                        >> $basedir/etc/env
echo "export gtm_rel=$gtm_rel"	                                      >> $basedir/etc/env
#TODO: traiter le cas autre que 64bit
# YDB 64bit peut utiliser une bibliothèque partagée
echo "export gtm_dist=$gtm_dist"	            >> $basedir/etc/env
echo "export gtm_arch=$gtm_arch"                >> $basedir/etc/env
echo "export gtmver=$gtmbver"                   >> $basedir/etc/env
echo "export gtm_log=$basedir/log"              >> $basedir/etc/env
echo "export gtm_tmp=$basedir/tmp"              >> $basedir/etc/env
echo "export gtm_prompt=\"YXP>\""     		    >> $basedir/etc/env
echo "export gtm_zinterrupt='I \$\$JOBEXAM^ZU(\$ZPOSITION)'"          >> $basedir/etc/env
echo "export gtm_lvnullsubs=2"                  >> $basedir/etc/env
echo "export PATH=\$PATH:$gtm_dist/utf8"        >> $basedir/etc/env
echo "export gtm_icu_version=`uconv --version | cut -d' ' -f5`"	      >> $basedir/etc/env
echo "export gtm_chset=UTF-8"			        >> $basedir/etc/env
echo ""			                                >> $basedir/etc/env
echo "export instance=$instance"                >> $basedir/etc/env
echo "export basedir=$basedir"                  >> $basedir/etc/env
echo "export basedist=$gtm_dist"	            >> $basedir/etc/env
echo ""			                                >> $basedir/etc/env
echo "export gtmroutines=\"\$basedir/routines/\$gtm_rel(\$basedir/routines) \$basedist/utf8/libgtmutil.so\"" >> $basedir/etc/env

# Mettre les droits corrects pour env
chown $instance:$instance $basedir/etc/env

if [[ -e $basedir/.bashrc ]]; then
    # Envrionment source en shell bash
    echo "Vérifier si - source $basedir/etc/env - existe pas dans .bashrc"
    #grep "source $basedir/etc/env" $basedir/.bashrc
    #if [[ "$?" == 0 ]]; then
    if [[ 1 == 0 ]]; then
        # TODO: grep ne fonctionne pas
        # si la ligne existe dans .bashrc - ne rien faire
        echo "La ligne existe dans .bashrc, ne rien faire."
    else
        # si la ligne n'existe pas
        echo "La ligne n'existe pas dans .bashrc, l'ajouter."
        echo                                          >> $basedir/.bashrc
        echo "# Ajouter par creerInstanceYRExpert.sh" >> $basedir/.bashrc
        echo "source $basedir/etc/env"                >> $basedir/.bashrc
        echo                                          >> $basedir/.bashrc
    fi
fi

echo "[ 08 ] prog.sh - accès des utilisateurs privilégiés (programmeur)." 
# Autoriser l'accès à ZSY
echo "#!/bin/bash"                              >> $basedir/scripts/prog.sh
echo "source $basedir/etc/env"               	>> $basedir/scripts/prog.sh
echo "export SHELL=/bin/bash"               	>> $basedir/scripts/prog.sh
echo "#Cela existent pour des raisons de compatibilité"   >> $basedir/scripts/prog.sh
echo "alias ydb=\"\$gtm_dist/mumps -dir\""      >> $basedir/scripts/prog.sh
echo "alias YDB=\"\$gtm_dist/mumps -dir\""      >> $basedir/scripts/prog.sh
echo "alias gde=\"\$gtm_dist/mumps -run GDE\""  >> $basedir/scripts/prog.sh
echo "alias lke=\"\$gtm_dist/mumps -run LKE\""  >> $basedir/scripts/prog.sh
echo "alias dse=\"\$gtm_dist/mumps -run DSE\""  >> $basedir/scripts/prog.sh
echo "\$gtm_dist/mumps -dir"                    >> $basedir/scripts/prog.sh

# Mettre les droits corrects pour prog.sh
chown $instance:$instance $basedir/scripts/prog.sh
chmod +x $basedir/scripts/prog.sh

echo "[ 09 ] util.sh - accès des utilisateurs non-privilégiés." 
# $instance est leur environnent - pas d'accès à ZSY
# besoin de mettre les utilisateurs $basedir/etc/util.sh dans leur environnement
echo "#!/bin/bash"                              >> $basedir/scripts/util.sh
echo "source $basedir/etc/env"			        >> $basedir/scripts/util.sh
echo "export SHELL=/scripts/false"              >> $basedir/scripts/util.sh
echo "export gtm_nocenable=true"                >> $basedir/scripts/util.sh
echo "exec \$gtm_dist/mumps -run ^VSTART"       >> $basedir/scripts/util.sh

# Mettre les droits corrects pour util.sh
chown $instance:$instance $basedir/scripts/util.sh
chmod +x $basedir/scripts/util.sh

echo "[ 10 ] Créer les globals." 

echo "c -s DEFAULT    -ACCESS_METHOD=BG -BLOCK_SIZE=4096 -ALLOCATION=200000 -EXTENSION_COUNT=1024 -GLOBAL_BUFFER_COUNT=4096 -LOCK_SPACE=400 -FILE=$basedir/globals/YXP.dat" >> $basedir/etc/db.gde
echo "a -s TEMP       -ACCESS_METHOD=MM -BLOCK_SIZE=4096 -ALLOCATION=10000 -EXTENSION_COUNT=1024 -GLOBAL_BUFFER_COUNT=4096 -LOCK_SPACE=400 -FILE=$basedir/globals/temp.dat" >> $basedir/etc/db.gde
echo "c -r DEFAULT    -RECORD_SIZE=16368 -KEY_SIZE=1019 -JOURNAL=(BEFORE_IMAGE,FILE_NAME=\"$basedir/journals/YXP.mjl\") -DYNAMIC_SEGMENT=DEFAULT" >> $basedir/etc/db.gde
echo "a -r TEMP       -RECORD_SIZE=16368 -KEY_SIZE=1019 -NOJOURNAL -DYNAMIC_SEGMENT=TEMP"   >> $basedir/etc/db.gde
echo "a -n TMP        -r=TEMP"                  >> $basedir/etc/db.gde
echo "a -n TEMP       -r=TEMP"                  >> $basedir/etc/db.gde
echo "a -n UTILITY    -r=TEMP"                  >> $basedir/etc/db.gde
echo "a -n XTMP       -r=TEMP"                  >> $basedir/etc/db.gde
echo "a -n CacheTemp* -r=TEMP"                  >> $basedir/etc/db.gde
echo "sh -a"                                    >> $basedir/etc/db.gde

# Mettre les droits corrects pour db.gde
chown $instance:$instance $basedir/etc/db.gde

# Créer db.gde
su $instance -c "source $basedir/etc/env && $basedist/mumps -run GDE < $basedir/etc/db.gde >> $basedir/log/sortieGDE.log 2>&1"

# Créer la base de données
echo "Créer la base de données"
su $instance -c "source $basedir/etc/env && $basedist/mupip create >> $basedir/log/creerDatabase.log 2>&1"
echo "Création de la base de données YDB terminée"

# Ajouter les règles pour le firewall
if [[ $RHEL || -z $debian ]]; then
    iptables -I INPUT 1 -p tcp --dport 8001 -j ACCEPT # Pour une future connexion
    service iptables save
fi

echo "[ 11 ] Mettre les droits"
chown -R $instance:$instance $basedir
chmod -R g+rw $basedir

echo "[ OK ] L'instance de YRExpert $instance est créée..."

