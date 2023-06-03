[English](../en/README.md) - [Français](../fr/README.md) - [Español](../es/README.md) - [Deutsch](../de/README.md) - [中文](../zh/README.md) - [日本語](../ja/README.md)

[README](./README.md) > [Documentations](./accueil.md) > **Présentation rapide de CMake**

![yrexpert_logo.png](./yrexpert_logo.png)

# Présentation rapide de CMake

CMake a pour but de générer des fichiers de construction adaptés au système hôte : des Makefiles sur un système Unix, XCode pour MacOs, etc de manière portable. Il suffit de lancer `cmake`, puis `make` et `make install` pour obtenir les exécutables et les bibliothèques.

## 1. Utilisation
### 1.1. Lancement de CMake

Depuis la racine de notre projet les objets seront construits dans le répertoire `buil`.

`````shell
$ mkdir build # si besoin
$ cd build
`````

Il faut ensuite lancer cmake depuis le répertoire `buil`.

`````shell
$ cmake ..
`````

### 1.2. Paramètres à fournir à CMake
Les paramètres passés à CMake se font avec l'option -DVARIABLE=valeur. Le fichier `CMakeLists.txt` renseigne plusieurs de ces variables pour configurer le projet, à l'instar de configure. L'activation ou la désactivation des modules facultatifs se fait avec -DMODULE=ON|YES|Y|OFF|NO|N (les valeurs sont incensibles à la casse).

#### 1.2.1. Les différents modules

Les modules facultatifs sont listés ici :

    FFTW
    GRIB
    GSHHS
    HDF5
    HDF
    LIBPROJ4
    MAGICK
    MPICH
    NETCDF
    OPENMP
    PYTHON
    READLINE
    UDUNITS
    WXWIDGETS

Les chemins vers les modules ci-dessus peuvent être spécifiés en ajoutant DIR à la fin du paramètre (ceci ne marche pas pour OpenMP). Exemple : -DMAGICK=ON -DMAGICKDIR=/path/to/magick. On ajoute à cette liste les chemins vers les modules obligatoires :

    GSLDIR
    NCURSESDIR
    PLPLOTDIR
    ZLIBDIR

#### 1.2.2. Les bibliothèques tierces

Les chemins de diverses bibliothèques tierces peuvent être définies. Ceci est utile lorsqu'une bibliothèque compilé par l'utilisateur utilise d'autres bibliothèques qui ne sont pas situées dans un chemin standard.

    JASPERDIR
    JPEGDIR
    SZIPDIR

#### 1.2.3. Divers paramètres supplémentaires

La création d'un module python se fait avec PYTHON_MODULE. Avec l'utilisation de PYTHON_MODULE ou de PYTHON, on peut utiliser le paramètre PYTHONVERSION afin de spécifier la version de python à utiliser en priorité. Si une ancienne version de plplot est utilisée, il faut activer OLDPLPLOT.

### 1.3. Autres cibles générées dans le Makefile

CMake permet aussi de créer simplement une suite de tests.

`````shell
$ make test
`````

L'installation se fait aussi de manière très simple. On peut définir CMAKE_INSTALL_PREFIX à l'appel de CMake afin de définir le répertoire d'installation.

`````shell
$ make install
`````

## 2. Documentation technique

Cette partie aura pour but de présenter la structure et la répartition des fichiers de configuration dans l'arborescence, afin d'avoir une vue globale.

### 2.1. Introduction rapide

Ceci est l'arborescence des différents fichiers requis pour compiler le projet avec cmake.

    yrexpert/ racine du projet
        `CMakeLists.txt`
        config.h.cmake
        src/
            `CMakeLists.txt`
            antlr/
                `CMakeLists.txt`
        tests/
            `CMakeLists.txt`
        CMakeModules
            FindPlplot.cmake
            ...
            FindUdunits.cmake

En utilisant cmake, les templates `Makefile.am` ne sont plus utiles. En effet, cmake est utilisé pour produire des fichiers comme des Makefiles ou des fichiers Eclipse, CodeBlocks, Visual Studio, etc... Contrairement à `configure.ac`, `CMakeLists.txt` n'est pas un script shell modifié pour des raisons de portabilités. Il a donc sa propre syntaxe. Ces fichiers sont parsés par cmake pour produire des Makefiles, ...

