#!/bin/bash
set -Eeux -o pipefail

pushd $(dirname "$0") >> /dev/null
trap "popd >> /dev/null" EXIT

endpoint="https://youtube.googleapis.com/youtube/v3/playlists"
request_parameta="part=snippet&mine=true&maxResults=50"

set +x
access_token=$(./get-access-token.sh)

response=$(
  curl "${endpoint}?${request_parameta}" \
    -H "Authorization: Bearer ${access_token}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --compressed
)

playlists_json=$(
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

  tmp_playlists=$(
    echo "${response}" \
    | jq -r .items
  )
  playlists_json=$(
    echo "${playlists_json}" "${tmp_playlists}" \
    | jq -s -r add
  )
done

echo "${playlists_json}"
