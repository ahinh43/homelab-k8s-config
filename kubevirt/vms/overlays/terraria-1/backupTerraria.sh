#!/usr/bin/env bash

dirname=$(date +%Y-%m-%d-%H-%M-%S-terraria-backup)
basepath="/home/steam/.local/share/Terraria/tModLoader/Worlds"

# Backup the world (but not the bak)
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/Worlds" s3://terraria/$dirname/Worlds --exclude 'Backups/*'