---
name: spotify-control
description: Use when controlling Spotify playback on macOS via AppleScript - includes play, pause, next, previous, volume control, track information retrieval, and search/play by artist or song
---

# Spotify Control for macOS

## Overview

Control Spotify playback on macOS using AppleScript commands. This skill provides a standardized way to interact with Spotify when users request music playback.

## When to Use

- User asks to "play music" or "play Spotify"
- User wants to play specific artist or song (e.g., "播放周杰伦的歌")
- User wants to control playback (pause, next, previous)
- User requests volume adjustment
- User asks what's currently playing
- Spotify is installed and running on macOS

## Quick Reference

| Command | AppleScript |
|---------|-------------|
| Play | `osascript -e 'tell application "Spotify" to play'` |
| Pause | `osascript -e 'tell application "Spotify" to pause'` |
| Next Track | `osascript -e 'tell application "Spotify" to next track'` |
| Previous Track | `osascript -e 'tell application "Spotify" to previous track'` |
| Get Current Track | `osascript -e 'tell application "Spotify" to get name of current track'` |
| Get Player State | `osascript -e 'tell application "Spotify" to get player state'` |
| Set Volume (0-100) | `osascript -e 'tell application "Spotify" to set sound volume to 50'` |
| Search & Play Artist | `osascript -e 'tell application "Spotify" to play track "spotify:artist:[ID]"'` |
| Search & Play Song | `osascript -e 'tell application "Spotify" to play track "spotify:track:[ID]"'` |

## Response Format

When controlling Spotify, provide structured responses:

### Successful Playback Start
```
🎵 **Spotify 已开始播放！**

**当前播放：** [歌曲名] - [艺术家] ([专辑])

[可选：控制提示]
```

### Track Information
```
**当前播放：** [歌曲名] - [艺术家]
**专辑：** [专辑名]
**播放状态：** [播放/暂停]
**音量：** [音量百分比]%
```

### Search & Play Actions
```
🔍 **正在搜索：** [歌手/歌曲名]
🎵 **开始播放：** [歌曲名] - [艺术家]

[可选：播放列表信息]
```

### Control Actions
```
✅ [动作] 成功执行

**当前播放：** [歌曲名] - [艺术家]
```

## Implementation

### 1. Search and Play Functions

#### Search and Play by Artist (Simplified)
Since AppleScript doesn't have direct search API, we use known artist URIs:

```bash
# Common Chinese artist URIs (examples)
# 周杰伦: spotify:artist:2elBjNSdBE2Y3f0j1mjrql
# 林俊杰: spotify:artist:2YCyqYF1BIGC4ly6eL7L8v
# 陈奕迅: spotify:artist:7AjbQrB9dczfyyF2CGZ8lt

# Play Jay Chou (周杰伦)
osascript -e 'tell application "Spotify" to play track "spotify:artist:2elBjNSdBE2Y3f0j1mjrql"'
```

#### Play Popular Playlist
```bash
# Play artist's popular tracks playlist
osascript -e 'tell application "Spotify" to play track "spotify:playlist:37i9dQZF1DX0vHZ8elq0UK"'  # 周杰伦热门歌曲
```

### 2. Check Spotify Status
```bash
# Check if Spotify is installed
which spotify

# Check if Spotify is running
osascript -e 'application "Spotify" is running'
```

### 2. Control Playback
```bash
# Start playing
osascript -e 'tell application "Spotify" to play'

# Pause
osascript -e 'tell application "Spotify" to pause'

# Next track
osascript -e 'tell application "Spotify" to next track'

# Previous track
osascript -e 'tell application "Spotify" to previous track'
```

### 3. Get Track Information
```bash
# Get full track info
osascript -e 'tell application "Spotify"
  set trackName to name of current track
  set artistName to artist of current track
  set albumName to album of current track
  set playerState to player state
  set volumeLevel to sound volume
  return "正在播放: " & trackName & " - " & artistName & " (" & albumName & ")" & " | 状态: " & playerState & " | 音量: " & volumeLevel & "%"
end tell'
```

### 4. Volume Control
```bash
# Set volume (0-100)
osascript -e 'tell application "Spotify" to set sound volume to 75'

# Get current volume
osascript -e 'tell application "Spotify" to get sound volume'
```

## Common Issues

1. **Spotify not running** - Start Spotify first or ask user to open it
2. **No output from commands** - Some commands return no output on success
3. **Permission issues** - Ensure Terminal has accessibility permissions
4. **Spotify not installed** - Guide user to install Spotify first
5. **Artist/song not found** - URI may be incorrect or artist not on Spotify
6. **Search limitations** - AppleScript has limited search capabilities, may need manual setup

## Best Practices

1. **Always verify Spotify is running** before attempting control
2. **Provide immediate feedback** - confirm action was taken
3. **Include current track info** when relevant
4. **Offer next steps** - suggest other controls user might want
5. **Handle errors gracefully** - if command fails, explain why and suggest fixes

## Example Workflow

### Basic Playback Control
```bash
# 1. Check Spotify status
./spotify-control.sh status

# 2. Start playback
./spotify-control.sh play

# 3. Control playback
./spotify-control.sh pause
./spotify-control.sh next
./spotify-control.sh prev

# 4. Adjust volume
./spotify-control.sh volume 80
```

### Search and Play Specific Artist
```bash
# Search and play Jay Chou (周杰伦)
./spotify-control.sh search 周杰伦

# Or using English name
./spotify-control.sh search jaychou

# Check what's playing
./spotify-control.sh status
```

### Play Pre-configured Playlist
```bash
# Play Jay Chou's popular songs playlist
./spotify-control.sh playlist 周杰伦热门

# Or using English name
./spotify-control.sh playlist chinese_pop
```

### List Available Artists and Playlists
```bash
# Show all pre-configured artists and playlists
./spotify-control.sh artists

# Show help
./spotify-control.sh help
```

## Notes

- This skill is macOS-specific (relies on AppleScript)
- Requires Spotify desktop app to be installed
- User must grant Terminal accessibility permissions if prompted
- Commands may fail if Spotify is not running or logged in
- Search functionality requires pre-configured artist/song URIs
- For full search capabilities, use Spotify app directly or consider Spotify Web API integration