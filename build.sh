#!/usr/bin/env bash
echo -e "Build script for Camille's PRADO Docker project"

echo -e "Building the Redis container..."
docker build --tag voting-redis:1.0.0 -f=DOCKERFILE-Redis . && echo -e "╭─────────────────────────────────────╮\n│ Done building the Redis container ! │\n╰─────────────────────────────────────╯" || echo -e "╭────────────────────────────────────╮\n│ Error building the Redis container │\n╰────────────────────────────────────╯"

echo -e "Building the voting container..."
docker build --tag voting-python:1.0.0 -f=DOCKERFILE-Votebox . && echo -e "╭──────────────────────────────────────╮\n│ Done building the voting container ! │\n╰──────────────────────────────────────╯" || echo -e "╭─────────────────────────────────────╮\│ Error building the voting container │\n╰─────────────────────────────────────╯"

echo -e "Building the postgresql container..."
docker build --tag voting-postgresql:1.0.0 -f=DOCKERFILE-Postgresql . && echo -e "╭──────────────────────────────────────────╮\n│ Done building the postgresql container ! │\n╰──────────────────────────────────────────╯" || echo -e "╭─────────────────────────────────────────╮\n│ Error building the postgresql container │\n╰─────────────────────────────────────────╯"

echo -e "Building the worker program..."
dotnet publish -c release --self-contained false --no-restore ./worker/ && echo -e "╭───────────────────────╮\n│ Worker binary built ! │\n╰───────────────────────╯" || echo -e "╭──────────────────────────────╮\n│ Error building worker binary │\n╰──────────────────────────────╯"
echo -e "Building the dotnet container..."
docker build --tag voting-worker:1.0.0 -f=DOCKERFILE-Dotnet . && echo -e "╭──────────────────────────────────────╮\n│ Done building the Dotnet container ! │\n╰──────────────────────────────────────╯" || echo -e "╭─────────────────────────────────────╮\n│ Error building the dotnet container │\n╰─────────────────────────────────────╯"
