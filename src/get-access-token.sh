#!/bin/bash
set -Eeu -o pipefail
set +x

pushd $(dirname "$0") >> /dev/null
trap "popd >> /dev/null" EXIT

access_token_json=$(
  curl "https://accounts.google.com/o/oauth2/token" \
    -d "client_id=${CLIENT_ID}" \
    -d "client_secret=${CLIENT_SECRET}" \
    -d "refresh_token=${REFRESH_TOKEN}" \
    -d "grant_type=refresh_token" \
  | jq -r .
)

if [[ $(echo "${access_token_json}" | jq -r .error) != "null" ]]; then
  echo "${access_token_json}"
  exit 1
fi

access_token=$(echo "${access_token_json}" | jq -r .access_token)

echo "${access_token}"

set -x
