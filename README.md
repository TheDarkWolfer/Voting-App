# Projet SUPINFO : Voting app

## De quoi s'agit-il ?
Ce dépôt de code contient les rendus du projet sur Docker, dans le cadre de mes études à SUPINFO. 
Cela consiste en trois parties : 
- 1. DOCKERFILEs pour chacune des cinq parties de l'application ;
    1. Base de données Redis 
    2. Application web de vote Python 3.11
    3. Base de données PostgreSQL 
    4. Application Dotnet de traitement
    5. Application NodeJS

- 2. Docker compose pour unifier la gestion de l'application

- 3. Configuration Docker Swarm pour s'assurer que l'application reste disponible aux utilisateur.ices

## Comment l'utiliser ?
### Dockerfiles 
Il est possible de compiler localement les conteneurs à partir des dockerfiles ; deux options s'offrent à vous. La première, plus simple, se fait au travers du script `build.sh`. Il suffit de le lancer depuis la racine du dépôt pour que les conteneurs soient créés en suivant les DOCKERFILEs (note : il faut que `docker` soit installé, et que vous ayez récupéré l'entièreté des fichiers, les DOCKERFILEs ayant besoin du code source des applications)
La seconde, plus manuelle, consiste à compiler un par un les conteneurs. Celle-ci vous permet plus de granularité dans le choix des noms voire les modifications apportées au code, mais rique d'être incompatible avec les solutions qui vont suivre.
