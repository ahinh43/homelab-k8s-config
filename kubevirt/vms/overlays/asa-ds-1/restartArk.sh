#!/usr/bin/env bash

# Restarts the ARK server by attempting to gracefully shutdown the Ark.exe process via systemd
# then killing the stuck winedevice process that inevitably happens
set -e

if ps -auuwx | grep ArkAscendedServer.exe | grep -q -v grep; then
  echo "Stopping the ark service.."
  # TODO: Add RCON command to save the world prior to shutting down
  /opt/rcon-cli --config /home/steam/.rcon-cli.yaml saveworld
  systemctl stop ark.service&
fi

until ! ps -auuwx | grep ArkAscendedServer.exe | grep -q -v grep
do
    echo "Waiting for the Ark process to be terminated.."
    sleep 2
done


echo "Ark process has been terminated. Killing all winedevice.exe processes.."
ls -l /proc/*/exe 2>/dev/null | grep -E 'wine(64)?-preloader|wineserver' | perl -pe 's;^.*/proc/(\d+)/exe.*$;$1;g;' | xargs -n 1 kill

echo "Starting Ark server again.."
systemctl start ark.service

