# Projet SUPINFO : Voting app

## De quoi s'agit-il ?
Ce dépôt de code contient les rendus du projet sur Docker, dans le cadre de mes études à SUPINFO. 
Cela consiste en trois parties : 
- 1. DOCKERFILEs pour chacune des cinq parties de l'application ;
    - 1. Base de données Redis 
    - 2. Application web de vote Python 3.11
    - 3. Base de données PostgreSQL 
    - 4. Application Dotnet de traitement
    - 5. Application NodeJS

- 2. Docker compose pour unifier la gestion de l'application
    - 1. Automatisation du déploiement, de l'ouverture des ports ainsi que de la configuration des variables d'environnement
    - 2. Healthchecks cherchant à assurer la disponibilité des services
    - 3. Segmentation en deux réseaux :
        - vote-network : regroupe les machines accessibles par les utilisateur.ices 
        - processing-network : regroupe les machines traitant les résultats de vote

- 3. Configuration Docker Swarm pour s'assurer que l'application reste disponible aux utilisateur.ices

## Comment l'utiliser ?
### Dockerfiles 
Il est possible de compiler localement les conteneurs à partir des dockerfiles ; deux options s'offrent à vous. La première, plus simple, se fait au travers du script `build.sh`. Il suffit de le lancer depuis la racine du dépôt pour que les conteneurs soient créés en suivant les DOCKERFILEs (note : il faut que `docker` soit installé, et que vous ayez récupéré l'entièreté des fichiers, les DOCKERFILEs ayant besoin du code source des applications)

La seconde, plus manuelle, consiste à compiler un par un les conteneurs. Celle-ci vous permet plus de granularité dans le choix des noms voire les modifications apportées au code, mais rique d'être incompatible avec les solutions qui vont suivre.

### Docker compose
Le fichier `docker-compose.yml` part du principe que vous avez construit les conteneurs Votebox, Dotnet et Dashboard. Vous pouvez ensuite lancer le stack entier avec le script `run.sh -c/--compose` (et `run.sh -k/--killall` pour tout arrêter), ou bien avec la commande `docker compose up` (et l'arrêter avec `docker compose down`).
Il faut noter que les variables d'environnement, telles que le choix des options, se fait soit en modifiant les DOCKERFILES des conteneurs conservés, ou dans le cas des choix de vote, au travers du script `run.sh` quand on lance les conteneurs. 

### Docker swarm 
> [!WIP]
