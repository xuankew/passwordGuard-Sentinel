#!/usr/bin/env bash
# 用免费 Apple Development 证书构建签名 .app —— Touch ID 生物识别钥匙串需要它。
#
# 为什么不能用自签（build-signed.sh）：数据保护钥匙串 + 生物识别 ACL
# 要求签名证书能连到 Apple 的受信根，自签证书会被拒（errSecMissingEntitlement /
# -34018）。免费 Apple ID 在 Xcode 里签发的 "Apple Development" 证书即可，无需 $99 计划。
#
# 前置（一次性）：
#   1. Xcode → Settings → Accounts → 登录 Apple ID → Manage Certificates → "+" → Apple Development
#   2. 若 `security find-identity -v -p codesigning` 里该证书显示 CSSMERR_TP_NOT_TRUSTED，
#      说明缺 WWDR G3 中间证书，安装一次即可：
#        curl -fsSLo /tmp/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
#        security add-certificates -k ~/Library/Keychains/login.keychain-db /tmp/AppleWWDRCAG3.cer
#
# 产物：安装到 /Applications/Sentinel.app（并清理 target 下的构建副本，
# 避免 Spotlight 搜出多个同名图标）。只替换二进制，不触碰应用数据/保险库。
set -euo pipefail
cd "$(dirname "$0")/.."

# 允许用环境变量覆盖；默认自动探测已安装的 Apple Development 身份。
IDENTITY="${APPLE_SIGNING_IDENTITY:-}"
if [[ -z "$IDENTITY" ]]; then
  IDENTITY="$(security find-identity -v -p codesigning \
    | grep -o '"Apple Development: [^"]*"' | head -1 | tr -d '"')"
fi
if [[ -z "$IDENTITY" ]]; then
  echo "未找到 Apple Development 签名身份。请按脚本顶部前置步骤在 Xcode 中创建证书。"
  exit 1
fi

echo "使用签名身份：$IDENTITY"

# 不写 keychain-access-groups 显式 entitlement：
# 该 entitlement 在 Apple Development 证书下要求内嵌 provisioning profile（仅 Xcode
# 能为免费个人团队生成），否则 AMFI 拒绝 LaunchServices 拉起（error 163，双击打不开）。
# 而只要用带 Team ID 的证书签名，系统会自动分配默认钥匙串访问组
# <TeamID>.<bundleID>，数据保护钥匙串 + 生物识别 ACL（Touch ID）即可工作。
export APPLE_SIGNING_IDENTITY="$IDENTITY"
pnpm tauri build --bundles app "$@"

# 安装到 /Applications 并清掉 target 下的构建副本，保证 Spotlight 只索引一个 Sentinel。
# 优先 release 包；仅当传入 --debug 时才用 debug 包。
if [[ -d src-tauri/target/release/bundle/macos/Sentinel.app ]]; then
  BUNDLE="src-tauri/target/release/bundle/macos/Sentinel.app"
else
  BUNDLE="src-tauri/target/debug/bundle/macos/Sentinel.app"
fi
if [[ ! -d "$BUNDLE" ]]; then
  echo "未找到构建产物 .app，跳过安装。"
  exit 1
fi

osascript -e 'quit app "Sentinel"' 2>/dev/null || true
sleep 1
rm -rf /Applications/Sentinel.app
cp -R "$BUNDLE" /Applications/
rm -rf src-tauri/target/release/bundle/macos/Sentinel.app \
       src-tauri/target/debug/bundle/macos/Sentinel.app
echo "已安装到 /Applications/Sentinel.app（target 构建副本已清理）"
