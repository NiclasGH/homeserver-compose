#!/bin/bash
# Small script to create a list of currently installed shows and movies, so a recovery in case of data loss is just a matter of like an hour

OUTPUT_FILE="shows.txt"

# Check if media exists
if [ ! -d "jellyfin/media" ] || [ ! -d "jellyfin/media/shows" ] || [ ! -d "jellyfin/media/movies" ]; then
    echo "Media, Shows or Movies directory does not exist. Not updating shows file"
    exit 1
fi

echo "Shows" > shows.txt
find jellyfin/media/shows -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort >> shows.txt

printf "\nMovies\n" >> shows.txt
find jellyfin/media/movies -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort >> shows.txt
