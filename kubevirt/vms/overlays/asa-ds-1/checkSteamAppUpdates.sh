#!/usr/bin/env bash

# This script queries steamdb for the latest BuildID for the designated steam app
# compares it with the locally stored ID and if it doesn't match, run steacmd
# to update and validate the game files.

# If any args is passed, the app will always check for an update and validate.
set -e
steamappid="2430930"
steamhomeDir="/home/steam"
appIdVersionFile="$steamhomeDir/$steamappid.version"
appIdVersionFileLastUpdated="$steamhomeDir/$steamappid.version.lastupdated"
updatedDate=$(date +"%s")

manuallyRun="$1"

if [ ! -n "$manuallyRun" ]; then
  if [ ! -f "$appIdVersionFile" ]; then
    echo "0" > "$appIdVersionFile"
  fi
  if [ ! -f "$appIdVersionFileLastUpdated" ]; then
    echo "$updatedDate" > "$appIdVersionFileLastUpdated"
  fi
  localAppVersion="$(cat $appIdVersionFile)"
  localAppUpdatedDate="$(cat $appIdVersionFileLastUpdated)"
  latestAppVersion=$(curl "https://api.steamcmd.net/v1/info/$steamappid" | jq -r ".data.\"$steamappid\".depots[][] | select(.buildid? != null) | .buildid"  | sort | tail -n1)
  echo "Local app version: $localAppVersion"
  echo "Latest app version: $latestAppVersion"
  if [[ "$localAppVersion" != "$latestAppVersion" ]]; then
    echo "App versions do not match. Running steamcmd to validate and update files.."
  else
    dateDiff=$(($updatedDate - $localAppUpdatedDate))
    if [[ "$dateDiff" > 86400 ]]; then
        echo "Last check was over 24 hours ago. Verifying files to ensure app integrity..."
    else
        echo "App up to date and last check was less than 24 hours ago. Skipping file checks."
        exit 0
    fi
  fi
fi

/usr/games/steamcmd +login anonymous +app_update $steamappid validate +quit

if [ -z "$latestAppVersion" ]; then
  latestAppVersion=$(curl "https://api.steamcmd.net/v1/info/$steamappid" | jq -r ".data.\"$steamappid\".depots[][] | select(.buildid? != null) | .buildid"  | sort | tail -n1)
fi

echo "$latestAppVersion" > "$appIdVersionFile"
echo "$updatedDate" > "$appIdVersionFileLastUpdated"