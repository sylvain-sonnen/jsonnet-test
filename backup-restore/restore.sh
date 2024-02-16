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

GRAFANA_AUTH="<changeme:gitlab-service-account-token>"
GRAFANA_URL="http://localhost:8080"

echo "Restoring dashboards from backup..."
for dashboard_json in backup/dashboards/*.json; do
	echo "Restoring $dashboard_json..."

	original_json=$(<"$dashboard_json")
	dashboard_content=$(echo "$original_json" | jq '.dashboard')
	folder_id=$(echo "$original_json" | jq '.meta.folderId')
	dashboard_uid=$(echo "$dashboard_content" | jq -r '.uid')

	dashboard_exists=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $GRAFANA_AUTH" "${GRAFANA_URL}/api/dashboards/uid/$dashboard_uid")

	if [ "$dashboard_exists" -eq 404 ]; then
		dashboard_content=$(echo "$dashboard_content" | jq '.id=null | .uid=null')
	fi

	payload=$(jq -n --argjson dashboard "$dashboard_content" --argjson folderId "$folder_id" \
		'{dashboard: $dashboard, folderId: $folderId, overwrite: true}')

	curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_AUTH" \
		-d "$payload" "${GRAFANA_URL}/api/dashboards/db" | jq .
done
echo "Done!"

echo "Restoring datasources from backup..."
for datasource_json in backup/datasources/*.json; do
	echo "Restoring $datasource_json..."

	datasource_content=$(<"$datasource_json")
	datasource_name=$(echo "$datasource_content" | jq -r '.name')

	existing_datasource_id=$(curl -s -H "Authorization: Bearer $GRAFANA_AUTH" "${GRAFANA_URL}/api/datasources/name/$datasource_name" | jq -r '.id // empty')

	if [ -n "$existing_datasource_id" ]; then
		echo "Datasource '$datasource_name' exists with ID $existing_datasource_id. Updating..."
		update_response=$(curl -s -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_AUTH" \
			-d "$datasource_content" "${GRAFANA_URL}/api/datasources/$existing_datasource_id")
		echo "Update response: $update_response"
	else
		echo "Datasource '$datasource_name' does not exist. Creating..."
		create_response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $GRAFANA_AUTH" \
			-d "$datasource_content" "${GRAFANA_URL}/api/datasources")
		echo "Create response: $create_response"
	fi
done
echo "done"
