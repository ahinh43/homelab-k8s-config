#!/usr/bin/env bash

dirname=$(date +%Y-%m-%d-%H-%M-%S-arkbackup)
basepath="/home/steam/ark/Saved"

# Backup server config
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/Config" s3://ark-sa/$dirname/Config --exclude '.git/*' --exclude 'CrashReportClient/*'
# Backup mod configurations
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/SaveGames" s3://ark-sa/$dirname/SaveGames
# Backup tribe profiles and characters
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/SavedArks/TheIsland_WP" s3://ark-sa/$dirname/TheIsland_WP --include '*.arkprofile' --include '*.profilebak' --include '*.arktribe' --include '*.tribebak' --exclude '*.ark' --exclude '*.bak'
# Backup the world
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp "${basepath}/SavedArks/TheIsland_WP/TheIsland_WP.ark" s3://ark-sa/$dirname/TheIsland_WP/TheIsland_WP.ark
# Backup the backup of the world
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp "${basepath}/SavedArks/TheIsland_WP/TheIsland_WP_AntiCorruptionBackup.bak" s3://ark-sa/$dirname/TheIsland_WP/TheIsland_WP_AntiCorruptionBackup.bak