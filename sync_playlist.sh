#!/usr/bin/bash

# Jellyfin Playlist Sync - Syncs YouTube videos from JSON to Jellyfin playlist
# Uses local config from jellyfin-mpv-shim instead of hardcoded credentials

if [ $# -ne 2 ]; then
  echo "Usage: $0 <json_file> <playlist_id>"
  exit 1
fi

JSON_FILE="$1"
PLAYLIST_ID="$2"

# Read config from jellyfin-mpv-shim
CONFIG_FILE="$HOME/.config/jellyfin-mpv-shim/cred.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file not found at $CONFIG_FILE"
  exit 1
fi

SERVER_URL=$(jq -r '.[0].address' "$CONFIG_FILE")
ACCESS_TOKEN=$(jq -r '.[0].AccessToken' "$CONFIG_FILE")

if [ -z "$SERVER_URL" ] || [ "$SERVER_URL" == "null" ]; then
  echo "Error: Could not read SERVER_URL from config"
  exit 1
fi

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
  echo "Error: Could not read ACCESS_TOKEN from config"
  exit 1
fi

echo "✓ Loaded config from $CONFIG_FILE"
echo "  Server: $SERVER_URL"

# Get all videos from Jellyfin
echo "Fetching all Jellyfin videos..."
ALL_VIDEOS=$(curl -s -X GET "$SERVER_URL/Items?Recursive=true&Fields=ProviderIds,Path&MediaTypes=Video&Limit=1000000" \
  -H "X-Emby-Token: $ACCESS_TOKEN")

# Clear playlist
echo "Clearing Playlist..."
CURRENT_ITEMS=$(curl -s -X GET "$SERVER_URL/Playlists/$PLAYLIST_ID/Items" \
  -H "X-Emby-Token: $ACCESS_TOKEN")

ITEM_IDS=$(echo "$CURRENT_ITEMS" | jq -r '.Items[].Id' | paste -sd "," -)

if [ -n "$ITEM_IDS" ]; then
  curl -s -X DELETE "$SERVER_URL/Playlists/$PLAYLIST_ID/Items?entryIds=$ITEM_IDS" \
    -H "X-Emby-Token: $ACCESS_TOKEN" > /dev/null
  echo "✓ Playlist cleared"
else
  echo "✓ Playlist already empty"
fi

# Build UUID list and sync
echo "Syncing videos..."
declare -a UUIDS
FOUND_COUNT=0

# Process JSON in one pass
while IFS= read -r youtube_id; do
  # Try to find by provider ID first
  uuid=$(echo "$ALL_VIDEOS" | jq -r --arg ytid "$youtube_id" '.Items[] | select(.ProviderIds.youtube == $ytid) | .Id' | head -1)
  
  # Fallback to path search
  if [ -z "$uuid" ] || [ "$uuid" == "null" ]; then
    uuid=$(echo "$ALL_VIDEOS" | jq -r --arg ytid "$youtube_id" '.Items[] | select(.Path | contains($ytid)) | .Id' | head -1)
  fi
  
  if [ -n "$uuid" ] && [ "$uuid" != "null" ]; then
    UUIDS+=("$uuid")
    echo "  ✓ $youtube_id"
    ((FOUND_COUNT++))
  else
    echo "  ✗ $youtube_id (not found)"
  fi
done < <(jq -r '.[] | .locator' "$JSON_FILE")

# Add items to playlist
if [ ${#UUIDS[@]} -gt 0 ]; then
  echo "Adding $FOUND_COUNT videos to playlist..."
  
  ADD_PARAMS=""
  for uuid in "${UUIDS[@]}"; do
    ADD_PARAMS="$ADD_PARAMS&ids=$uuid"
  done
  
  curl -s -X POST "$SERVER_URL/Playlists/$PLAYLIST_ID/Items?${ADD_PARAMS:1}" \
    -H "X-Emby-Token: $ACCESS_TOKEN" > /dev/null
  
  echo "Sync complete! Added $FOUND_COUNT videos"
else
  echo "No videos found to add"
  exit 1
fi
