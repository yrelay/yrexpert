[English](../en/README.md) - [Français](../fr/README.md) - [Español](../es/README.md) - [Deutsch](../de/README.md) - [中文](../zh/README.md) - [日本語](../ja/README.md)

[README](./README.md) > [Documentations](./accueil.md) > **Futures améliorations**

![yrexpert_logo.png](./yrexpert_logo.png)

# Futures améliorations

Ce document recense les évolutions potentielles envisagées pour le système YRExpert. Veuillez noter que ces suggestions n'ont pas encore fait l'objet d'une évaluation formelle. Par conséquent, leur inclusion dans cette liste ne garantit pas nécessairement leur implémentation future.

## À court terme

**yrexpert-m :**
- Implémentation des dernières corrections identifiées pour YRExpert en mode terminal.

**yrexpert-js :**
- Application des dernières corrections identifiées pour YRExpert en mode web.

## À moyen terme

Amélioration de l'interface utilisateur.

## À long terme

Dans le but de faciliter la maintenance et les évolutions de la partition système, il est envisagé de la décomposer en modules distincts, appelés `yrexpert-m`, comprenant :
* yrexpert-sys-dkbms : base de données et de connaissances.
* yrexpert-sys-gdx : gestion documentaire.
* yrexpert-sys-hevea : évaluateur interactif.
* yrexpert-sys-totem : moteur d’inférence.
* yrexpert-sys-link : configurateur.
* yrexpert-sys-mozart : éditeur de gamme.
* yrexpert-sys-eqx : aide à l’équilibrage de ligne.

Parallèlement, il est prévu de développer des partitions utilisateur, telles que :
* yrexpert-usr-aiya : poche de connaissances spécialisée dans le trading de crypto-monnaies.

---

Copyright (C) 2001-2023 Hamid LOUAKED.

Ce programme est un logiciel libre : vous pouvez le redistribuer et/ou le modifier sous les termes de la licence publique générale GNU telle que publiée par la Free Software Foundation, soit la version 3 de la Licence, soit (à votre choix) toute version ultérieure.

Ce programme est distribué dans l'espoir qu'il sera utile, mais SANS AUCUNE GARANTIE ; sans même la garantie implicite de QUALITÉ MARCHANDE ou ADAPTATION À UN USAGE PARTICULIER. Voir le Licence publique générale GNU pour plus de détails.

Vous devriez avoir reçu une copie de la licence publique générale GNU avec ce programme. Sinon, consultez <https://www.gnu.org/licenses/>.
