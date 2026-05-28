# IntimacyCards 情趣抽卡

> 一款面向 18+ 热恋情侣的单机情趣抽卡 App。  
> 暗夜烛影风 · 跨平台 · 纯本地存储 · 含对战与功能卡机制。

---

## 项目状态

- **当前阶段**: MVP 开发中 · 单人抽卡闭环已打通（含完成日记）
- **技术栈**: Flutter 3.22+ · Riverpod · go_router · sqflite · flutter_secure_storage
- **目标平台**: Android + iOS
- **预计 MVP 周期**: 4–6 周

### 进度速览

| 模块 | 状态 |
|---|---|
| 启动密码 / 首次引导（昵称 + 头像 + 纪念日 + 舒适度 + PIN） | ✅ |
| 主页（亲密度条 / 在一起天数 / 身份切换 / 导航 Tile） | ✅ |
| 等级选择（Lv.1–3 + Lv.4 同意书 + Lv.4 独立 PIN） | ✅ |
| 抽卡蓄力（呼吸光晕 + 保底进度条，pity 跨会话持久化） | ✅ |
| 抽卡引擎（等级权重 + 10% 功能卡 + 十连保底 + 舒适度过滤 + 近 10 抽去重） | ✅ |
| 翻牌弹层（伪翻牌过渡 + 稀有度爆发 + 粒子 / 光柱 / shimmer / 流光边框） | ✅ |
| **完成日记**（心情 + 备注弹层，按日期分组列表 + 长按删除） | ✅ |
| 图鉴（收集进度 + 未收集"？？？"，仅按完成计数） | ✅ |
| **功能卡 10 张真实效果**（跳过 / 重抽 / 升降级 / 反转 / 镜像 / 加注 / 心愿 / 时光） | ✅ |
| 对战模式（石头剪刀布 / 色子 / 翻硬币） | ⏳ |
| 自制卡片编辑器 | ⏳ |
| 加密 JSON 导入 / 导出备份 | ⏳ |
| 真 3D 翻牌（已用 2D 透视 + 粒子 / 光柱替代，按需可升级 Rive） | ⏳ |

---

## 环境要求

| 依赖 | 版本 |
|---|---|
| Flutter SDK | `>= 3.22.0` |
| Dart SDK | `^3.4.0` |
| Android | Android Studio + Android SDK 34，最低 API 21 (Android 5.0) |
| iOS | Xcode 15+，最低 iOS 12（仅 macOS 可构建） |

先用 `flutter doctor` 确认环境无缺失项后再继续。

---

## 安装

```bash
git clone <your-repo-url> IntimacyCards
cd IntimacyCards

flutter pub get
```

> 首次拉取依赖较慢可设置国内镜像：
>
> ```bash
> # Windows PowerShell
> $env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
> $env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
>
> # macOS / Linux
> export PUB_HOSTED_URL=https://pub.flutter-io.cn
> export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
> ```

可选资源准备：

- 字体：将 `NotoSerifSC-Regular.ttf` / `NotoSerifSC-Bold.ttf` 放入 `assets/fonts/`
- 卡片数据：`data/cards.json` 复制或软链到 `assets/data/cards.json`
- 头像 / 音效：分别放入 `assets/images/avatars/`、`assets/sounds/`

---

## 运行

```bash
flutter devices                  # 查看可用设备
flutter run                      # 在默认设备上运行（debug）
flutter run -d <deviceId>        # 指定设备
flutter run --release            # 性能模式，体验真实动效与帧率
```

常用辅助命令：

```bash
flutter analyze                  # 静态分析
dart format .                    # 代码格式化
flutter test                     # 运行单元 / Widget 测试
flutter clean                    # 清理构建缓存
```

---

## 构建发布包

```bash
# Android APK（分架构产物体积更小）
flutter build apk --release --split-per-abi

# Android App Bundle（Google Play 上架）
flutter build appbundle --release

# iOS（需在 macOS + Xcode 环境）
flutter build ios --release
```

