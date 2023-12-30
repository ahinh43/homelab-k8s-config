#!/usr/bin/env bash

dirname=$(date +%Y-%m-%d-%H-%M-%S-arkbackup)
basepath="/home/steam/.local/share/Steam/steamapps/common/ARK Survival Ascended Dedicated Server/ShooterGame/Saved"

aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/Config" s3://ark-sa/$dirname/Config --exclude '.git/*' --exclude 'CrashReportClient/*'
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp --recursive "${basepath}/SaveGames" s3://ark-sa/$dirname/SaveGames
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp "${basepath}/SavedArks/TheIsland_WP/TheIsland_WP.ark" s3://ark-sa/$dirname/TheIsland_WP/TheIsland_WP.ark
aws --endpoint-url http://minio.labs.ahinh.me:9000 s3 cp "${basepath}/SavedArks/TheIsland_WP/TheIsland_WP_AntiCorruptionBackup.bak" s3://ark-sa/$dirname/TheIsland_WP/TheIsland_WP_AntiCorruptionBackup.bak