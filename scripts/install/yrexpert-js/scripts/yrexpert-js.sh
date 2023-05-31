#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Script d'installation de yrexpert-js, EWD.js et autres modules nodejs
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

    Ce script permet de créer l'interface web

    Exemple : ./yrexpert-js.sh -i yrexpert
              installer l'interface web yrexpert-js
              -i créer l'interface web depuis l'instance nommée yrexpert

    DEFAULTS:
      Nom de l'instance = valeur obligatoire
      Réinstaller l'instance = false
      Supprimer et réinstaller l'interface web = false
      Mode test tester = false

    OPTIONS:
      -h    Afficher ce message
      -i    Nom de l'instance
      -r    Supprimer et réinstaller l'interface web
      -t    Mode test tester
EOF
}

while getopts "hi:rt" option
do
    case $option in
        h)
            usage
            exit 0
            ;;
        i)
            instance=$(echo $OPTARG |tr '[:upper:]' '[:lower:]')
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
    echo "Le nom de l'instance est obligatoire"
    echo
    usage
    exit 0
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

# $basedir est le répertoire de base de l'instance
# exemples d'installation possibles : /home/$instance, /opt/$instance, /var/db/$instance
basedir=/home/$instance

# Résumer des options
echo "!--------------------------------------------------------------------------!"
echo "                                    yrexpert-js.sh"
echo "i - Installer l'instance nommée   : $instance"
echo "r - Réinstallation                : $reInstall"
echo "t - Mode test                     : $modeTest"
echo "!--------------------------------------------------------------------------!"

set +e # Pas de fermeture lors d'un code retour différent de 0
echo "[ 01 ] Tester s'il est possible d'installer l'interface web yrexpert-js" 
# Exit code 0 Success
# Exit code 1 General errors, Miscellaneous errors, such as "divide by zero" and other impermissible operations
# Exit code 2 Misuse of shell builtins (according to Bash documentation) Example: empty_function() {}
# Tester avec echo $?
if [[ -e /home/$instance/etc/yrexpert-release ]]; then
    echo "L'instance" $instance "est reconnue comme une instance de YRExpert."
    if [[ -d /home/$instance/nodejs ]]; then
        if $reInstall ; then
        	echo "Vous pouvez réinstaller l'interface web yrexpert-js car l'option -r est activée."
            if [[ $modeTest = true ]]; then
                echo
                echo "Vous pouvez installer l'interface web yrexpert-js"
                exit 0
            fi
        else
            echo
        	echo "Vous pouvez réinstaller l'interface web yrexpert-js en ajoutant l'option -r"
            exit 1
        fi
    else
        echo "L'interface" $instance "n'existe pas !"
        if [[ $modeTest = true ]]; then
            echo
            echo "Vous pouvez installer l'interface web"
            exit 0
        fi
    
    fi
else
    if [[ -d /home/$instance ]]; then
        echo
        echo "L'instance" $instance "n'est pas reconnue comme une instance de YRExpert !"
        echo "Vous ne pouvez pas installer l'interface yrexper-web sur cette instance."
        exit 1
    else
        echo "L'instance" $instance "n'existe pas !"
        if [[ $modeTest = true ]]; then
            echo
            echo "Vous devez d'abord installer l'instance $instance !"
            exit 0
        fi
    fi
fi

if [[ "$?" != 0 ]];then
    echo
    echo "La supression de l'instance $instance est impossible !"
    echo "Ajouter l'option -f pour forcer la suppression de l'instance $instance."
    exit 2
fi 

set -e # Fermeture lors d'un code retour différent de 0
echo "[ 02 ] Supprimer l'interface web si elle existe." 
if [[ -d $basedir/nodejs ]]; then
    rm -rf $basedir/nodejs
fi

echo "[ 03 ] Installer node version $nodever" 
# Définir la version de node
nodever="16" #version LST

# Définir la variable arch
arch=$(uname -m | tr -d _)

# Se posionner sur le répertoire père d'ou se trouve le fichier lancé
cd $(readlink -f $(dirname $0))
cd ..

# Copier les scripts init.d dans le répertoite scripts de yrexpert
su $instance -c "cp -R ./etc $basedir"

# Aller à $basedir
cd $basedir

# Installer node.js en utilisant NVM (node version manager) - https://github.com/creationix/nvm
echo "Télécharger et installer NVM"
su $instance -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash"
echo "Installation de NVM terminé"

# Installer node $nodever
su $instance -c "source $basedir/.nvm/nvm.sh && nvm install $nodever > /dev/null 2>&1 && nvm alias default $nodever && nvm use default"

# Dire à $basedir/etc/env notre nodever
# TODO: vérifier si existe
echo                            >> $basedir/etc/env
echo "# Version de node"        >> $basedir/etc/env
echo "export nodever=$nodever"  >> $basedir/etc/env