产物路径：

- APK: `build/app/outputs/flutter-apk/`
- AAB: `build/app/outputs/bundle/release/`
- iOS: 通过 Xcode `Runner.xcworkspace` → Archive

---

## 项目结构

```
lib/
  main.dart                # 入口
  app.dart                 # MaterialApp + 主题装配
  router.dart              # go_router 路由表
  providers.dart           # 全局 Riverpod Provider
  core/                    # 主题、常量、文本样式
  data/                    # 数据库、模型、Repository
  features/                # 业务模块（home / draw / battle / album / diary / ...）
  services/                # 安全 / 密码等横切服务
  shared/                  # 通用 Widget
assets/                    # 图片、音频、字体、卡片 JSON
data/cards.json            # 卡片库源文件（80 主卡 + 10 功能卡）
PRD.md                     # 完整产品需求文档
```

---

## 文档导航

| 文件 | 说明 |
|---|---|
| [`PRD.md`](./PRD.md) | **完整产品需求文档**，涵盖产品定义、视觉规范、信息架构、功能规格、卡片体系、技术架构、MVP 路线图 |
| [`data/cards.json`](./data/cards.json) | 机器可读的卡片库（80 张主卡 + 10 张功能卡） |
| [`assets/01_home.png`](./assets/01_home.png) | 视觉稿 · 主页 |
| [`assets/02_draw_charging.png`](./assets/02_draw_charging.png) | 视觉稿 · 抽卡蓄力 |
| [`assets/03_ssr_reveal.png`](./assets/03_ssr_reveal.png) | 视觉稿 · SSR 翻牌瞬间 |
| [`assets/04_battle_rps.png`](./assets/04_battle_rps.png) | 视觉稿 · 对战 · 石头剪刀布 |

---

## 核心特性概览

### 视觉
- **暗夜烛影**主题，深紫黑底 + 暗金点缀 + 酒红玫瑰情感线
- 二次元抽卡式 3D 翻牌特效，R/SR/SSR/UR 四档稀有度差异化光效
- 高质量过渡动效，配合震动与音效

### 玩法
- **4 档氛围**：甜蜜日常 → 心动暧昧 → 亲密互动 → 私密大胆（18+）
- **抽卡机制**：单抽 + 十连 + 保底
- **对战模式**：石头剪刀布 / 色子比大小 / 翻硬币
- **功能卡**：跳过/重抽/反转/镜像/加注/升降级/心愿/时光等 10 张
- **收集系统**：图鉴 + 完成日记 + 亲密度成长

### 隐私 & 安全
- 启动密码 + Lv.4 独立密码 + 伪装图标
- 全本地 SQLite + AES 加密，零数据上传
- 强制安全词、双方同意机制、舒适度过滤

### 个性化
- 情侣昵称、纪念日、在一起天数
- 自定义卡片（与官方卡平等参与抽取）
- 加密 JSON 导出/导入备份

---

## 下一步建议

1. **接入字体与音效资源**：补 `assets/fonts/NotoSerifSC-*.ttf`、抽卡 / 翻牌 / 完成的音效
2. **对战模式**：石头剪刀布 / 色子 / 翻硬币，复用现有抽卡引擎产出 winner/loser 执行者
3. **自制卡片编辑器**：在 `assets/data/cards.json` 之外，让用户写入 `cards` 表 (`is_custom=1`)
4. **加密备份**：用 `encrypt` 库做 JSON 导入 / 导出
5. **翻牌动效深度优化**（可选）：把现有 2D 透视 + 爆发特效迁移到 Rive 或自绘 3D
6. **每日跳过限制**（PRD §9.2）：把跳过限制接到 settings + 日期键

详细路线图见 PRD 第 12 章。

---

## 法律 / 合规

- 本项目内容含 18+ 成人元素，仅适用于年满 18 周岁的用户
- 不收集、上传、传输任何用户数据
- 上架应用商店时建议默认隐藏 Lv.4 入口，避免审核风险
