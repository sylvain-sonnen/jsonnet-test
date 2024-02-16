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

echo "Restoring dashboards from backup..."
for dashboard_json in backup/dashboards/*.json; do
	echo "Restoring $dashboard_json..."

	# Read and parse the original JSON content
	original_json=$(<"$dashboard_json")
	dashboard_content=$(echo "$original_json" | jq '.dashboard')
	folder_id=$(echo "$original_json" | jq '.meta.folderId')
	dashboard_uid=$(echo "$dashboard_content" | jq -r '.uid')

	# Check if the dashboard exists
	dashboard_exists=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $GRAFANA_AUTH" "${GRAFANA_URL}/api/dashboards/uid/$dashboard_uid")

	# If dashboard does not exist (HTTP 404), set id and uid to null
	if [ "$dashboard_exists" -eq 404 ]; then
		dashboard_content=$(echo "$dashboard_content" | jq '.id=null | .uid=null')
	fi

	# Prepare the JSON payload with the "dashboard" key, "folderId", and "overwrite": true
	payload=$(jq -n --argjson dashboard "$dashboard_content" --argjson folderId "$folder_id" \
		'{dashboard: $dashboard, folderId: $folderId, overwrite: true}')

	# Use the Grafana API to import the dashboard with the modified payload
	curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_AUTH" \
		-d "$payload" "${GRAFANA_URL}/api/dashboards/db" | jq .
done
echo "Done!"

echo "Restoring datasources from backup..."
for datasource_json in backup/datasources/*.json; do
	echo "Restoring $datasource_json..."

	# Read the datasource JSON content
	datasource_content=$(<"$datasource_json")
	datasource_name=$(echo "$datasource_content" | jq -r '.name')

	# Check if the datasource exists in Grafana by name
	existing_datasource_id=$(curl -s -H "Authorization: Bearer $GRAFANA_AUTH" "${GRAFANA_URL}/api/datasources/name/$datasource_name" | jq -r '.id // empty')

	# If the datasource exists, update it
	if [ -n "$existing_datasource_id" ]; then
		echo "Datasource '$datasource_name' exists with ID $existing_datasource_id. Updating..."
		update_response=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_AUTH" \
			-d "$datasource_content" "${GRAFANA_URL}/api/datasources/$existing_datasource_id")
		echo "Update response: $update_response"
	else
		# If the datasource does not exist, create it
		echo "Datasource '$datasource_name' does not exist. Creating..."
		create_response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_AUTH" \
			-d "$datasource_content" "${GRAFANA_URL}/api/datasources")
		echo "Create response: $create_response"
	fi
done
echo "done"
