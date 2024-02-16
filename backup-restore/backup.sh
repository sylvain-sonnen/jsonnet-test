#!/usr/bin/env bash

set -euo pipefail
#set -x

echo "Checking for dependencies..."
if [[ "$BASH_VERSION" < "5.2" ]]; then
	echo "Error: bash is running an old version, please update to 5.2+"
	exit 1
fi

for cmd in curl jq; do
	if ! command -v $cmd &>/dev/null; then
		echo "Error: $cmd is not installed." >&2
		exit 1
	fi
done
echo "Done!"

GRAFANA_AUTH="glsa_eQkZuvOY7ccsPJUmWMp1ZQtoHunAOiHw_faf45ebe"
GRAFANA_URL="http://localhost:8080"

echo "Creating backup folder structure..."
folder="backup/"
if [ -d "$folder" ]; then
	rm -rf "$folder"
fi
mkdir -p backup/dashboards
mkdir -p backup/datasources
echo "Done!"

echo "Retrieving the list of dashboards from Grafana..."
uids=$(curl -s -H "Authorization: Bearer $GRAFANA_AUTH" "${GRAFANA_URL}/api/search?type=dash-db" | jq -r '.[].uid')

for uid in $uids; do
	echo "Fetching dashboard json model for UID: $uid"
	curl -s -H "Authorization: Bearer $GRAFANA_AUTH" "${GRAFANA_URL}/api/dashboards/uid/$uid" |
		jq '.' >"backup/dashboards/dashboard_model_$uid.json"
	echo "Dashboard model for UID: $uid saved to dashboard_model_$uid.json"
done
echo "Done!"

echo "Retrieving the list of datasources from Grafana..."
datasources=$(curl -s -H "Authorization: Bearer $GRAFANA_AUTH" "${GRAFANA_URL}/api/datasources")

# Parse and save each datasource to a separate JSON file
echo "$datasources" | jq -c '.[]' | while read -r datasource; do
	name=$(echo "$datasource" | jq -r '.name')
	echo "$datasource" | jq '.' >"backup/datasources/datasource_${name// /_}.json"
	echo "Datasource '$name' saved to datasource_${name// /_}.json"
done

echo "All datasources have been retrieved and saved."
