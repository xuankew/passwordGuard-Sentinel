// 功能开关：Touch ID 解锁 UI。
//
// 现状隐藏的原因：Touch ID 依赖 macOS 数据保护钥匙串 + 生物识别 ACL，必须有
// keychain-access-groups entitlement；而免费 Apple Development 证书下该 entitlement
// 需要内嵌 provisioning profile（仅 Xcode 可为个人团队生成），否则要么 -34018
// 「A required entitlement isn't present」，要么被 AMFI 拒绝 Finder 拉起。
// 后端 src-tauri/src/touchid.rs 与相关命令完整保留，未受影响。
//
// 将来恢复：拿到 Developer ID（或解决 provisioning profile）后，把下面改回 true，
// 锁屏按钮与设置面板区块即自动回来，无需改其它代码。
export const TOUCH_ID_UI_ENABLED = false;