Il faut différencier le répertoire source (CMAKE_SOURCE_DIR), le répertoire binaire (CMAKE_BINARY_DIR) et le répertoire d'installation (CMAKE_INSTALL_PREFIX). Le répertoire source est le répertoire racine du projet (yrexpert); le répertoire binaire rassemble les fichiers objets et les cibles construites (il peut être placé n'importe où) et le répertoire d'installation est l'endroit où les fichiers finaux seront installés (par défaut /usr/local sous Unix).

### 2.2. `CMakeLists.txt`

Le but de ce chapitre est de décrire brièvement les fonctionnalités associées aux différents `CMakeLists.txt`. Le prochain chapitre reprendra quelques points qui demandent plus d'attention.

#### 2.2.1. yrexpert/CMakeList.txt

A l'appel de cmake, vous devez specifier le répertoire où est situé le `CMakeLists.txt` principal. En étant dans le répertoire yrexpert :

`````shell
$ mkdir build # si besoin
$ cd build
$ cmake ..
`````

Ce premier fichier :

* Déclare le projet
* Fixe les variables mises en cache avec les valeurs par défaut
* Vérifie si le système est en 64 bits, vérifie les headers et diverses fonctions
* Pour chaque module, s'il est obligatoire ou activé : chercher les headers, les chemins et les bibliothèques requis
* Execute cmake dans le sous-répertoire src
* Execute cmake dans le sous-répertoire tests
* Génère config.h à partir de config.h.cmake et des résultats
* Affiche la configuration

#### 2.2.2. yrexpert/src/`CMakeLists.txt`

Ce fichier est appelé à partir de yrexpert/`CMakeLists.txt`. Quand le parser a atteind la ligne (5.), cmake arrête de traîter le fichier courant et saute à celui-ci. Il :

