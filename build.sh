#!/usr/bin/env bash

echo -e "Build script for Camille's PRADO Docker project"

case "$1" in
	-h|--help)
		echo -e "Script permettant de construire les conteneurs Dockers du projet de Camille PRADO"
		echo -e "Arguments : "
		echo -e "-e|--edit\t: Modifier les variables d'environnement des DOCKERFILEs"
		echo -e "-o|--options\t: Modifier les options de vote (plus simple que de modifier les dockerfiles dans leur entièreté)"
		echo -e "-h|--help\: Affiche ce message"
		;;
	-e|--edit)
		echo "NYI"
		;;
	*)
	echo -e "Début du build des conteneurs..."

# Un jour j'aurais le courage de réparer la tabulation (¬_¬")

# Pour compter le nombre de conteneurs qui sont construits avec succès, pour faciliter la lecture des logs 
COUNTER=0
AMOUNT_OF_BUILDS=$(($(grep -c if $0)-5))

# On source les différents .ENVs du projet 
export $(grep -v '^#' .env-votebox | xargs)
export $(grep -v '^#' .env-redis | xargs)
export $(grep -v '^#' .env-postgresql | xargs)

echo -e "Building the Redis container..."
if docker build --tag voting-redis:1.0.0 -f=DOCKERFILE-Redis . ;
	then
		((COUNTER++))
		echo -e "╭─────────────────────────────────────╮\n│ Done building the Redis container ! │\n╰─────────────────────────────────────╯"
	else 
		echo -e "╭────────────────────────────────────╮\n│ Error building the Redis container │\n╰────────────────────────────────────╯"
fi

# On laisse l'option de paramétrer certaines valeusr'
echo -e "Building the voting container..."
if docker build --tag voting-python:1.0.0  \
	--build-arg REDIS_HOST="$REDIS_HOST" \
	--build-arg REDIS_PORT="$REDIS_PORT" \
	--build-arg REDIS_DB="$REDIS_DB" \
	--build-arg REDIS_TIMEOUT="$REDIS_TIMEOUT" \
	-f=DOCKERFILE-Votebox . ; 
	then 
		((COUNTER++))
		echo -e "╭──────────────────────────────────────╮\n│ Done building the voting container ! │\n╰──────────────────────────────────────╯" 
	else 
		echo -e "╭─────────────────────────────────────╮\│ Error building the voting container │\n╰─────────────────────────────────────╯"
fi

echo -e "Building the postgresql container..."
if docker build --tag voting-postgresql:1.0.0 -f=DOCKERFILE-Postgresql . ; 
	then 
		((COUNTER++))
		echo -e "╭──────────────────────────────────────────╮\n│ Done building the postgresql container ! │\n╰──────────────────────────────────────────╯" 
	else 
		echo -e "╭─────────────────────────────────────────╮\n│ Error building the postgresql container │\n╰─────────────────────────────────────────╯"
fi

echo -e "Building the worker program..."
if dotnet publish -c release --self-contained false --no-restore ./worker/ ;
	then 
		((COUNTER++))
		echo -e "╭───────────────────────╮\n│ Worker binary built ! │\n╰───────────────────────╯" 
	else 
		echo -e "╭──────────────────────────────╮\n│ Error building worker binary │\n╰──────────────────────────────╯"
fi

echo -e "Building the dotnet container..."
if docker build --tag voting-worker:1.0.0 \
	--build-arg PG_HOST="$PG_HOST" \
	--build-arg PG_PORT="$PG_PORT" \
	--build-arg PG_USER="$PG_USER" \
	--build-arg PG_PASSWORD="$PG_PASSWORD" \
	--build-arg PG_DB="$PG_DB" \
	--build-arg REDIS_HOST="$REDIS_HOST" \
	-f=DOCKERFILE-Dotnet . ; 
	then 
		((COUNTER++))
		echo -e "╭──────────────────────────────────────╮\n│ Done building the Dotnet container ! │\n╰──────────────────────────────────────╯" 
	else 
		echo -e "╭─────────────────────────────────────╮\n│ Error building the dotnet container │\n╰─────────────────────────────────────╯"
fi

echo -e "Building the result dashboard container..."
if docker build --tag voting-dashboard:1.0.0 \
	--build-arg POSTGRE_HOST="$PG_HOST" \
	-f=DOCKERFILE-Statistiques . ; 
	then 
		((COUNTER++))
		echo -e "╭─────────────────────────────────────────────────╮\n│ Done building the results dashboard container ! │\n╰─────────────────────────────────────────────────╯" 
	else 
		echo -e "╭────────────────────────────────────────────────╮\n│ Error building the results dashboard container │\n╰────────────────────────────────────────────────╯"
fi
# Si tous les builds se sont bien passés, on affiche le résultat en vert, et en rouge si il y a eu un soucis
COLOR="\e[31m" # On part du principe que tout se passe mal
if (( $COUNTER == $AMOUNT_OF_BUILDS )) ; then
	COLOR="\e[32m" # Et si ça s'est bien passé, c'est une bonne surprise !
fi

echo -e "╭────────────────╮\n│ Builds :$COLOR $COUNTER / $AMOUNT_OF_BUILDS\e[0m │\n╰────────────────╯"

	case "$1" in 
		-l|--list)
			echo "Containers built :"
		docker image ls
		;;
esac

;;

esac
