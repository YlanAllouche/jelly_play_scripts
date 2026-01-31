# Jelly Play Scripts

Get a video downloaded from
A few examples on how to enjoy videos and Youtube notes created by [CaptureMD](https://github.com/YlanAllouche/capturemd).

## Scripts

### `jelly_play_yt`

Plays a video indexed on your Jellyfin server locally into jelly-mpv-shim by providing its YouTube ID.

**Usage:**
```bash
JELLYFIN_SERVER_URL="https://your-jellyfin-server.com"
JELLYFIN_USERNAME="your_username"
JELLYFIN_PASSWORD="your_password"

jelly_play_yt <youtube_id>
```

**Environment Variables:**
- `JELLYFIN_SERVER_URL` - URL to your Jellyfin server
- `JELLYFIN_USERNAME` - Jellyfin username
- `JELLYFIN_PASSWORD` - Jellyfin password

**How it works:**

1. Authenticates with Jellyfin using username/password
2. Searches for the video by YouTube ID
3. Sends a play command to your mpv-shim session

**Technical Notes:**

Jellyfin stores YouTube video IDs as custom provider IDs (external IDs), but the API doesn't support direct querying of this field. This means we must fetch all videos from the server and parse through them to find the match. This is an expensive operation, but it's the most reliable way to locate videos by their YouTube ID.

### `sync_playlist`

Syncs a playlist from a JSON file into an existing Jellyfin playlist.

**Usage:**
```bash
./sync_playlist <json_file> <playlist_id>
```

**Arguments:**
- `json_file` - Path to JSON file containing YouTube video IDs
- `playlist_id` - Jellyfin playlist ID to sync to

**JSON Format:**
```json
[
  { "locator": "youtube_id_1" },
  { "locator": "youtube_id_2" }
]
```

**How it works:**

1. Reads YouTube IDs from the provided JSON file
2. Matches each ID against videos in Jellyfin
3. Clears the target playlist and adds matching videos

**Note:**

This script is particularly useful for syncing materialized dataview queries (e.g., from Obsidian) directly into Jellyfin playlists. It reuses the existing mpv-shim configuration (`~/.config/jellyfin-mpv-shim/cred.json`) to authenticate, completely skipping the need for explicit username/password authentication.

### jelly_play.lua

Simple lua script for neovim that retrieves the note's ID if and pases it to themain script.  
Going into a markdown note created and cached by `CaptureMd`, we can immediately play the video in the local jellyfin-mpv-shim bypressing `<leader>bp`

## Future Improvements

### Caching Strategy
We could implement local caching of Jellyfin video IDs to avoid expensive API calls on each execution. This would dramatically improve performance.

### Direct Note Sync
Instead of syncing playlists, we could update notes directly with Jellyfin internal IDs. This would eliminate the current delay inherent in the YouTube ID lookup process and provide a more direct reference system.

## Architecture Notes

- **Authentication:** `jelly_play_yt` requires explicit credentials via environment variables. `sync_playlist` cleverly reuses the existing mpv-shim configuration, requiring no additional authentication setup.
- **Video Lookup:** Both scripts use a fallback strategy:
  1. First attempt: Match by provider ID (YouTube ID)
  2. Second attempt: Match by file path

This ensures compatibility with videos that may have been added to Jellyfin through different methods.

## Requirements

- `bash`
- `curl`
- `jq`
- A running Jellyfin server
- jellyfin-mpv-shim setup locally
