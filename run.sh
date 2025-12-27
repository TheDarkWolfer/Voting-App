#!/usr/bin/env bash
# Un petit script qui lance les conteneurs d'un coup, vu que cinq conteneurs ça fait un paquet de commandes et d'arguments à taper.

case "$1" in

	-k|--killall)
		docker ps | tail -n "$(($(docker ps | wc -l)-1))" | awk '{print $1}' | xargs docker kill
		;;
	-h|--help)
		echo -e "Script permettant de lancer / interrompre les conteneurs."
		echo -e "Arguments:"
		echo -e "\t-h ou --help\t: affiche ce message"
		echo -e "\t-c ou --compose\t: Lance avec docker compose"
		echo -e "\t-s ou --swarm\t: Lance en mode Swarm"
		echo -e "\t-k ou --killall\t: met fin à l'execution de tous les conteneurs docker lancés sur le système"
		;;
	-s|--swarm)
		docker stack deploy voting-app --compose-file docker-compose-swarm.yml
		;;
	-c|--compose)
		docker compose up
		;;
	*)
		# Logique similaire au script build.sh ; 
	COUNTER=0
	LAUNCHES=$(($(grep -c if $0)-2))
	echo -e "Launching redis container..."
	if docker run -d --rm -p 6379:6379 -v redisdata:/data --name redis --network vote-network voting-redis:1.0.0 ; then
		((COUNTER++))
		echo -e "Redis container launched !"
	else 
		echo -e "Error launching the redis container :("
	fi

	echo -e "Launching postgresql container..."
	if docker run -d --rm -p 5432:5432 -v pgdata:/bitnami/postgresql --name postgresql --network vote-network voting-postgresql:1.0.0 ; then
		((COUNTER++))
		echo -e "Postgresql container launched !"
	else
		echo -e "Error launching the postgresql container :("
	fi

	echo -e "Launching python app container..."
	if docker run -d --rm -p 8080:8080 --name voting-app --network vote-network voting-python:1.0.0 ; then
		((COUNTER++))
		echo -e "Voting app container launched !"
	else 
		echo -e "Error launching voting container :("
	fi 

	echo -e "Launching dotnet worker container..."
	if docker run -d --rm -p 443:443 -p 80:80 --name voting-worker --network vote-network voting-worker:1.0.0 ; then 
		((COUNTER++))
		echo -e "Data worker container launched !"
	else 
		echo -e "Error launching the data worker container :("
	fi

	echo -e "Launching results dashboard container..."
	if docker run -d --rm -p 8888:8888 --name voting-dashboard --network vote-network voting-dashboard:1.0.0 ; then 
		((COUNTER++))
		echo -e "Dashboard container launched !"
	else 
		echo -e "Error launching the dashboard container :("
	fi

	# Si tous les lancements se sont bien passés, on affiche le résultat en vert, et en rouge si il y a eu un soucis
	COLOR="\e[31m" # On part du principe que tout se passe mal
	if (( $COUNTER == $LAUNCHES )) ; then
		COLOR="\e[32m" # Et si ça s'est bien passé, c'est une bonne surprise !
	fi

	echo -e "╭──────────────────╮\n│ Launches :$COLOR $COUNTER / $LAUNCHES\e[0m │\n╰──────────────────╯"

	;;
esac
