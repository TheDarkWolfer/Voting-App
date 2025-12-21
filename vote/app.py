from flask import Flask, render_template, request, make_response
from redis import Redis
import os
import socket
import random
import json
import logging

option_a = os.getenv('OPTION_A', "Cats")
option_b = os.getenv('OPTION_B', "Dogs")
hostname = socket.gethostname()

app = Flask(__name__)

app.logger.setLevel(logging.INFO)

# Ancienne fonction ; modifiée de par sa rigidité, et par besoin de pouvoir configurer certaines données à travers les variables d'environnement.
 # Gardée pour des soucis de documentation et en cas de besoin futur
#def get_redis():
#    if not hasattr(Flask, 'redis'):
#        Flask.redis = Redis(host="localhost", db=0, socket_timeout=5)
#    return Flask.redis

def get_redis():
    # Récupération des variables d'environnement
    redis_host = os.getenv('REDIS_HOST','localhost')
    redis_port = os.getenv('REDIS_PORT','6379')
    redis_timeout = os.getenv('REDIS_TIMEOUT','5')
    redis_db = os.getenv('REDIS_DB','0')

    # Assemblage des variables d'environnement dans un objet Redis qui est ensuite passé à Flask 
    Flask.redis = Redis(host=f"{redis_host}:{redis_port}",db=redis_db,socket_timeout=redis_timeout)                                #Man I love fstrings <3
    
    return Flask.redis

@app.route("/", methods=['POST', 'GET'])
def hello():
    voter_id = request.cookies.get('voter_id')
    if not voter_id:
        voter_id = hex(random.getrandbits(64))[2:-1]

    vote = None

    if request.method == 'POST':
        redis = get_redis()
        vote = request.form['vote']
        app.logger.info('Received vote for %s', vote)
        data = json.dumps({'voter_id': voter_id, 'vote': vote})
        redis.rpush('votes', data)

    resp = make_response(render_template(
        'index.html',
        option_a=option_a,
        option_b=option_b,
        hostname=hostname,
        vote=vote,
    ))
    resp.set_cookie('voter_id', voter_id)
    return resp

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080, debug=True, threaded=True)
