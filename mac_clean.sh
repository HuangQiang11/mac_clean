#!/bin/bash

echo "🧹 开始清理 macOS 系统和 Xcode 无用文件..."

USER_DIR=$HOME

# 获取磁盘占用（清理前）
BEFORE=$(df -h / | tail -1 | awk '{print $4}')
echo "💾 清理前剩余磁盘空间: $BEFORE"

# ---------------------------
# 定义常规清理路径（无需空格处理）
# ---------------------------
CLEAN_PATHS=(
    # 系统缓存 & 日志
    "$USER_DIR/Library/Caches/*"
    "/Library/Caches/*"
    "$USER_DIR/Library/Logs/*"
    "/Library/Logs/*"
    "$USER_DIR/Library/Application Support/CrashReporter/*"
    "$USER_DIR/Library/Developer/CoreSimulator/Caches/*"
    "$USER_DIR/Library/Containers/com.apple.mail/Data/Library/Mail Downloads/*"
    "$USER_DIR/Library/Application Support/MobileSync/Backup/*"

    # Xcode 可立即清理的目录
    "$USER_DIR/Library/Developer/Xcode/DerivedData/*"
    "$USER_DIR/Library/Caches/com.apple.dt.Xcode/*"
    "$USER_DIR/Library/Logs/DiagnosticReports/*"
    "$USER_DIR/Library/Developer/Xcode/Archives/*"
)

# 清理函数
clean_path() {
    local path=$1
    if ls "$path" &> /dev/null 2>/dev/null; then
        echo "🗑 清理: $path"
        rm -rf "$path"
    fi
}

# 执行常规清理
for path in "${CLEAN_PATHS[@]}"; do
    clean_path "$path"
done

# ---------------------------
# 微信 MessageTemp 清理（单独处理空格路径）
# ---------------------------
WECHAT_TEMP="$USER_DIR/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/2.0b4.0.9/cb9f8c4241ad4741d0a5a15036ea1f62/Message/MessageTemp"

if [ -d "$WECHAT_TEMP" ]; then
    echo "⚠️ 请确保微信已退出，否则 MessageTemp 文件无法清理"
    read -p "❓ 是否清理微信 MessageTemp？[y/N]: " del
    case "$del" in
        y|Y )
            echo "🗑 清理微信 MessageTemp..."
            rm -rf "$WECHAT_TEMP"/*
            echo "✅ 微信 MessageTemp 已清理完成"
            ;;
        * )
            echo "⏭ 跳过清理微信 MessageTemp"
            ;;
    esac
fi


# ---------------------------
# 清理钉钉缓存
# ---------------------------
DINGTALK_PATHS=(
"$USER_DIR/Library/Application Support/DingTalkMac/228534577_v2/EAppFiles/download"
"$USER_DIR/Library/Application Support/DingTalkMac/228534577_v2/EAppFiles/unziped"
"$USER_DIR/Library/Application Support/DingTalkMac/228534577_v2/resource_cache"
)

for path in "${DINGTALK_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "🗑 清理钉钉缓存: $path"
        rm -rf "$path"/*
    fi
done

# ---------------------------
# 交互：选择性清理 iOS DeviceSupport
# ---------------------------
DEVICE_SUPPORT_DIR="$USER_DIR/Library/Developer/Xcode/iOS DeviceSupport"
if [ -d "$DEVICE_SUPPORT_DIR" ]; then
    echo "📂 检测到 iOS DeviceSupport 目录: $DEVICE_SUPPORT_DIR"
    echo "其中包含以下 iOS 版本符号文件："
    ls "$DEVICE_SUPPORT_DIR"
    echo
    read -p "❓ 是否要选择性删除其中的某些 iOS 版本？[y/N]: " choice
    case "$choice" in
      y|Y )
        for version in "$DEVICE_SUPPORT_DIR"/*; do
            [ -d "$version" ] || continue
            ver_name=$(basename "$version")
            size=$(du -sh "$version" | awk '{print $1}')
            read -p "🗑 删除 $ver_name (大小: $size)? [y/N]: " del_choice
            case "$del_choice" in
              y|Y )
                rm -rf "$version"
                echo "✅ 已删除 $ver_name"
                ;;
              * )
                echo "⏭ 保留 $ver_name"
                ;;
            esac
        done
        ;;
      * )
        echo "⏭ 跳过清理 iOS DeviceSupport"
        ;;
    esac
fi

# ---------------------------
# 删除 Time Machine 本地快照
# ---------------------------
if command -v tmutil &> /dev/null; then
    echo "⌛ 检查 Time Machine 快照..."
    SNAPSHOTS=$(tmutil listlocalsnapshots / | awk -F. '{print $4}')
    for s in $SNAPSHOTS; do
        echo "🗑 删除本地快照: $s"
        sudo tmutil deletelocalsnapshots $s
    done
fi

# ---------------------------
# 重建 Spotlight 索引
# ---------------------------
echo "🔄 重建 Spotlight 索引..."
sudo mdutil -E / > /dev/null

# 获取磁盘占用（清理后）
AFTER=$(df -h / | tail -1 | awk '{print $4}')
echo "💾 清理后剩余磁盘空间: $AFTER"

echo "✅ 清理完成！建议重启电脑以释放缓存。"
