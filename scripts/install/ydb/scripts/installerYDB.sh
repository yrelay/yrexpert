#!/usr/bin/env bash
#!----------------------------------------------------------------------------!
#!                                                                            !
#! YRExpert : (Your Yrelay) Système Expert                                    !
#! Copyright (C) 2001-2023 par Hamid LOUAKED                                  !
#!                                                                            !
#!----------------------------------------------------------------------------!
#
# Installer YottaDB
# Cet utilitaire nécessite privliges root
#
# 22 mars 2023
#


# S'assurer que nous sommes en root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root" 1>&2
    exit 1
fi

# Rechercher YDB:
# Utiliser le chemin /usr/local/lib/yottadb
# nous pouvons lister les répertoires si > 1 erreur de répertoire
# Par défaut YDB est installé sur /usr/local/lib/yottadb/{ydb_ver}

# Rechercher si une version est installéé
if [ -d /usr/local/lib/yottadb ]; then
    dirs=$(find /usr/local/lib/yottadb -maxdepth 1 -type d -printf '%P\n')
    echo
    echo "La version YDB" $dirs "est déjà installée"
    echo "Pour reinstaller, désinstaller d'abord avec ./deinstallerYDB.sh"
    exit 2
fi

# Une seule version YDB trouvée --> On peut installer YDB
sudo apt-get update
sudo apt-get install build-essential

mkdir /tmp/ydb ; wget -P /tmp/ydb https://gitlab.com/YottaDB/DB/YDB/raw/master/sr_unix/ydbinstall.sh
cd /tmp/ydb ; chmod +x ydbinstall.sh
sudo -E ./ydbinstall.sh --overwrite-existing --utf8 default --verbose

# Rechercher la version YDB installée
ydbver=$(ls -1 /usr/local/lib/yottadb | tail -1)
ydb_dist=/usr/local/lib/yottadb/$ydbver

# Mettre à jour l'environnement
source $ydb_dist/ydb_env_set
rm -rf /tmp/ydb
cd ~

echo "[OK] La base de données YDB est installée..."

