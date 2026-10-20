<div align="center">

# 🛡️ Sentinel（哨兵）

**你的密钥，寸步不让。**

零知识、可离线、通过你自己的 GitHub 私有仓库同步的 **macOS 本地密码管理器**。

主密码派生密钥加密整库，云端只存密文——即使设备或仓库文件被盗，没有主密码也读不出任何一个字。

[![License: MIT](https://img.shields.io/badge/License-MIT-accent.svg)](LICENSE)
[![Tauri](https://img.shields.io/badge/Tauri-2-24C8DB?logo=tauri)](https://tauri.app/)
[![SolidJS](https://img.shields.io/badge/SolidJS-1.9-4F88C6?logo=solid)](https://www.solidjs.com/)
[![Platform](https://img.shields.io/badge/platform-macOS-000?logo=apple)](#)

</div>

---

## ✨ 功能特性

- **三类条目**：登录密码、API Key、安全笔记，统一搜索（含笔记正文与备注）。
- **标签筛选**：侧栏按标签聚合计数、一键过滤，与视图/类型筛选互斥高亮。
- **一键复制**：用户名、密码、验证码均可复制；敏感内容按设置自动清除剪贴板。
- **强密码生成**：内置随机强密码 / 密钥生成器，前端 `crypto.getRandomValues`。
- **TOTP 两步验证**：粘贴 Base32 / `otpauth://` 链接，或**扫描二维码图片**自动填入；实时 6 位验证码 + 倒计时环。
- **剪贴板自动清除**：复制敏感内容后 10/30/60 秒自动擦除，或设为「从不」。
- **零知识加密**：整库单文件加密落盘，主密码永不存储、永不上传。
- **GitHub 私有仓库同步**：多台 Mac 间同步密文，三方合并 + 冲突可视化裁决。
- **自动 / 手动同步**：可设 5/15/30/60 分钟自动同步，列表栏一键手动同步，侧栏显示上次同步时间。
- **同步历史**：本地记录最近 50 次同步结果（成功 / 已最新 / 冲突 / 失败），设置面板可查。
- **CSV 导入**：支持 Chrome / 1Password / 通用格式一键迁入，自动去重。
- **空闲自动锁定**：无操作超时自动锁库。
- **加密导出 / 备份**：用独立导出密码重新封盘导出 `.sentinel`，**绝不导出明文**。
- **修改主密码**：设置内改主密码并整库重加密。
- **恢复提示语**：本地明文存一句「给主人看的提示」，防忘主密码；不加密、不上云。
- **全局快捷键**：常用操作键盘直达。
- **外观微调**：强调色 + 紧凑/舒适密度。

> **Touch ID 解锁**：代码与后端完整保留，但**当前默认隐藏**（见下文「Touch ID 现状」）。

## 🔐 安全模型

| 环节 | 方案 |
| --- | --- |
| 密钥派生 | **Argon2id**（64 MiB 内存 / 3 迭代 / 1 并行度，V0x13） |
| 认证加密 | **XChaCha20-Poly1305**（256-bit 密钥，24 字节随机 nonce） |
| 完整性 | 文件头（含参数、盐）作为 **AAD** 参与认证，参数/盐/密文被篡改即解密失败 |
| 内存卫生 | 主密码、明文密钥使用 `Zeroizing` 用后清零 |
| 同步凭据 | GitHub Token 存 **macOS 钥匙串**（Keychain），绝不写入仓库或库文件 |
| 剪贴板 | 复制敏感字段后按设置定时清空系统剪贴板 |
| Touch ID | 主密码存 `kSecAccessControlBiometryCurrentSet` 的**数据保护钥匙串**项（当前 UI 隐藏） |

> **零知识**：Sentinel 不知道也无法知道你的主密码。加密/解密全部在本机完成，GitHub 上只存放密文。丢失主密码 = 数据无法恢复，请务必牢记并自行备份。

## 🚀 快速开始

### 前置要求

- macOS（Apple Silicon 或 Intel）
- [Rust](https://rustup.rs/)
- Node.js 20+ 与 [pnpm](https://pnpm.io/)
- Xcode Command Line Tools：`xcode-select --install`

### 从源码运行

```bash
pnpm install          # 安装依赖
pnpm tauri dev        # 开发模式（热重载，ad-hoc 签名）
pnpm tauri build      # 打包 .app / .dmg
```

其他常用命令：

```bash
pnpm dev                 # 仅启动前端 Vite 开发服务器
pnpm build               # 仅构建前端到 dist/
cd src-tauri && cargo test   # 运行 Rust 加密 / 合并 / 导入单测
npx tsc --noEmit         # 前端类型检查
```

### 签名与安装（自用）

macOS 上钥匙串行为强依赖代码签名身份，仓库提供两条打包路径：

| 脚本 | 签名身份 | 适用 |
| --- | --- | --- |
| `scripts/build-signed.sh` | 本地**自签**证书（`setup-signing.sh` 一次性生成） | 稳定签名、钥匙串 ACL 一次授权不再频繁弹窗；**无 Touch ID** |
| `scripts/build-apple.sh` | 免费 **Apple Development** 证书（Xcode 签发） | 带 Team ID 的真实签名；自动安装到 `/Applications` 并清理构建副本 |

```bash
# 自签路径
scripts/setup-signing.sh   # 一次性：自签证书 → 独立钥匙串 → .env.signing（已 gitignore）
scripts/build-signed.sh    # 构建签名 .app

# Apple 证书路径（推荐自用）
scripts/build-apple.sh     # 构建 + 签名 + 安装 /Applications + 清理 target 副本
```

> `build-apple.sh` 会自动探测已安装的 `Apple Development` 身份；若 `security find-identity -v -p codesigning` 显示该证书 `CSSMERR_TP_NOT_TRUSTED`，说明缺 Apple 中间证书，安装一次即可：
> `curl -fsSLo /tmp/AppleWWDRCAG3.cer https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer && security add-certificates -k ~/Library/Keychains/login.keychain-db /tmp/AppleWWDRCAG3.cer`

自签 / Apple 免费证书均**不用于对外分发**（过不了 Gatekeeper 公证）。普通 `pnpm tauri build` 仍可构建（仅无稳定签名）。

### Touch ID 现状（重要）

Touch ID 依赖 macOS **数据保护钥匙串 + 生物识别 ACL**，这要求应用带有 `keychain-access-groups` entitlement。而在**免费 Apple Development 证书**下，该 entitlement 必须配**内嵌 provisioning profile**（仅 Xcode 可为个人团队生成），否则要么报 `-34018 A required entitlement isn't present`，要么被 AMFI 拒绝从 Finder 拉起。自签证书没有 Team ID，同样无法满足。

因此 Touch ID 的**前端 UI 当前默认隐藏**（开关在 `src/lib/features.ts` 的 `TOUCH_ID_UI_ENABLED`），后端 `touchid.rs` 与 IPC 命令完整保留。将来拿到 Developer ID（或解决 provisioning profile）后，把开关改回 `true` 即可恢复锁屏按钮与设置区块，无需改其它代码。跨设备使用时，Touch ID 凭据按机器存储，每台 Mac 需各自启用；未启用时一律走主密码解锁。

## 🔄 配置 GitHub 同步

同步走你自己的私有仓库，Sentinel 不会替你创建任何远端资源。

1. **建一个私有仓库**（例如 `my-vault`），无需初始化任何文件。
2. **签发 Fine-grained Personal Access Token**：
   - GitHub → Settings → Developer settings → Fine-grained tokens → Generate new token。
   - **Repository access**：选 *Only select repositories*，勾选上面那个仓库。
   - **Permissions → Repository permissions → Contents**：设为 **Read and write**（Metadata 自动带上、只读即可）。
   - 其余权限一律不授予。
3. 在 Sentinel 侧栏点 **配置同步**，填入 Owner、仓库名、分支（默认 `main`）、文件路径（默认 `vault.sentinel`）与 Token，点 **测试连接** 通过后 **立即同步**。

Token 写入 macOS 钥匙串（service `com.sentinel.app`），不入库、不上云。

## 🗂️ 项目结构

```
src/                     前端（SolidJS + TypeScript）
  components/            三栏界面、编辑器、同步/设置面板、冲突裁决
  lib/api.ts             前端调用后端命令的封装层
  lib/features.ts        功能开关（如 Touch ID UI）
  styles/vault.css       设计系统
src-tauri/src/           后端（Rust）
  crypto.rs              Argon2id + XChaCha20-Poly1305 加密内核
  vault.rs               .sentinel 文件格式与保险库持久化
  merge.rs               三方合并引擎
  sync.rs                GitHub Contents API 传输
  import.rs              CSV 导入解析与去重
  touchid.rs             生物识别门禁钥匙串
  commands.rs            Tauri IPC 命令
scripts/                 自签 / Apple 证书打包脚本
docs/                    产品文档（PRD.md）与 UI 交互稿
```

- 产品文档：[`docs/PRD.md`](docs/PRD.md)
- UI 交互稿：[`docs/ui-mockup.html`](docs/ui-mockup.html)（浏览器直接打开）

## 🧭 路线图

- [x] **M0** 脚手架：Tauri 2 + SolidJS + Vite，品牌外壳与前后端 IPC 通路
- [x] **M1** 加密内核 + 保险库创建/解锁/锁定（Argon2id + XChaCha20-Poly1305，密文落盘）
- [x] **M2** 主界面三栏 + 条目 CRUD + 搜索 + 一键复制（自动清除）+ TOTP 实时验证码
- [x] **M3** GitHub 同步 + 三方合并 + 冲突裁决（私有仓库密文同步，Keychain 存 Token）
- [x] **M4** Touch ID 后端 / 空闲自动锁定 / 强调色与密度 / 加密导出 / 修改主密码
- [x] **M5** 自动 + 手动同步 / 侧栏上次同步时间 / 同步历史
- [x] **打磨**：全局快捷键、恢复提示语、剪贴板清除可配、备注字段、标签筛选、CSV 导入、TOTP 二维码识别、动效
- [ ] **Touch ID 前端恢复**：待 Developer ID / provisioning profile 解决签名约束
- [ ] 对外分发：Developer ID 签名 + 公证

## ⚠️ 免责声明

Sentinel 是个人开源项目，**尚未经过第三方安全审计**。请自行评估风险后使用，并务必牢记主密码、定期备份加密文件。因使用本软件造成的任何数据丢失或安全问题，作者不承担责任。

## 📄 License

[MIT](LICENSE) © 2026 Sentinel Contributors
