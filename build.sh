#!/usr/bin/env bash
echo -e "Build script for Camille's PRADO Docker project"

#set -euo pipefail
# Pour compter le nombre de conteneurs qui sont construits avec succès, pour faciliter la lecture des logs 
COUNTER=0
AMOUNT_OF_BUILDS=$(($(grep -c if $0)-2))

echo -e "Building the Redis container..."
if docker build --tag voting-redis:1.0.0 -f=DOCKERFILE-Redis . ;
	then
		((COUNTER++))
		echo -e "╭─────────────────────────────────────╮\n│ Done building the Redis container ! │\n╰─────────────────────────────────────╯"
	else 
		echo -e "╭────────────────────────────────────╮\n│ Error building the Redis container │\n╰────────────────────────────────────╯"
fi

echo -e "Building the voting container..."
if docker build --tag voting-python:1.0.0 -f=DOCKERFILE-Votebox . ; 
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
if docker build --tag voting-worker:1.0.0 -f=DOCKERFILE-Dotnet . ; 
	then 
		((COUNTER++))
		echo -e "╭──────────────────────────────────────╮\n│ Done building the Dotnet container ! │\n╰──────────────────────────────────────╯" 
	else 
		echo -e "╭─────────────────────────────────────╮\n│ Error building the dotnet container │\n╰─────────────────────────────────────╯"
fi

echo -e "Building the result dashboard container..."
if docker build --tag voting-dashboard:1.0.0 -f=DOCKERFILE-Statistiques . ; 
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
