#!/usr/bin/env bash

dirname=$(date +%Y-%m-%d-%H-%M-%S-palbackup)
basepath="/home/steam/palworld/Pal/Saved"

# Backup server config
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/Config" s3://palworld/$dirname/Config --exclude '.git/*' --exclude 'CrashReportClient/*'
# Backup the world and players
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/SaveGames/0/95A2B2D0ABE34D79B9E02C780546E012" s3://palworld/$dirname/SaveGames/0/95A2B2D0ABE34D79B9E02C780546E012