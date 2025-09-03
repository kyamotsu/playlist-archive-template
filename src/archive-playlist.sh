#!/bin/bash
set -Eeux -o pipefail

playlist_json_path="$1"

pushd $(dirname "$0") >> /dev/null
trap "popd >> /dev/null" EXIT

playlist_id=$(jq -r .id "${playlist_json_path}")

playlist_items=$(
  ./get-playlist-items.sh "${playlist_id}" \
  | jq -c .[]
)

set +x
IFS=$'\n'; for video in ${playlist_items}; do
  id="$(echo ${video} | jq -r .snippet.resourceId.videoId)"
  name="$(echo ${video} | jq -r .snippet.title)"
  added_at="$(echo ${video} | jq -r .snippet.publishedAt)"
  description="$(echo ${video} | jq -r .snippet.description)"
  channel_id="$(echo ${video} | jq -r .snippet.videoOwnerChannelId)"
  channel_name="$(echo ${video} | jq -r .snippet.videoOwnerChannelTitle)"

  is_available=true
  if [[ "${name}" == "Deleted video" && "${description}" == "This video is unavailable." && "${channel_id}" == "null" && "${channel_name}" == "null" ]]; then
    is_available=false
  fi

  tmp=$(
    jq \
      --arg id "${id}" \
      --arg name "${name}" \
      --arg addedAt "${added_at}" \
      --arg isAvailable "${is_available}" \
      --arg url "https://www.youtube.com/watch?v=${id}" \
      --arg description "${description}" \
      --arg channelId "${channel_id}" \
      --arg channelName "${channel_name}" \
      '.videos += [
        {
          "id": $id,
          "name": $name,
          "addedAt": $addedAt,
          "isAvailable": $isAvailable,
          "url": $url,
          "description": $description,
          "channelId": $channelId,
          "channelName": $channelName
        }
      ]' \
      "${playlist_json_path}"
  )
  echo "${tmp}" > "${playlist_json_path}"
done

tmp=$(
  jq \
    '.videoCount = (.videos | length)' \
    "${playlist_json_path}"
)
echo "${tmp}" > "${playlist_json_path}"
