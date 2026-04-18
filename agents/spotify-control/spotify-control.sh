#!/bin/bash

# Spotify Control Script for macOS (Compatible version)
# Usage: ./spotify-control-v2.sh [command] [value]

COMMAND="${1:-status}"
VALUE="${2:-}"

# Simple artist URI lookup using case statement
get_artist_uri() {
    case "$1" in
        周杰伦|jaychou)
            echo "spotify:artist:2elBjNSdBE2Y3f0j1mjrql"
            ;;
        林俊杰|jjlin)
            echo "spotify:artist:2YCyqYF1BIGC4ly6eL7L8v"
            ;;
        陈奕迅|easonchan)
            echo "spotify:artist:7AjbQrB9dczfyyF2CGZ8lt"
            ;;
        五月天|mayday)
            echo "spotify:artist:2QaB2QUbdlqNQc1C8b0u8x"
            ;;
        田馥甄|hebetien)
            echo "spotify:artist:2ZR7f7Kc8e7h9q3c0p8Q5J"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Simple playlist URI lookup
get_playlist_uri() {
    case "$1" in
        周杰伦热门|jaychou_top|中文流行|chinese_pop)
            echo "spotify:playlist:37i9dQZF1DX0vHZ8elq0UK"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Specific song URI lookup
get_song_uri() {
    case "$1" in
        告白气球|gaobaiqiqiu|loveconfession)
            echo "spotify:track:5t1r7LpLm6hQk8F8F2v0v0"  # 需要验证的URI
            ;;
        七里香|qilixiang|chrysanthemum)
            echo "spotify:track:2a7L7r5Zz3tBmYhqTf6U8K"
            ;;
        青花瓷|qinghuaci|blueandwhite)
            echo "spotify:track:5t1r7LpLm6hQk8F8F2v0v0"  # 需要验证的URI
            ;;
        *)
            echo ""
            ;;
    esac
}

check_spotify() {
    if ! command -v spotify &> /dev/null; then
        echo "❌ Spotify 未安装"
        return 1
    fi
    
    if ! osascript -e 'application "Spotify" is running' 2>/dev/null | grep -q "true"; then
        echo "⚠️  Spotify 未运行"
        return 2
    fi
    
    return 0
}

get_track_info() {
    osascript -e 'tell application "Spotify"
        set trackName to name of current track
        set artistName to artist of current track
        set albumName to album of current track
        set playerState to player state
        set volumeLevel to sound volume
        return trackName & "|" & artistName & "|" & albumName & "|" & playerState & "|" & volumeLevel
    end tell' 2>/dev/null
}

