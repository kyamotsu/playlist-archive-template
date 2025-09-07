#!/bin/bash
set -Eeux -o pipefail

pushd $(dirname "$0") >> /dev/null
trap "popd >> /dev/null" EXIT

archive_dir=$(realpath "./../archive/youtube")
github_repository_url="https://github.com/${GITHUB_REPOSITORY}"

playlists=$(
  ./get-playlists.sh \
  | jq -c .[]  
)

playlist_index_file_path="${archive_dir}/playlist_index.json"
echo "[]" | jq -r . > "${playlist_index_file_path}"

IFS=$'\n'; for playlist in ${playlists}; do
  id="$(echo ${playlist} | jq -r .id)"
  name="$(echo ${playlist} | jq -r .snippet.title)"
  created_at="$(echo ${playlist} | jq -r .snippet.publishedAt)"
  description="$(echo ${playlist} | jq -r .snippet.description)"

  playlist_archive_json_path="${archive_dir}/playlists/${id}.json"

  echo '{
    "id": "'"${id}"'",
    "name": "'"${name}"'",
    "createdAt": "'"${created_at}"'",
    "url": "'"https://www.youtube.com/playlist?list=${id}"'",
    "description": "'"${description}"'",
    "videoCount": 0,
    "videos": []
  }' \
  | jq -r > "${playlist_archive_json_path}"

  ./archive-playlist.sh "${playlist_archive_json_path}"

  video_count="$(jq -r .videoCount ${playlist_archive_json_path})"
  archive_url="${github_repository_url}/tree/main/archive/youtube/playlists/${id}.json"

  tmp=$(
    jq \
      --arg id "${id}" \
      --arg name "${name}" \
      --arg createdAt "${created_at}" \
      --arg url "https://www.youtube.com/playlist?list=${id}" \
      --arg description "${description}" \
      --arg videoCount "${video_count}" \
      --arg archiveUrl "${archive_url}" \
      '. += [
        {
          "id": $id,
          "name": $name,
          "createdAt": $createdAt,
          "url": $url,
          "description": $description,
          "videoCount": $videoCount,
          "archiveUrl": $archiveUrl
        }
      ]' \
      "${playlist_index_file_path}"
  )
  echo "${tmp}" > "${playlist_index_file_path}"
done
