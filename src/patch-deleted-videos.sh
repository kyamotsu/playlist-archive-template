#!/bin/bash
set -Eeux -o pipefail

pushd $(dirname "$0") >> /dev/null
trap "popd >> /dev/null" EXIT

archive_dir="../archive/youtube"
patch_file_path="../patch/youtube.json"

playlists=$(
  jq -c .[] "${archive_dir}/playlist_index.json"
)

set +x

IFS=$'\n'; for playlist in ${playlists}; do
  playlist_id="$(echo ${playlist} | jq -r .id)"
  playlist_file_path="${archive_dir}/playlists/${playlist_id}.json"
  videos=$(jq -c .videos[] "${playlist_file_path}")
  patched_playlist=$(
    echo "${playlist}" \
    | jq '.videos |= []' 
  )

  IFS=$'\n'; for video in ${videos}; do
    is_available="$(echo ${video} | jq -r .isAvailable)"
    if ! "${is_available}"; then
      id=$(echo "${video}" | jq -r .id)
      patch=$(jq '.[] | select(.id == "'"${id}"'")' "${patch_file_path}")
      if [[ "${patch}" != "" ]]; then
        echo "patch video: ${id}"
        patch_name="$(echo ${patch} | jq -r .name)"
        patch_description="$(echo ${patch} | jq -r .description)"
        video=$(
          echo "${video}" \
          | jq '.name |= "'"${patch_name}"'" | .description |= "'"${patch_description}"'"'
        )
      fi
    fi
    patched_playlist=$(
      echo "${patched_playlist}" \
      | jq \
        --argjson video "${video}" \
        '.videos += [$video]'
    )
  done

  echo "${patched_playlist}" | jq -r > "${playlist_file_path}"
done
