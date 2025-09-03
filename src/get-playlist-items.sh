#!/bin/bash
set -Eeux -o pipefail

playlist_id="$1"

pushd $(dirname "$0") >> /dev/null
trap "popd >> /dev/null" EXIT

endpoint="https://www.googleapis.com/youtube/v3/playlistItems"
request_parameta="part=snippet&playlistId=${playlist_id}&maxResults=50"

set +x
access_token=$(./get-access-token.sh)

response=$(
  curl "${endpoint}?${request_parameta}" \
    -H "Authorization: Bearer ${access_token}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --compressed
)

playlist_items_json=$(
  echo "${response}" \
  | jq -r .items
)

while [[ $(echo "${response}" | jq -r .nextPageToken) != "null" ]]; do
  next_page_token=$(
    echo "${response}" \
    | jq -r .nextPageToken
  )
  response=$(
    curl "${endpoint}?${request_parameta}&pageToken=${next_page_token}" \
      -H "Authorization: Bearer ${access_token}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --compressed
  )

  tmp_playlist_items=$(
    echo "${response}" \
    | jq -r .items
  )
  playlist_items_json=$(
    echo "${playlist_items_json}" "${tmp_playlist_items}" \
    | jq -s -r add
  )
done

echo "${playlist_items_json}"