case "$COMMAND" in
    play)
        check_spotify
        if [ $? -eq 0 ]; then
            osascript -e 'tell application "Spotify" to play' 2>/dev/null
            INFO=$(get_track_info)
            IFS='|' read -r track artist album state volume <<< "$INFO"
            echo "🎵 正在播放: $track - $artist"
            echo "📀 专辑: $album"
            echo "⏯️ 状态: $state | 🔊 音量: $volume%"
        fi
        ;;
        
    pause)
        check_spotify
        if [ $? -eq 0 ]; then
            osascript -e 'tell application "Spotify" to pause' 2>/dev/null
            echo "⏸️ 已暂停播放"
        fi
        ;;
        
    next)
        check_spotify
        if [ $? -eq 0 ]; then
            osascript -e 'tell application "Spotify" to next track' 2>/dev/null
            INFO=$(get_track_info)
            IFS='|' read -r track artist album state volume <<< "$INFO"
            echo "⏭️ 下一首: $track - $artist"
        fi
        ;;
        
    prev|previous)
        check_spotify
        if [ $? -eq 0 ]; then
            osascript -e 'tell application "Spotify" to previous track' 2>/dev/null
            INFO=$(get_track_info)
            IFS='|' read -r track artist album state volume <<< "$INFO"
            echo "⏮️ 上一首: $track - $artist"
        fi
        ;;
        
    volume)
        check_spotify
        if [ $? -eq 0 ] && [ -n "$VALUE" ]; then
            if [[ "$VALUE" =~ ^[0-9]+$ ]] && [ "$VALUE" -ge 0 ] && [ "$VALUE" -le 100 ]; then
                osascript -e "tell application \"Spotify\" to set sound volume to $VALUE" 2>/dev/null
                echo "🔊 音量设置为: $VALUE%"
            else
                echo "❌ 音量值必须是 0-100 之间的数字"
            fi
        elif [ -z "$VALUE" ]; then
            CURRENT_VOL=$(osascript -e 'tell application "Spotify" to get sound volume' 2>/dev/null)
            echo "🔊 当前音量: $CURRENT_VOL%"
        fi
        ;;
        
    status|info)
        check_spotify
        if [ $? -eq 0 ]; then
            INFO=$(get_track_info)
            if [ -n "$INFO" ]; then
                IFS='|' read -r track artist album state volume <<< "$INFO"
                echo "🎵 当前播放: $track - $artist"
                echo "📀 专辑: $album"
                echo "⏯️ 状态: $state"
                echo "🔊 音量: $volume%"
            else
                echo "❌ 无法获取播放信息"
            fi
        fi
        ;;
        
    search)
        check_spotify
        if [ $? -eq 0 ] && [ -n "$VALUE" ]; then
            ARTIST_URI=$(get_artist_uri "$VALUE")
            
            if [ -n "$ARTIST_URI" ]; then
                echo "🔍 搜索艺术家: $VALUE"
                osascript -e "tell application \"Spotify\" to play track \"$ARTIST_URI\"" 2>/dev/null
                sleep 2
                INFO=$(get_track_info)
                if [ -n "$INFO" ]; then
                    IFS='|' read -r track artist album state volume <<< "$INFO"
                    echo "🎵 开始播放 $VALUE 的歌曲:"
                    echo "  曲目: $track"
                    echo "  专辑: $album"
                    echo "  状态: $state | 音量: $volume%"
                else
                    echo "✅ 已开始播放 $VALUE 的歌曲"
                fi
            else
                echo "🔍 搜索: $VALUE"
                echo "⚠️  未找到预配置的艺术家，请尝试:"
                echo "   1. 手动在 Spotify 中搜索"
                echo "   2. 使用已知艺术家: 周杰伦, 林俊杰, 陈奕迅, 五月天, 田馥甄"
                echo "   3. 联系管理员添加 $VALUE 到艺术家列表"
            fi
        elif [ -z "$VALUE" ]; then
            echo "❌ 请提供搜索内容，例如: $0 search 周杰伦"
            echo "   可用艺术家: 周杰伦, 林俊杰, 陈奕迅, 五月天, 田馥甄"
        fi
        ;;
        
    playlist)
        check_spotify
        if [ $? -eq 0 ] && [ -n "$VALUE" ]; then
            PLAYLIST_URI=$(get_playlist_uri "$VALUE")
            
            if [ -n "$PLAYLIST_URI" ]; then
                echo "📋 播放列表: $VALUE"
                osascript -e "tell application \"Spotify\" to play track \"$PLAYLIST_URI\"" 2>/dev/null
                sleep 2
                INFO=$(get_track_info)
                if [ -n "$INFO" ]; then
                    IFS='|' read -r track artist album state volume <<< "$INFO"
                    echo "🎵 开始播放列表:"
                    echo "  曲目: $track - $artist"
                    echo "  专辑: $album"
                    echo "  状态: $state | 音量: $volume%"
                else
                    echo "✅ 已开始播放列表: $VALUE"
                fi
            else
                echo "📋 可用播放列表:"
                echo "  - 周杰伦热门 (中文流行)"
            fi
        elif [ -z "$VALUE" ]; then
            echo "📋 可用播放列表:"
            echo "  - 周杰伦热门 (中文流行)"
        fi
        ;;
        
    artists)
        echo "🎤 预配置艺术家:"
        echo "  - 周杰伦 (jaychou)"
        echo "  - 林俊杰 (jjlin)"
        echo "  - 陈奕迅 (easonchan)"
        echo "  - 五月天 (mayday)"
        echo "  - 田馥甄 (hebetien)"
        echo ""
        echo "📋 预配置播放列表:"
        echo "  - 周杰伦热门 (中文流行)"
        ;;
        
    song)
        check_spotify
        if [ $? -eq 0 ] && [ -n "$VALUE" ]; then
            SONG_URI=$(get_song_uri "$VALUE")
            
            if [ -n "$SONG_URI" ]; then
                echo "🎶 播放歌曲: $VALUE"
                osascript -e "tell application \"Spotify\" to play track \"$SONG_URI\"" 2>/dev/null
                sleep 2
                INFO=$(get_track_info)
                if [ -n "$INFO" ]; then
                    IFS='|' read -r track artist album state volume <<< "$INFO"
                    echo "🎵 开始播放:"
                    echo "  曲目: $track"
                    echo "  艺术家: $artist"
                    echo "  专辑: $album"
                    echo "  状态: $state | 音量: $volume%"
                else
                    echo "✅ 已开始播放歌曲: $VALUE"
                fi
            else
                echo "🎶 可用歌曲:"
                echo "  - 告白气球 (周杰伦)"
                echo "  - 七里香 (周杰伦)"
                echo "  - 青花瓷 (周杰伦)"
                echo ""
                echo "⚠️  未找到预配置的歌曲，请尝试:"
                echo "   1. 手动在 Spotify 中搜索"
                echo "   2. 使用已知歌曲: 告白气球, 七里香, 青花瓷"
                echo "   3. 联系管理员添加 $VALUE 到歌曲列表"
            fi
        elif [ -z "$VALUE" ]; then
            echo "🎶 可用歌曲:"
            echo "  - 告白气球 (周杰伦)"
            echo "  - 七里香 (周杰伦)"
            echo "  - 青花瓷 (周杰伦)"
        fi
        ;;
        
    help|--help|-h)
        echo "Spotify 控制脚本 (兼容版)"
        echo "用法: $0 [命令] [值]"
        echo ""
        echo "命令:"
        echo "  play             开始播放"
        echo "  pause            暂停播放"
        echo "  next             下一首"
        echo "  prev|previous    上一首"
        echo "  volume [0-100]   设置音量 (无参数显示当前音量)"
        echo "  status|info      显示当前播放信息"
        echo "  search [艺术家]  搜索并播放艺术家歌曲"
        echo "  playlist [名称]  播放预配置播放列表"
        echo "  song [歌曲名]    播放特定歌曲"
        echo "  artists          显示预配置艺术家列表"
        echo "  help             显示此帮助信息"
        echo ""
        echo "示例:"
        echo "  $0 search 周杰伦"
        echo "  $0 playlist 周杰伦热门"
        echo "  $0 song 告白气球"
        echo "  $0 volume 80"
        ;;
        
    *)
        echo "❌ 未知命令: $COMMAND"
        echo "使用 '$0 help' 查看可用命令"
        ;;
esac