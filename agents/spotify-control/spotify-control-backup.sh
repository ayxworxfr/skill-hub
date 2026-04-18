#!/bin/bash

# Spotify Control Script for macOS
# Usage: ./spotify-control.sh [command] [value]

COMMAND="${1:-status}"
VALUE="${2:-}"

# Common artist URIs (Spotify IDs)
# Using English keys for compatibility
declare -A ARTIST_URIS=(
    [jaychou]="spotify:artist:2elBjNSdBE2Y3f0j1mjrql"      # 周杰伦
    [jjlin]="spotify:artist:2YCyqYF1BIGC4ly6eL7L8v"        # 林俊杰
    [easonchan]="spotify:artist:7AjbQrB9dczfyyF2CGZ8lt"    # 陈奕迅
    [mayday]="spotify:artist:2QaB2QUbdlqNQc1C8b0u8x"       # 五月天
    [hebetien]="spotify:artist:2ZR7f7Kc8e7h9q3c0p8Q5J"     # 田馥甄
)

# Artist name mapping (Chinese to English key)
declare -A ARTIST_MAP=(
    [周杰伦]=jaychou
    [林俊杰]=jjlin
    [陈奕迅]=easonchan
    [五月天]=mayday
    [田馥甄]=hebetien
)

# Popular playlists
declare -A PLAYLIST_URIS=(
    [jaychou_top]="spotify:playlist:37i9dQZF1DX0vHZ8elq0UK"      # 周杰伦热门
    [chinese_pop]="spotify:playlist:37i9dQZF1DX0vHZ8elq0UK"     # 中文流行
)

# Playlist name mapping
declare -A PLAYLIST_MAP=(
    [周杰伦热门]=jaychou_top
    [中文流行]=chinese_pop
)

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
            # Map Chinese name to English key if needed
            ARTIST_KEY="$VALUE"
            if [[ -n "${ARTIST_MAP[$VALUE]}" ]]; then
                ARTIST_KEY="${ARTIST_MAP[$VALUE]}"
                echo "🔍 搜索艺术家: $VALUE ($ARTIST_KEY)"
            else
                echo "🔍 搜索艺术家: $VALUE"
            fi
            
            # Check if it's a known artist
            if [[ -n "${ARTIST_URIS[$ARTIST_KEY]}" ]]; then
                osascript -e "tell application \"Spotify\" to play track \"${ARTIST_URIS[$ARTIST_KEY]}\"" 2>/dev/null
                sleep 2  # Wait for playback to start
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
                echo "   2. 使用已知艺术家:"
                for key in "${!ARTIST_MAP[@]}"; do
                    echo "     - $key"
                done
                echo "   3. 联系管理员添加 $VALUE 到艺术家列表"
            fi
        elif [ -z "$VALUE" ]; then
            echo "❌ 请提供搜索内容，例如: $0 search 周杰伦"
            echo "   可用艺术家:"
            for key in "${!ARTIST_MAP[@]}"; do
                echo "     - $key"
            done
        fi
        ;;
        
    playlist)
        check_spotify
        if [ $? -eq 0 ] && [ -n "$VALUE" ]; then
            # Map Chinese name to English key if needed
            PLAYLIST_KEY="$VALUE"
            if [[ -n "${PLAYLIST_MAP[$VALUE]}" ]]; then
                PLAYLIST_KEY="${PLAYLIST_MAP[$VALUE]}"
                echo "📋 播放列表: $VALUE ($PLAYLIST_KEY)"
            else
                echo "📋 播放列表: $VALUE"
            fi
            
            if [[ -n "${PLAYLIST_URIS[$PLAYLIST_KEY]}" ]]; then
                osascript -e "tell application \"Spotify\" to play track \"${PLAYLIST_URIS[$PLAYLIST_KEY]}\"" 2>/dev/null
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
                for key in "${!PLAYLIST_MAP[@]}"; do
                    echo "  - $key"
                done
            fi
        elif [ -z "$VALUE" ]; then
            echo "📋 可用播放列表:"
            for key in "${!PLAYLIST_MAP[@]}"; do
                echo "  - $key"
            done
        fi
        ;;
        
    artists)
        echo "🎤 预配置艺术家 (中文 → 英文键):"
        for chinese_key in "${!ARTIST_MAP[@]}"; do
            english_key="${ARTIST_MAP[$chinese_key]}"
            echo "  - $chinese_key → $english_key"
        done
        echo ""
        echo "📋 预配置播放列表 (中文 → 英文键):"
        for chinese_key in "${!PLAYLIST_MAP[@]}"; do
            english_key="${PLAYLIST_MAP[$chinese_key]}"
            echo "  - $chinese_key → $english_key"
        done
        ;;
        
    help|--help|-h)
        echo "Spotify 控制脚本"
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
        echo "  artists          显示预配置艺术家列表"
        echo "  help             显示此帮助信息"
        echo ""
        echo "示例:"
        echo "  $0 search 周杰伦"
        echo "  $0 playlist 周杰伦热门"
        echo "  $0 volume 80"
        ;;
        
    *)
        echo "❌ 未知命令: $COMMAND"
        echo "使用 '$0 help' 查看可用命令"
        ;;
esac