# Dire à nvm d'utiliser la version de node dans .profile et .bash_profile
if [ -s $basedir/.profile ]; then
    # TODO: vérifier si existe
    echo ""                                 >> $basedir/.profile
    echo "# Installer par yrexpert-js.sh"   >> $basedir/.profile
    echo "source \$HOME/.nvm/nvm.sh"        >> $basedir/.profile
    echo "nvm use $nodever"                 >> $basedir/.profile
    ###source $basedir/.nvm/nvm.sh && nvm use $nodever && echo "export PATH=`npm config get prefix`/bin:\$PATH" >> $basedir/.profile
    echo "export PATH=\`npm config get prefix\`/bin:\$PATH" >> $basedir/.profile
fi

if [ -s $basedir/.bash_profile ]; then
    # TODO: vérifier si existe
    echo ""                             >> $basedir/.bash_profile
    echo "Installer par yrexpert-js.sh" >> $basedir/.bash_profile
    echo "source \$HOME/.nvm/nvm.sh"    >> $basedir/.bash_profile
    echo "nvm use $nodever"             >> $basedir/.bash_profile
    ###source $basedir/.nvm/nvm.sh && nvm use $nodever && echo "export PATH=`npm config get prefix`/bin:\$PATH" >> $basedir/.bash_profile
    echo "export PATH=\`npm config get prefix\`/bin:\$PATH" >> $basedir/.bash_profile
fi

echo "[ 04 ] Créer les répertoires pour node" 
# Créer les répertoires pour node
su $instance -c "source $basedir/etc/env && mkdir $basedir/nodejs"

# Créer un script d'installation silencieux pour yrexpert-js
cat > $basedir/nodejs/yrexpert-jsSilent.js << EOF
{
    "silent": true,
    "extras": true
}
EOF
# Mettre les droits corrects
chown $instance:$instance $basedir/nodejs/yrexpert-jsSilent.js

# Créer un script d'installation silencieux pour yrexpert-term
cat > $basedir/nodejs/yrexpert-termSilent.js << EOF
{
    "silent": true,
    "extras": true
}
EOF
# Mettre les droits corrects
chown $instance:$instance $basedir/nodejs/yrexpert-termSilent.js

#echo "[   ] Mettre les droits"
chown -R $instance:$instance $basedir
chmod -R g+rw $basedir

echo "[ 05 ] Installer les modules de node requis dans $basedir/nodejs" 
# Installer les modules de node requis dans $basedir/nodejs
cd $basedir/nodejs
#echo "0/5 Initialiser le fichier package.json"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm set init.author.name 'yrelay' >> $basedir/log/initNpm.log"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm set init.author.email 'info@yrelay.fr' >> $basedir/log/initNpm.log"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm set init.author.url 'https://www.yrelay.fr' >> $basedir/log/initNpm.log"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm set init.license 'GPL-3.0' >> $basedir/log/initNpm.log"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm init -y >> $basedir/log/initNpm.log"

# Installer en mode global les outils de développement
echo "1/7 browserify" # http://doc.progysm.com/doc/browserify
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet -g browserify >> $basedir/log/installerBrowserify.log"
echo "2/7 uglify-es"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet -g uglify-es >> $basedir/log/installerUglify-es.log"
echo "3/7 marked"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet -g marked >> $basedir/log/installerMarked.log"
echo "4/7 jsdoc"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet -g jsdoc >> $basedir/log/installerJsdoc.log"
echo "5/7 react-devtools (non-installer)"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet -g react-devtools >> $basedir/log/installerReact-devtools.log"

# Installer les modules locaux
echo "6/7 yrexpert-js"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet --save-prod yrexpert-js >> $basedir/log/installerYrexpert-js.log"
# Installer les modules locaux
echo "7/7 babelify@next"
su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && npm install --quiet --save-dev babelify@next >> $basedir/log/installerBabelify@next.log"

# Certaines distributions linux installent nodejs non comme exécutable "node" mais comme "nodejs".
# Dans ce cas, vous devez lier manuellement à "node", car de nombreux paquets sont programmés après le node "binaire". Quelque chose de similaire se produit également avec "python2" non lié à "python".
# Dans ce cas, vous pouvez faire un lien symbolique. Pour les distributions linux qui installent des binaires de package dans /usr/bin, vous pouvez faire
if [ -h /usr/bin/nodejs ]; then
  rm -f /usr/bin/nodejs
fi
ln -s /usr/bin/node /usr/bin/nodejs

echo "[ 06 ] Créer le fichier bundle.js requis par l'application" 
su $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js && rm -rf build && mkdir build"
su - $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js/src/js && browserify -t [ babelify --presets [@babel/preset-env @babel/preset-react] ] App.js | uglifyjs > ../../build/bundle.js"