* Fixe la liste des fichiers source
* Execute cmake dans le sous-répertoire antlr
* Créé une nouvelle cible : yrexpert en tant que bibliothèque si python_module est activé; en tant qu'exécutable dans le cas contraire
* Fixe la destination de yrexpert pour l'installation
* Fixe la destination des fichiers src/pro/* pour l'installation

#### 2.2.3. yrexpert/src/antlr/`CMakeLists.txt`

Il est appelé de yrexpert/src/`CMakeLists.txt` et se contente de :

* Fixer la liste des fichiers source
* Créer une nouvelle cible : antlr en tant que bibliothèque dynamique si python_module est activée; en tant que bibliothèque statique sinon
* Fixer la destination de antlr pour l'installation s'il s'agit d'une bibliothèque dynamique

#### 2.2.4. yrexpert/tests/`CMakeLists.txt`

Ce fichier est appelé depuis yrexpert/`CMakeLists.txt`, juste après que cmake ai traité le sous-répertoire src/. Il permet de :

* Générer un lanceur de test écrit en language C
* Créer une nouvelle cible : launchtest qui sera compilé à partir du code source généré
* Fixer la liste des fichiers de test *.pro
* Déclarer les tests

### 2.3. Les fichiers `CMakeLists.txt` en détail

Certaines fonctionnalités décrites précédemment seront expliquées ici (avec des exemples de code).

#### 2.3.1 Fixer les variables mises en cache avec les valeurs par défaut

Définir des variables mises en cache est réaliser simplement avec la commande "set". Par exemple, le module HDF est requit par défaut. La commande "set(HDF ON CACHE BOOL "Enable HDF ?")" dit à cmake de créer une variable appellée HDF, qui est un booléen initialisé à ON et mise en cache (CMakeCache.txt). Le dernier paramètre est utilisé pour afficher des informations en mode interactif. cmake accepte plusieurs types de valeurs : bool, path, filepath, string, ...

#### 2.3.2. Vérifier si le système est en 64 bits, vérifier les headers et diverses fonctions

Vérifier si un système est en 64 bits est fait aisément avec cmake. Il suffit de lire la variable "CMAKE_SIZEOF_VOID_P" (retourne 8 sur un système 64 bits). Après lecture, cmake cherchera automatiquement en priorité dans les répertoire de bibliothèque 64 bits (lib64).

"check_function_exists" teste si une fonction existe. Les variables "CMAKE_REQUIRED_*" peuvent être fixées afin d'ajouter différents emplacements/bibliothèque/flags pour que le test puisse réussir. En effet, cmake essaie de compiler un petit programme pour vérifier son existance.

"check_include_file" cherche un header.

"check_library_exists" est utilisé pour savoir si une bibliothèque contient une fonction. Par exemple, "check_library_exists(m sin "" HAVE_SIN)" vérifie si la bibliothèque mathématique contient la fonction sin. Le résultat est placé dans HAVE_SIN. Un chemin vers cette bibliothèque peut être placé en troisième argument.

#### 2.3.3. Pour chaque module, s'il est obligatoire ou activé : chercher les headers, les chemins et les bibliothèques requis

Cette partie prend une place importante dans le premier `CMakeLists.txt`. Pour chaque module, le code ressemble à ceci :

    if(MODULE)
        set(CMAKE_PREFIX_PATH ${MODULEDIR})
        find_package(Module)
        if(Module_FOUND)
            check_library_exists(...)
            check_*(...)
            if(NOT libraries...)
                message(FATAL_ERROR "...")
            endif(NOT libraries...)
            set(LIBRARIES ${LIBRARIES} ${Module_LIBRARIES})
            include_directories(${Module_INCLUDE_DIR})
        else(Module_FOUND)
            message(FATAL_ERROR "...")
        endif(Module_FOUND)
    endif(MODULE)

La première ligne vérifie si le module est activé. "MODULE" est une variable mise en cache et qui peut être écrasée en passant des arguments à cmake avec l'option -D. Si "MODULE" est obligatoire, les lignes 1 et 15 ne sont pas présentes.

La deuxième ligne est utilisée pour signaler à cmake que les bibliothèques et les headers, etc... peuvent être trouvés dans "MODULEDIR". Par exemple, si cmake est invoqué avec -DGRIB=ON -DGRIBDIR=/chemin/vers/grib alors CMAKE_PREFIX_PATH sera égal à '/chemin/vers/grib'.

La troisième ligne permet de chercher le 'package'. En fait, cmake va appeler le script FindModule.cmake pour cacher la recherche (qui peut être complexe) dans un autre fichier. Cmake est installé avec des Find*.cmake. Il peuvent être 'écrasés' par l'utilisateur. Le prochain chapitre expliquera les principes de ces fichiers. Ce script va fixer un booléen "Module_FOUND". Si le module n'est pas trouvé (12), cmake s'arrêtera avec un message d'erreur (13). Dans le cas contraire, des vérifications supplémentaires peuvent être faites (5-6) et interprétées (7-9). Si tout est bon, cmake atteindra la ligne 10. Les bibliothèque nécessaires au module seront ajoutées à la liste "LIBRARIES" (option -l de gcc). La ligne 11 ajoute "Module_INCLUDE_DIR" aux répertoires inclus (option -I de gcc).

#### 2.3.4. Execute cmake dans les sous-répertoires src/, src/antlr/, tests/

Ceci est fait en appelant "add_subdirectory". cmake arrête le traitement du fichier courant et va au `CMakeLists.txt` dans le répertoire fournit en paramètre. Pour se projet, la séquence d'appel est yrexpert > src > antlr > src > yrexpert > tests > yrexpert.

#### 2.3.5. Génèrer config.h à partir de config.h.cmake et des résultats

Un simple appel à "configure_file(config.h.cmake config.h) permet de générer le header. Ceci sera détailler dans le dernier chapitre.

#### 2.3.6. Créer une nouvelle cible : yrexpert/antlr en tant que bibliothèque/bibliothèque dynamique si python_module est activé; en tant qu'exécutable/bibliothèque statique dans le cas contraire

Une nouvelle cible est crée en appelant "add_library" ou "add_executable" avec le nom de la cible suivit des sources. Par exemple, antlr est compilé en tant que bibliothèque dynamique si python_module est activé : "add_library(antlr SHARED ${ANTLRSOURCES})". Le mot-clef STATIC peut être utilisé pour créer des bibliothèques statiques. Pour être sur que antlr est construit avant yrexpert, on appelle "add_dependencies(yrexpert antlr)". Ensuite, il faut spécifier les bibliothèques (dynamiques ou statiques) liées à une cible : "target_link_libraries(yrexpert ${LIBRARIES})". Une cible peut aussi être utilisée à la place de "LIBRARIES" : "target_link_libraries(yrexpert antlr)" permet de lier antlr à yrexpert.

#### 2.3.7. Fixer la destination de yrexpert pour l'installation, fixer la destination des fichiers src/pro/* pour l'installation

L'installation est fait dans "CMAKE_INSTALL_PREFIX". Tout est gérer avec une unique fonction : "install". On doit spécifier ce qui doit être installer, par exemple, "TARGETS" ou "DIRECTORY" et où, avec le mot-clef "DESTINATION". Par exemple, pour installer yrexpert, on peut écrire "install(TARGETS yrexpert DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)". Cette fonction peut gérer des cas complexes comme installer un répertoire en omettant des fichiers correspondant à un pattern spécifique. Cette technique est employé pour le sous-répertoire src/pro.

#### 2.3.8. Générer un lanceur de test écrit en language C

Le programme généré sera utilisé pour lancer les tests. Il se contente de vérifier les paramètres, de fixer les variables d'environnement yrexpert_PATH et LC_COLLATE et appeler yrexpert.

#### 2.3.9. Déclarer les tests

Après avoir définit une liste de tests, ils doivent tous être déclarés avec "add_test". Puisque launchtest peuvent appeler yrexpert avec un fichier *.pro à tester, on peut définir un test avec launchtest en tant que programme et le fichier *.pro en tant que paramètre. Avant tout, on a besoin de connaître le chemin de launchtest : "get_target_property(LAUNCHTESTLOCATION launchtest LOCATION)". Cette fonction permet de récupérer plein d'information sur les différentes cibles. Ensuite, pour chaque fichier de la liste, on appelle "add_test(${TEST} ${LAUNCHTESTLOCATION} ${TEST})". Le premier argument est le nom du test, suivit par l'executable et ses arguments.

### 2.4. Find*.cmake

Ce chapitre expose simplement les choses minimales requises dans un fichier Find*.cmake, puisqu'ils peuvent être longs et complexes. Quand "find_package" est appelé, cmake cherche le fichier qui correspond avec le paramètre fournit. Par exemple, "find_package(Pack)" correspond au fichier FindPack.cmake. cmake fournit à son installation des bons fichiers Find*.cmake. Mais l'utilisateur peut en écrire et écraser les existants. Le but de ces fichiers et de trouver les bibliothèques et les répertoires associé à ce 'package'. Par conséquent, le plus simple des fichiers ressemble à ceci :

    find_library(Pack_LIBRARIES NAMES libtofind alternativename)
    find_path(Pack_INCLUDE_DIR NAMES pack.h pack/pack.h)
    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(Pack DEFAULT_MSG Pack_LIBRARIES Pack_INCLUDE_DIR)
    mark_as_advanced(Pack_LIBRARIES Pack_INCLUDE_DIR)

La première ligne cherche une bibliothèque qui peut se nommer "libtofind" ou "alternativename". Rappelez vous que "CMAKE_PREFIX_PATH" peut être remplie pour permettre de rechercher dans cette arborescence en premier (et ensuite dans les chemins usuels). Si c'est trouvé, Pack_LIBRARIES contient le chemin de la bibliothèque; dans le cas contraire, cmake interprètera la valeur comme fausse (*-NOTFOUND).

La même chose est faite à la deuxième ligne, mais cette fois-ci, c'est un header qui est recherché. Puisqu'il faut juste un nom de répertoire (l'option -I de gcc), on utilise "find_path".

"*_LIBRARIES" et "*_INCLUDE_DIR" sont des nommages standards pour "find_package".

Ensuite, les résultats sont vérifiés au moyen de la fonction "find_package_handle_standard_args". Le premier paramètre est le nom du résultat (il vaut mieux utiliser le même nom en préfix pour LIBRARIES et INCLUDE_DIR). "DEFAULT_MSG" est utilisé comme template d'affichage en cas d'erreur et il peut être personnalisé. Ensuite, on ajoute la liste des variables. La fonction fixe la variable "*_FOUND" (par exemple Pack_FOUND) à vrai si chacunes des variables (celles après DEFAULT_MSG) sont vraies; à faux sinon, accompagné d'un message d'erreur.

La dernière ligne est utilisée pour cacher les variables quand cmake est lancé en mode interactif (cmake -i, make edit_cache) ou quand une interface graphique est utilisée. L'utilisateur devra donc être en mode avancé pour voir ces variables.

### 2.5. config.h.cmake

De la même façon que config.h.in, config.h.cmake est un fichier template qui sera utilisé par cmake pour produire config.h. La syntaxe est simple; il suffit d'utiliser @VAR@ pour substituer une variable cmake et #cmakedefine VAR pour produire le bon #define. Par exemple :

    set(FOO foo)
    set(MODULE ON)
    set(NOMODULE Module-NOTFOUND)


et le fichier config.h.cmake suivant :

    #define FOO "@FOO@"
    #cmakedefine MODULE
    #cmakedefine NOMODULE


produira ce fichier :

    #define FOO "foo"
    #define MODULE
    /* #undef NOMODULE */


