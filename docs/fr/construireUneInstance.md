**Français** - [English](../en/README.md) - [中文](../zh/README.md) - [Espagnol](../sp/README.md) - [日本ais](../ja/README.md)

[README](./README.md) > [Documentations](./accueil.md) > **Construire une instance YRExpert**

![yrexpert_logo.png](./yrexpert_logo.png)

# Construire d'une Instance YRExpert

La Construire d'une instance YRExpert peut être effectuée via deux méthodes distinctes :

1. Une installation locale sur un système d'exploitation Linux, spécifiquement de la distribution Debian.
2. Une mise en place sur une machine virtuelle (VM) VirtualBox, en employant l'outil de gestion d'environnement Vagrant.

Pour établir votre instance YRExpert, veuillez suivre les étapes ci-après.

## 1. Depuis un système Linux type Debian

### 1.1. Installer YRExpert en local

Si vous êtes sur un système Linux type Debian, et que vous souhaitez installer **YRExpert** en local, vous pouvez taper :

* Mettre à jour votre système :

````shell
$ sudo apt-get update && sudo apt-get upgrade -y
$ sudo apt-get install git # si non installé
````

* Installer YRExpert par défaut :

````shell
$ rm -rf ~/tmp/yrexpert # si besoin
$ git clone https://github.com/yrelay/yrexpert.git ~/tmp/yrexpert
$ sudo ~/tmp/yrexpert/scripts/install/debian/installerAuto.sh -er -i yrexpert -m ydb
$ rm -rf ~/tmp/yrexpert
````
L'instance est installer sur `/home/yrexpert`

Pour utiliser **YRExpert**, voir : [faire ses premiers pas sur YRExpert](./faireSesPremiersPas.md).

### 1.2. Supprimer l'instance YRExpert

ATTENTION : Toutes les données seront perdues !!!

````shell
$ sudo ~/yrelay/yrexpert/scripts/install/scripts/supprimerInstanceYRExpert.sh -f -s -i yrexpert
````
Si vous n'avez pas créer de box YRExpert, pour finir vous pouvez supprimer sans risque l'arboressance ~/yrelay/yrexpert.

## 2. Dans une machine virtuelle (VM) VirtualBox en optant pour Vagrant

## 2.1. Qu'est-ce que Vagrant