su $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js && cp -f src/index.html build/index.html"
su $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js && cp -f src/css/json-inspector.css build/json-inspector.css"
su $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js && cp -f src/css/Select.css build/Select.css"
su $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js && cp -rf src/images build/images"
# Mettre les droits
chown -R $instance:$instance $basedir/nodejs/node_modules/yrexpert-js/build
chmod -R g+rw $basedir/nodejs/node_modules/yrexpert-js/build
rm -rf $basedir/nodejs/www/yrexpert
if [ ! -d "$basedir/nodejs/www/yrexpert" ];then
  su $instance -c "mkdir $basedir/nodejs/www/yrexpert && cp -rf $basedir/nodejs/node_modules/yrexpert-js/build/* $basedir/nodejs/www/yrexpert"
  su $instance -c "mkdir $basedir/nodejs/www/yrexpert/docs && cp -rf $basedir/nodejs/node_modules/yrexpert-js/docs/* $basedir/nodejs/www/yrexpert/docs"
  su $instance -c "mkdir $basedir/nodejs/www/yrexpert/help && cp -rf $basedir/nodejs/node_modules/yrexpert-js/help/* $basedir/nodejs/www/yrexpert/help"
  # Mettre les droits
  chown -R $instance:$instance $basedir/nodejs/www/yrexpert
  chmod -R g+rw $basedir/nodejs/www/yrexpert
fi

echo "[ 07 ] Créer les docs de l'application" 
# Créer le répertoire docs utilisé par l'application
su $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js && rm -rf docs && mkdir docs"
su - $instance -c "cd $basedir/nodejs/node_modules/yrexpert-js && jsdoc lib src -r -d docs"
# Mettre les droits
chown -R $instance:$instance $basedir/nodejs/node_modules/yrexpert-js/docs
chmod -R g+rw $basedir/nodejs/node_modules/yrexpert-js/docs

# Copier toutes les routines de yrexpert-js
su $instance -c "find $basedir/nodejs/node_modules/yrexpert-js -name \"*.m\" -type f -exec cp {} $basedir/p/ \;"

echo "[ 08 ] Configurer de GTM C Callin" 
# Configurer de GTM C Callin
# avec nodem 0.3.3 le nom de la ci a changé. Déterminer l'utilisation ls -1
calltab=$(ls -1 $basedir/nodejs/node_modules/nodem/resources/*.ci)
# TODO: vérifier si existe
echo                                                                                    >> $basedir/etc/env
echo "# Configurer de GTM C Callin"                                                     >> $basedir/etc/env
echo "export GTMCI=$calltab"                                                            >> $basedir/etc/env
# Ajouter les routines nodem dans ydb_routines
echo "export gtmroutines=\"\${gtmroutines} \$basedir/nodejs/node_modules/nodem/src\""   >> $basedir/etc/env

echo "[ 09 ] Créer la configuration ewd.js" 
# Créer la configuration ewd.js
cat > $basedir/nodejs/node_modules/yrelay-config.js << EOF
module.exports = {
  setParams: function() {
    return {
      ssl: true
    };
  }
};
EOF

# Mettre les droits corrects
chown $instance:$instance $basedir/nodejs/node_modules/yrelay-config.js

echo "[ 10 ] Installer les droits webservice" 
# Installer les droits webservice
##echo "Installer les droits webservice"
##su $instance -c "source $basedir/.nvm/nvm.sh && source $basedir/etc/env && nvm use $nodever && cd $basedir/nodejs && node registerWSClient.js"

echo "[ 11 ] Modifier les scripts init.d pour les rendre compatibles avec $instance" 
# Modifier les scripts init.d pour les rendre compatibles avec $instance
perl -pi -e 's#y-instance#'$instance'#g' $basedir/etc/init.d/y-instance-yrexpert-js
#perl -pi -e 's#y-basedir#'ydb_dir'#g' $basedir/etc/init.d/y-instance-yrexpert-js

# Créer le démarrage de service
# TODO: Faire fonctionner avec un lien -h
if [ -f /etc/init.d/${instance}-yrexpert-js ]; then
    rm /etc/init.d/${instance}-yrexpert-js
fi
#ln -s $basedir/etc/init.d/y-instance-yrexpert-js /etc/init.d/${instance}-yrexpert-js
cp $basedir/etc/init.d/y-instance-yrexpert-js /etc/init.d/${instance}-yrexpert-js

# Installer le script init
if [[ $debian || -z $RHEL ]]; then
    update-rc.d ${instance}-yrexpert-js defaults 85 15
fi

if [[ $RHEL || -z $debian ]]; then
    #TODO: à modifier
    #chkconfig --add ${instance}yrexpert-js
    echo "voir TODO..."
fi

echo "[ 12 ] Ajouter des règles de pare-feu et démarrer les services" 
# Ajouter des règles de pare-feu
if [[ $RHEL || -z $debian ]]; then
    iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT # EWD.js
    iptables -I INPUT 1 -p tcp --dport 8000 -j ACCEPT # EWD.js Webservices
    iptables -I INPUT 1 -p tcp --dport 8081 -j ACCEPT # EWD yrexpert Term
    iptables -I INPUT 1 -p tcp --dport 8082 -j ACCEPT # Pour test
    iptables -I INPUT 1 -p tcp --dport 3000 -j ACCEPT # Débuggeur node-inspector

    service iptables save
fi

# Démarrer le service
systemctl daemon-reload
service ${instance}-yrexpert-js start

echo "[ 13 ] Mettre les droits"
chown -R $instance:$instance $basedir
chmod -R g+rw $basedir

echo "[ OK ] L'installation de l'interface web yrexpert-js terminée..."


