#!/usr/bin/env bash
olm_version="v0.24.0"

curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/$olm_version/install.sh -o install.sh
chmod +x install.sh
./install.sh $olm_version

rm install.sh