[Vagrant](http://www.vagrantup.com) est une application libre qui permet la mise en place d'environnements de développement faciles. Il est constitué essentiellement d'une machine virtuelle automatisée (VM) qui peut dialoguer avec de nombreuses solutions (VirtualBox, Rackspace, AWS, etc.) pour créer une VM de base et y déployer une application comme yrexpert.

Pour connaitre l'histoire de Vagrant suivre de ce [lien](http://www.vagrantup.com/about.html).

## 2.2. Tutoriel vidéo

Il y a un didacticiel vidéo qui illustre cette procédure dans un environnement Linux sur [YouTube](https://www.youtube.com/watch?v=YpkPAb7q10k). Ceci est hautement recommandé pour les nouveaux utilisateurs à Vagrant.

## 2.3. Pourquoi Vagrant ?

Vagrant remplit les conditions suivantes :
* Open Source
* Compatible avec de multiples fournisseurs VM, y compris les fournisseurs de cloud
* Ecriture facile de scripts d'automatisation
* Utilisation facile pour les utilisateurs finaux

## 2.4. Comment puis-je utiliser Vagrant ?

Vous devez d'abord télécharger et installer quelques utilitaires :

### 2.4.1. Vagrant

Si vous êtes sur un système Linux type Debian, vous pouvez taper :

````shell
$ sudo apt-get update && sudo apt-get upgrade -y
$ sudo apt-get install vagrant
````

Sinon, Vagrant peut être téléchargé à partir http://downloads.vagrantup.com/. Vous devez télécharger la version correcte de Vagrant en fonction de votre système d'exploitation.

Yrelay a testé Vagrant 2.1.7, mais il n'y a aucune raison que les nouvelles versions ne fonctionnent pas.

### 2.4.2. VirtualBox

VirtualBox est un logiciel de virtualisation open source qui fonctionne avec Vagrant. Si vous êtes sur un système Linux type Debian, vous pouvez taper :

````shell
$ sudo apt-get install virtualbox
````

Si Virtualbox n'est pas dans les dépôts de votre sources.list : voir les instructions sur https://wiki.debian.org/VirtualBox

Sinon, VirtualBox peut être téléchargé à partir https://www.virtualbox.org/wiki/Downloads. L'installation est simple et vous pouvez prendre les valeurs par défaut durant le processus d'installation.

Veiller à la compatibilité entre Vagrant et VirtualBox : https://www.vagrantup.com/docs/virtualbox/

### 2.4.3. Git

Pour télécharger le référentiel Git **https://github.com/yrelay/yrexpert** vous avez besoin de Git. Ce logiciel est un système de contrôle de version source distribué et ouvert qui est incroyablement pratique et populaire pour la gestion du code source de projets. Si vous êtes sur un système Linux type Debian, vous pouvez taper :

````shell
$ sudo apt-get install git
````

Sinon, Git est disponible à l'adresse http://www.git-scm.com. L'installation est simple et vous pouvez prendre les valeurs par défaut durant le processus d'installation.

## 2.5. Cloner le dépôt yrexpert

Le référentiel **yrexpert** contient tous les fichiers spécifiques du projet pour dire à Vagrant quoi faire et comment le faire. Nous allons commencer par l'ouverture d'une invite **git-bash** (sous Windows) ou un **shell bash** (sous Linux).

Remarque : Les guides supposent que vous allez utiliser un **git-bash** ou un **shell bash** pour toutes les futures interactions avec Vagrant. Vous pouvez cloner le dépôt **yrexpert** n'impote où, mais pour plus de simplicité, nous allons cloner dans un nouveau répertoire **yrelay** :

````shell
$ cd ~
$ mkdir yrelay
$ cd yrelay
$ git clone https://github.com/yrelay/yrexpert.git
````

Cela ne devrait prendre que quelques minutes être téléchargé.

## 2.6. Installer un plugin additionnel pour Vagrant VirtualBox 

Avec les dernières versions de VirtualBox et Vagrant le montage des dossiers partagés peut échouer. En ajoutant un plugin additionnel pour Vagrant, VirtualBox sera automatiquement installé quand une VM est montée.

Pour installer le plugin procéder comme suit :

````shell
$ cd ~
$ vagrant plugin install vagrant-vbguest
````

Vous pouvez voir une erreur durant l'install **"Could not find the X.Org or XFree86 Window System, skipping."**. Cette erreur ne posera pas de problèmes. Cela vient du fait que la VM créée ne contient pas d'interface graphique.

## 2.7. Démarrer le process

Maintenant, puisque nous avons un clone du référentiel **yrexpert**, nous devons créer une nouvelle machine virtuelle utilisant Vagrant. Ce processus est automatisé et devrait prendre entre 15 minutes à 1 heure 30 minutes en fonction de ligne internet et des mises à jour nécessaires.

Remarque : Si vous ne souhaitez pas installer les répertoires de développement par défaut (nécessaire pour la ré-exécuter des tests), vous devez modifier manuellement le **Vagrantfile** situé dans **~/yrelay/yrexpert/debian** et enlever le **-e** sur la ligne 155. Il devrait ressembler à : **s.args = "-i " + "#{ENV['instance']}" -m ydb**

Les scripts pour la VM sont situés dans **~/yrelay/yrexpert/** et le fichier **Vagrantfile** est située dans **~/yrelay/yrexpert/debian**.

````shell
$ cd ~/yrelay/yrexpert/scripts/install/debian
$ vagrant up --provider=virtualbox
````

Si votre interface n'est pas reconnue, Vagrant vous proposera de la choisir :

	==> YRExpert box Debian: Available bridged network interfaces:
	1) wlp3s0
	2) docker0
	3) enp4s0


Le processus est très verbeux avec du texte vert et rouge. Pour les utilisateurs avancés, le texte vert serait du texte standard et le rouge correspond à des informations complémentaires. Un texte rouge ne signifie pas qu'il y a une erreur. Vagrant affichera un message d'erreur s'il y a vraiment une erreur. Si vous rencontrez des difficultés, vous pouvez envoyer un message au projet yrexpert de YRelay https://www.yrelay.fr. Dans ce cas, une sortie écran peut aider à comprendre le problème.

Sur mon système, j’initialise les variables LANG et **LC_MESSAGES** à, respectivement, **fr_FR.utf8** et **en_US.utf8**. Ainsi, les différents programmes appliquent les paramètres régionaux français à l’exception des messages qui sont affichés en anglais. Cela implique de bien inclure ces deux « locales » dans le fichier /etc/locale.gen. Toutefois, celles-ci peuvent être indisponibles sur certains systèmes distants. La plupart des applications se rabattent sur la locale C sans broncher. Une exception notable est Perl qui se plaint très bruyamment. La documentation de Perl explique comment se débarasser de ce message.

	export PERL_BADLANG=0

Remarque : Vous pouvez recontrez des problèmes avec la création des définitions des paramètres régionaux et le positionnement de LANG. Pour corriger le problème, suivre les deux étapes en lancant la commande suivante :

````shell
$ sudo dpkg-reconfigure locales
````

Cochez au moins le paramètre correspondant à votre langue (fr) et votre pays (FR, BE, LU, etc), avec ou sans l'euro. Par exemple : fr_FR.UTF-8

Sur certaine machine vous devrez activer le support vt-x/amd-v dans le BIOS, sans lequel vous ne pourrez pas utiliser la virtualisation.

![erreur_vt-x.png](./erreur_vt-x.png)

## 2.8. Détails techniques

L'essentiel se trouve dans deux fichiers :

* [Vagrantfile](https://github.com/yrelay/yrexpert/tree/master/debian/Vagrantfile)
* [installerAuto.sh](https://github.com/yrelay/yrexpert/tree/master/debian/installerAuto.sh)

Le fichier Vagrantfile est ce qui indique à Vagrant quoi faire. Ce fichier contient la configuration pour la machine virtuelle de base qui sera créée, mais aussi où l'obtenir par exemple **debian/bullseye64**. Le Vagrantfile contient également des informations sur l'outil de gestion (shell, chef, puppet, etc.) à utiliser, dans quel ordre, et où les fichiers sont. Actuellement, seul l'outil shell est utilisé.

Pour plus d'informations sur Vagrantfiles lire la documentation Vagrant situé à **http://docs.vagrantup.com/v2/vagrantfile/index.html**.

## 2.9. Supprimer la box YRExpert

ATTENTION : Toutes les données seront perdues !!!

Si vous êtes sur un système Linux type Debian, et que vous souhaitez supprimer la box YRExpert, vous pouvez taper :

````shell
$ cd ~/yrelay/yrexpert/scripts/install/debian
$ vagrant destroy
````

Pour finir vous pouvez supprimer sans risque l'arboressance ~/yrelay/yrexpert.