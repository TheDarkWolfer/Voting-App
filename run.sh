#!/usr/bin/env bash
# Un petit script qui lance les conteneurs d'un coup, vu que cinq conteneurs ça fait un paquet de commandes et d'arguments à taper.

# Le script contient un compteur qui permet de savoir combien de conteneurs ont étés lancés avec succès ; le total est dynamiquement compté grâce aux mots-clef `if`. De ce fait, il faut parfois modifier ce chiffre, pour que le compte soit bon ^^'
OFFSET=10

case "$1" in

	-k|--killall)
		docker ps | tail -n "$(($(docker ps | wc -l)-1))" | awk '{print $1}' | xargs docker kill

		# Option pour supprimer les résultats de vote et recommencer de zéro
		read -r -p "Supprimer les volumes ? [y/N]: " delVol
		if [[ "${delVol,,}"  == "y" ]]; then
			if docker volume ls | awk '{print $2}' | grep voting-app_ ; then
				if docker volume rm {voting-app_votebox_pgdata,voting-app_votebox_redis} ; then
					echo -e "Volumes supprimés !"
				else
					echo -e "Erreur lors de la suppression des volumes (つ╥﹏╥)つ"
				fi
			elif docker volume ls | awk '{print $2}' | grep data ; then
				if docker volume rm {redisdata,pgdata} ; then
					echo -e "Volumes supprimés !"
				else
					echo -e "Erreur lors de la suppression des volumes (つ╥﹏╥)つ"
				fi
			fi
		fi
		;;
	-h|--help)
		echo -e "Script permettant de lancer / interrompre les conteneurs."
		echo -e "Arguments:"
		echo -e "\t-h ou --help\t: affiche ce message"
		echo -e "\t-c ou --compose\t: Lance avec docker compose"
		echo -e "\t-s ou --swarm\t: Lance en mode Swarm"
		echo -e "\t-k ou --killall\t: Met fin à l'execution de tous les conteneurs docker lancés sur le système"
		echo -e "-*-"
		echo -e "\t--options\t\t: Permet de choisir les options de vote (argument expérimental)"
		;;
	-s|--swarm)
		echo "Not yet implemented, sorry (¬_¬)''" ; exit -1
		docker stack deploy voting-app --compose-file docker-compose-swarm.yml
		;;
	-c|--compose)
		docker compose up
		;;
	*)
		# Logique similaire au script build.sh ; 


		# Si les réseaux n'existent pas, '
		if docker network ls | awk '{print $2}' | grep 'vote-network' > /dev/null ; then
			docker network create vote-network && echo -e "Réseau de vote (public) créé" || echo -e "Erreur lors de la création du réseaux de vote (public) !"
		fi 

		if docker network ls | awk '{print $2}' | grep 'vote-network' > /dev/null ; then
			docker network create processing-network && echo -e "Réseau de traitement (privé) créé" || echo -e "Erreur lors de la création du réseaux de traitement (privé) !"
		fi 

	COUNTER=0
	LAUNCHES=$(($(grep -c if $0)-$OFFSET))
	echo -e "Launching redis container..."
	if docker run -d --rm -p 6379:6379 -v redisdata:/data --name redis --network processing-network voting-redis:1.0.0 ; then
		((COUNTER++))
		echo -e "Redis container launched !"
	else 
		echo -e "Error launching the redis container :("
	fi

	echo -e "Launching postgresql container..."
	if docker run -d --rm -p 5432:5432 -v pgdata:/bitnami/postgresql --name postgresql --network processing-network voting-postgresql:1.0.0 ; then
		((COUNTER++))
		echo -e "Postgresql container launched !"
	else
		echo -e "Error launching the postgresql container :("
	fi

	echo -e "Launching python app container..."
	
	# On demande les options de vote à l'utilisateur.ice grâce à l'argument --options 
	if [[ "$1" == "--options" ]] ; then
		read -p "Option A > " OPTION_A
		read -p "Option B > " OPTION_B
	else 
		OPTION_A="Cats"
		OPTION_B="Dogs"
	fi

	if docker run -d --rm -p 8080:8080 --env OPTION_A="$OPTION_A" --env OPTION_B="$OPTION_B" --name voting-app --network vote-network --network processing-network voting-python:1.0.0 ; then
		((COUNTER++))
		echo -e "Voting app container launched !"
	else 
		echo -e "Error launching voting container :("
	fi 

	echo -e "Launching dotnet worker container..."
	if docker run -d --rm -p 443:443 -p 80:80 --name voting-worker --network processing-network voting-worker:1.0.0 ; then 
		((COUNTER++))
		echo -e "Data worker container launched !"
	else 
		echo -e "Error launching the data worker container :("
	fi

	echo -e "Launching results dashboard container..."
	if docker run -d --rm -p 8888:8888 --name voting-dashboard --network vote-network --network processing-network voting-dashboard:1.0.0 ; then 
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
