# Projet SUPINFO : Voting app

## Branches
### `twilight-zone` :
- Branche de test, plus avancée mais potentiellement plus instable
- Sauf nécessité absolue, préférer la branche `master` pour les environnements de production
### `master` :
- Branche stable / principale
- Fonctionnalités testées dans la branche `twilight-zone` avant intégration
- À préférer pour le déploiement en production

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
    - 1. Adaptation du `docker-compose.yml`
    - 2. Ajout de conditions de redémarrage des processus workers
    - 3. Ajout de conditions de déduplication des processus tels que l'endpoint de vote
    - 4. Ajout de contraintes de création, afin de s'assurer que les services sont déployés sur les bon noeuds

## Comment l'utiliser ?
### Dockerfiles 
Il est possible de compiler localement les conteneurs à partir des dockerfiles ; deux options s'offrent à vous. La première, plus simple, se fait au travers du script `build.sh`. Il suffit de le lancer depuis la racine du dépôt pour que les conteneurs soient créés en suivant les DOCKERFILEs (note : il faut que `docker` soit installé, et que vous ayez récupéré l'entièreté des fichiers, les DOCKERFILEs ayant besoin du code source des applications)

La seconde, plus manuelle, consiste à compiler un par un les conteneurs. Celle-ci vous permet plus de granularité dans le choix des noms voire les modifications apportées au code, mais risque d'être incompatible avec les solutions qui vont suivre.

### Docker compose
Le fichier `docker-compose.yml` part du principe que vous avez construit les conteneurs `vote`, `worker` et `results`. Vous pouvez ensuite lancer le stack entier avec le script `run.sh -c/--compose` (et `run.sh -k/--killall` pour tout arrêter), ou bien avec la commande `docker compose up` (et l'arrêter avec `docker compose down`).
Il faut noter que les variables d'environnement, telles que le choix des options, se fait soit en modifiant les DOCKERFILES des conteneurs conservés, ou dans le cas des choix de vote, au travers du script `run.sh` quand on lance les conteneurs. 

### Docker swarm 
> [!INFO]
De par la différence de fonctionnement de Docker Swarm, il faudra au préalable construire les conteneurs avant de les publier sur un registre externe<sup>1</sup>. 

#### 1.Construction
Pour ce faire, il faut lancer le script `build.sh` au préalable, et publier les conteneurs comme suit :
```bash 
build.sh -l # L'argument -l permet de lister les conteneurs ayant étés construits'
```

#### 2. Publication
```bash 
#N.B. On imagine que `camille` est le compte utilisateur.ice sur le registre distant
docker push camille/voting-dashboard:1.0.0
docker push camille/voting-worker:1.0.0
docker push camille/votebox:1.0.0
```
L'utilisation de Redis et de PostgreSQL, dans le cadre de ce projet, ne nécessite pas un build particulier, donc nous pouvons nous permettre de les omettre dans l'étape précédente.

#### 3. Ajout de workers
Il faut ensuite ajouter des noeuds dans le cluster ; On peut faire cela en lançant la commande suivante sur les machines (virtuelles ou physiques) :
```
docker swarm init
```

#### 4. Lancement du stack
La dernière étape est de lancer le stack tout entier ; avec le fichier `docker-compose-swarm.yml` dans le répertoire actif :
```bash
docker stack deploy -c docker-compose-swarm.yml voting-app
# Puis, pour vérifier que tout est lancé :
docker stack services voting-app
docker service logs voting-app_votebox
```

#### 5. Arrêt du stack 
Après que l'application ait été utilisée, on peut l'arrêter avec la commande `docker stack rm voting-app`

#### 6. Nettoyage
> [!INFO] Cette étape est également applicable aux autres façons de faire ; toutes les procédures utilisent des volumes docker pour la persistence des résultats.

Pour effacer les données du vote, vous pouvez supprimer les volumes attachés avec la commande suivante, qui va filtrer les conteneurs avec "voting" dans leur nom (les conteneurs étant nommés au moment de leur construction), puis va les supprimer ainsi que les volumes leur étant attachés
```bash
docker rm -fv $(docker ps -a --filter "name=voting" --format "{{.ID}}")
```
Vous pouvez également supprimer tous les réseaux que vous avez sur votre machine (cette commande ignore les réseaux docker natifs tels que `bridge`)
```bash
docker network ls | tail -n $(($(docker network ls | wc -l)-1)) | awk '{print $1}' | xargs docker network rm
```
