# Code Structure — Claus Island

> Version: v3.0.0 (Updated 2026-06-14)

## Architecture Overview

Claus Island is a macOS SwiftUI application that creates a Dynamic Island-style floating panel below the menu bar. It uses a **plugin-based module architecture** where each feature implements the `IslandModule` protocol. The app is an LSUIElement (no Dock icon) with a floating panel at `.floating` window level.

### 核心数据流

```
用户操作 / 快捷键 ⌘⇧O
        │
        ▼
  AppDelegate ──→ IslandWindowController ──→ IslandPanel (NSPanel)
                              │                     │
                              ▼                     ▼
                    IslandContainerView (SwiftUI 根容器)
                     └── ExpandedIslandView + TabBarView
                              │
                              ▼
                     ModuleRegistry ──→ activeModule
                        │
            ┌───────────┼───────────┬───────────────┐
            ▼           ▼           ▼               ▼
       InfoModule  ClipboardModule QuickInfo   ClaudePermission
       (Dashboard)                Module      Module
            │           │           │               │
            ▼           ▼           ▼               ▼
     SystemMonitor  Clipboard  QuickInfo    ClaudePermission
     MusicService   Service    Store        Service
     WeatherService            (localStorage)
     CalendarService
```

## Project Structure

```
cisland/
├── Sources/claus_island/
│   ├── App/
│   │   ├── AppDelegate.swift              # 应用生命周期，注册模块，菜单栏图标，全局快捷键 ⌘⇧O
│   │   └── DynamicIslandApp.swift         # @main 入口，SwiftUI App 协议
│   ├── Core/
│   │   ├── IslandModule.swift             # 模块协议定义（id, displayName, tabIcon, expandedView 等）
│   │   └── ModuleRegistry.swift           # ObservableObject 模块注册中心
│   ├── Models/
│   │   ├── CalendarData.swift             # 日历缓存数据结构
│   │   └── CalendarService.swift          # 日历服务（EventKit 格式化，60s 刷新）
│   ├── Modules/
│   │   ├── InfoModule.swift               # Dashboard 模块：日历卡 + 音乐卡 + 天气卡
│   │   ├── ClipboardModule.swift          # 剪贴板模块：历史管理、搜索、图片支持、持久化
│   │   ├── QuickInfoModule.swift          # 快捷信息模块：用户自定义 KV 条目，点击复制
│   │   └── ClaudePermissionModule.swift   # Claude 权限审批模块：工具审批 + 问题回复 UI
│   ├── Services/
│   │   ├── ClaudePermissionStreamService.swift  # Claude 权限服务：监听 pending 文件，审批/拒绝写入 response
│   │   ├── MusicService.swift             # 音乐服务：nowplaying 脚本轮询，封面/进度/播放状态
│   │   ├── WeatherService.swift           # 天气服务：CoreLocation + open-meteo API
│   │   └── IslandSettings.swift           # 偏好设置（IslandBackground：glass/dark/light）
│   ├── Views/
│   │   ├── IslandContainerView.swift      # 根容器：ExpandedIslandShape 背景、TabBarView、设置弹窗
│   │   └── ExpandedIslandView.swift       # 展开态视图：Tab 切换 + 模块内容区
│   ├── Windows/
│   │   ├── IslandPanel.swift              # NSPanel 子类：无边框、浮动级、透明背景
│   │   └── IslandWindowController.swift   # 窗口控制器：定位、展开/收起动画
│   └── Resources/
│       └── Assets.xcassets/               # AppIcon + ClaudeLogo 图片资源
├── Tests/claus_islandTests/               # 单元测试（2 个文件）
│   ├── ModuleRegistryTests.swift                       # Module 注册、切换、空状态测试
│   └── CalendarDataTests.swift                         # CalendarData 结构体，CalendarService 格式化测试
├── hooks/
│   ├── claude_permission_hook.py          # Claude Code PreToolUse 钩子
│   ├── nowplaying.swift                   # macOS 正在播放音乐信息提取脚本
│   └── test_claude_permission_stream.py   # 钩子单元测试
├── scripts/
│   └── install-hook.sh                   # 一键安装 Claude 权限钩子
├── ai-soul/                               # SDD 规约 & 知识库
│   ├── knowledge/
│   └── specs/
├── project.yml                            # XcodeGen 工程定义
└── CLAUDE.md                              # Claude Code 指引
```

## Key Components

### IslandModule Protocol (`Core/IslandModule.swift`)

插件协议，所有功能模块必须实现：

| 属性/方法 | 类型 | 说明 |
|-----------|------|------|
| `id` | `String` | 唯一模块标识符 |
| `displayName` | `String` | 显示名称 |
| `tabIcon` | `String` | Tab 栏 SF Symbol 图标名 |
| `customIconAsset` | `String?` | 可选自定义 Asset Catalog 图标（默认 `nil`） |
| `accentColor` | `Color` | 模块强调色（默认 `.white`） |
| `expandedHeight` | `CGFloat` | 展开态高度（默认 `IslandSize.expandedHeight`） |
| `expandedView()` | `AnyView` | 展开态 SwiftUI 视图 |

### ModuleRegistry (`Core/ModuleRegistry.swift`)

模块注册中心（`ObservableObject`）：

- `init()` — 空初始化，无硬编码注册
- `@Published modules` — 有序模块列表
- `@Published activeModuleIndex` — 当前活跃模块索引
- `register(_:)` — 注册模块
- `switchToModule(at:)` — 切换活跃模块，带 `.easeInOut(duration: 0.25)` 动画
- `activeModule` — 计算属性，返回当前模块

### Module Registration Flow

1. `AppDelegate.applicationDidFinishLaunching` 创建 `ModuleRegistry`，按序注册 4 个模块：
   - `InfoModule()` — Dashboard
   - `ClipboardModule()` — 剪贴板
   - `QuickInfoModule()` — 快捷信息
   - `ClaudePermissionModule()` — Claude 权限审批（**默认活跃 Tab**）
2. 传递 `ModuleRegistry` 给 `IslandWindowController`
3. 展开态显示 `TabBarView`（顶部） + `activeModule.expandedView()`（内容区）
4. Tab 栏中还有齿轮按钮打开 `IslandSettingsPopover`（背景主题切换）

---

## 四大模块详解

### 1. InfoModule（Dashboard）`id: "info"`

| 属性 | 值 |
|------|-----|
| `tabIcon` | `square.grid.2x2` |
| `accentColor` | 蓝 `(0.35, 0.65, 1.0)` |
| `expandedHeight` | `200` |

展开态为 `DashboardView`，采用 HStack 水平三卡布局：

| 子视图 | 功能 | 数据源 |
|--------|------|--------|
| **MusicCard** | 专辑封面 + 歌曲名/艺术家 + 音乐频谱动画 | `MusicService.shared` |
| **CalendarCard** | 月份标题 + 一周日期条（高亮今日）+ 实时时钟（渐变色） + 星期标签 | `CalendarService.shared` |
| **WeatherCard** | 天气图标（渐变色）+ 温度 + 城市名 + 天气描述 | `WeatherService.shared` |

### 2. ClipboardModule `id: "clipboard"`

| 属性 | 值 |
|------|-----|
| `tabIcon` | `doc.on.clipboard` |
| `accentColor` | 橙 `(1.0, 0.65, 0.2)` |

- **ClipboardService** (`ClipboardModule.swift` 内)：单例，1s 轮询 `NSPasteboard.general.changeCount`
  - 支持文本和图片剪贴内容
  - 图片保存到 `~/.claus_island/clipboard/images/`，文本去重（相同内容提升到顶部）
  - 最多 100 条历史，FIFO 淘汰
  - 持久化到 `~/.claus_island/clipboard/history.json`（ISO8601 日期格式）
  - 图片缓存（内存 `imageCache`）
- **ClipboardExpandedView**：搜索框（`ClipboardSearchField`，NSViewRepresentable 支持方向键/回车）+ 历史列表
- 点击条目 → 写入粘贴板 → 发送 `.islandShouldHide` 通知收起 Island

### 3. QuickInfoModule `id: "quickinfo"`

| 属性 | 值 |
|------|-----|
| `tabIcon` | `person.text.rectangle` |
| `accentColor` | 绿 `(0.3, 0.8, 0.6)` |

- **QuickInfoStore** (`QuickInfoModule.swift` 内)：单例，管理自定义 KV 条目
  - 数据持久化到 `~/.claus_island/quickinfo.json`
  - 支持 `add` / `remove` / `update` 操作
- **QuickInfoView**：
  - 头部标题 + 添加按钮
  - 可展开的添加表单（Label + Value 输入框）
  - 条目列表：点击复制值到粘贴板，hover 显示编辑/删除按钮
  - 编辑模式：内联 TextField 修改

### 4. ClaudePermissionModule `id: "claude-permissions"`

| 属性 | 值 |
|------|-----|
| `tabIcon` | `sparkle` |
| `customIconAsset` | `ClaudeLogo` |
| `accentColor` | 紫 `(0.85, 0.45, 0.95)` |

作为 Claude Code 的审批 UI，核心交互流程：

1. Claude Code 钩子写入 `~/.claude/cisland-pending.json`
2. `ClaudePermissionService` 监听 `~/.claude/` 目录变化，读取 pending 请求
3. Island 显示审批卡片（工具审批或问题回复）
4. 用户点击 Approve/Deny 或回复文本 → 写入 `~/.claude/cisland-response.json`，删除 pending 文件
5. 钩子读取 response，返回给 Claude Code

**视图结构**：

| 状态 | 视图 |
|------|------|
| 有 pending 请求（工具） | `ToolApprovalCard` — 工具徽章 + 命令预览 + Approve/Deny 按钮 |
| 有 pending 请求（问题） | `QuestionCard` — 问题文本 + 选项按钮 + 文本输入框 |
| 无 pending，有历史 | 审批历史列表（绿色✓ / 红色✗ / 蓝色↪） |
| 无 pending，无历史 | "Claude is ready" 占位 |

**通知联动**：新请求到来时 → `.islandShouldShow`（显示 Island）+ `.islandSwitchToModule`（切到 Claude Tab）

---

## Services 层详解

### ClaudePermissionService (`Services/ClaudePermissionStreamService.swift`)

| 属性 | 说明 |
|------|------|
| 模式 | 单例 `ClaudePermissionService.shared` |
| 监听 | `DispatchSourceFileSystemObject` 监听 `~/.claude/` 目录写入 |
| pending | `~/.claude/cisland-pending.json` — 钩子写入，服务读取 |
| response | `~/.claude/cisland-response.json` — 服务写入审批决定 |
| 历史 | 最多 50 条 `PermissionHistoryEntry`，FIFO |
| 请求模型 | `PermissionRequest`：id, timestamp, toolName, toolInput, sessionId, cwd |
| 去重 | `respondedId` 防止重复处理 |

### MusicService (`Services/MusicService.swift`)

| 属性 | 说明 |
|------|------|
| 模式 | 单例 `MusicService.shared` |
| 数据 | songName, artist, album, isPlaying, hasMusic, artwork (NSImage), elapsed, duration |
| 采集 | 执行 `nowplaying.swift` 脚本，解析 JSON 输出 |
| 刷新 | 10 秒轮询，`tolerance = 2` |
| 暂停/恢复 | 监听 `.islandDidBecomeVisible` / `.islandDidBecomeHidden` 通知 |

### WeatherService (`Services/WeatherService.swift`)

| 属性 | 说明 |
|------|------|
| 模式 | 单例 + `CLLocationManagerDelegate` |
| 数据 | temperature (Int?), conditionSymbol (SF Symbol), conditionText, cityName |
| 定位 | `CLLocationManager`，3km 精度，逆地理编码获取城市名 |
| API | `api.open-meteo.com`（WMO weather_code 映射 SF Symbol） |
| 刷新 | 900 秒（15 分钟），`tolerance = 60` |

### IslandSettings (`Services/IslandSettings.swift`)

| 属性 | 说明 |
|------|------|
| 模式 | 单例 `IslandSettings.shared`，`@AppStorage` 持久化 |
| 配置 | `IslandBackground` 枚举：`glass`（毛玻璃）/ `dark`（深黑）/ `light`（浅色） |
| 默认 | `glass` |

---

## Views 层详解

### IslandContainerView

根容器视图，关键特性：

- **ExpandedIslandShape**：自定义 Shape，模拟 Dynamic Island 造型——顶部直边 + 侧边内收曲线 + 底部圆角
- **背景**：根据 `IslandSettings.background` 切换 `ultraThinMaterial` / 深黑 / 浅色
- **阴影**：`Color.black.opacity(0.35)`, radius 24, y offset 8
- **动画**：`spring(response: 0.35, dampingFraction: 0.8)` 驱动高度变化
- **TabBarView**：模块图标切换 + 齿轮设置按钮（Popover 主题选择）
- **ModuleIcon**：优先使用 `customIconAsset`（如 ClaudeLogo），否则使用 SF Symbol

### ExpandedIslandView

展开态内容区，包含 TabBarView 和模块内容交换。

### CompactModuleView

紧凑态视图，图标 + 摘要 + 点击手势。

### 其他视图

| 视图 | 说明 |
|------|------|
| `MusicBars` | 音乐播放频谱动画（4 根柱条，交替高度动画，定义在 InfoModule.swift） |
| `CardShell` | Claude 审批卡片外壳（可复用，图标 + 标题 + 项目标签，定义在 ClaudePermissionModule.swift） |
| `ClipboardSearchField` | NSViewRepresentable 搜索框，支持方向键和回车快捷操作（定义在 ClipboardModule.swift） |
| `ClipboardRow` | 剪贴板历史条目行（文本/图片，选中/悬浮状态，定义在 ClipboardModule.swift） |
| `QuickInfoRowView` | 快捷信息条目行（标签 + 值，hover 编辑/删除，点击复制，定义在 QuickInfoModule.swift） |
| `IslandSettingsPopover` | 设置弹窗（背景主题三选一：Glass/Dark/Light，定义在 IslandContainerView.swift） |

---

## Windows 层详解

### IslandPanel (`Windows/IslandPanel.swift`)

NSPanel 子类，核心特性：

- `styleMask`：`.borderless` + `.nonactivatingPanel` + `.fullSizeContentView`
- `level = .floating` — 浮动窗口层级
- 透明背景 + 阴影
- `canBecomeKey = true`, `canBecomeMain = false`
- `LSUIElement = true` — 不在 Dock 显示

### IslandWindowController (`Windows/IslandWindowController.swift`)

窗口控制器：

- 接收 `ModuleRegistry`，管理 Island 窗口生命周期
- 定位于菜单栏下方，5pt 间距
- `showIsland()` / `hideIsland()` / `toggleIsland()` 方法
- 窗口 frame 动画：`easeInEaseOut`（0.5s）
- 监听 `.islandShouldShow` / `.islandShouldHide` / `.islandSwitchToModule` 通知

---

## Dimensions & Visual Style

| 状态 | 帧宽度 | 内容宽度 | 高度 |
|------|--------|----------|------|
| Expanded 帧宽度 | `IslandSize.expandedFrameWidth` | `IslandSize.expandedWidth` | 各模块 `expandedHeight` (默认 240pt) |

| 视觉属性 | 值 |
|----------|-----|
| 形状 | `ExpandedIslandShape`：topOverhang 内收曲线，底部 24pt 圆角 |
| 背景 | glass: `ultraThinMaterial` + `black.opacity(0.3)` / dark: `black.opacity(0.95)` / light: `(0.96, 0.96, 0.97)` |
| 阴影 | `black.opacity(0.35)`, radius 24, y=8 |
| 动画 | `spring(response: 0.35, dampingFraction: 0.8)` |

---

## Module Specifications

| Module | id | tabIcon | customIconAsset | accentColor | expandedHeight | expanded 内容 |
|--------|-----|---------|-----------------|-------------|----------------|--------------|
| Info | `info` | `square.grid.2x2` | — | 蓝 `(0.35, 0.65, 1.0)` | 200 | HStack: MusicCard + CalendarCard + WeatherCard |
| Clipboard | `clipboard` | `doc.on.clipboard` | — | 橙 `(1.0, 0.65, 0.2)` | 默认 240 | 搜索框 + 历史列表（文本/图片，最多 100 条） |
| QuickInfo | `quickinfo` | `person.text.rectangle` | — | 绿 `(0.3, 0.8, 0.6)` | 默认 240 | 标题栏 + 添加表单 + KV 条目列表 |
| Claude | `claude-permissions` | `sparkle` | `ClaudeLogo` | 紫 `(0.85, 0.45, 0.95)` | 默认 240 | 审批卡片 / 问题回复 / 历史列表 |

---

## External Integration — Claude Code PreToolUse Hook

`ClaudePermissionModule` 通过文件协议与 Claude Code 钩子集成：

### 文件协议

| 文件 | 方向 | 说明 |
|------|------|------|
| `~/.claude/cisland-pending.json` | 钩子 → Island | 待审批请求（id, ts, tool_name, tool_input, session_id, cwd） |
| `~/.claude/cisland-response.json` | Island → 钩子 | 审批决定（id, decision: "approve"/"deny"/"reply", message?） |

### 钩子 (`hooks/claude_permission_hook.py`)

- 白名单自动审批：`Read/Glob/Grep/TodoWrite/WebFetch/WebSearch` + Bash 安全前缀（`ls/pwd/cat/head/tail/wc/git status` 等）
- Bash 前缀匹配要求下一个字符为空格或行尾，防止 `graphify-query` 误匹配 `graphify query`
- 命令中含 `&& || ; | $( \`` 拒绝自动审批
- 所有调用（无论是否自动审批）都写入 JSONL 流文件供历史查看
- 顶层 `try/except` 保证钩子故障绝不阻断 Claude Code

---

## Notifications（通知中心）

| 通知名 | 发送方 | 接收方 | 说明 |
|--------|--------|--------|------|
| `.islandDidBecomeVisible` | IslandWindowController | MusicService | Island 显示，恢复轮询 |
| `.islandDidBecomeHidden` | IslandWindowController | MusicService | Island 隐藏，暂停轮询 |
| `.islandShouldShow` | ClaudePermissionService | IslandWindowController | 新审批请求，显示 Island |
| `.islandShouldHide` | ClipboardModule 等 | IslandWindowController | 操作完成后隐藏 Island |
| `.islandSwitchToModule` | ClaudePermissionService | IslandWindowController | 切换到指定模块 Tab |

---

## Data Persistence

| 路径 | 内容 | 格式 |
|------|------|------|
| `~/.claus_island/quickinfo.json` | QuickInfo 用户自定义条目 | JSON (Codable) |
| `~/.claus_island/clipboard/history.json` | 剪贴板历史 | JSON (ISO8601 日期) |
| `~/.claus_island/clipboard/images/*.png` | 剪贴板图片缓存 | PNG |
| `~/.claude/cisland-pending.json` | Claude 审批待处理请求 | JSON |
| `~/.claude/cisland-response.json` | Claude 审批响应 | JSON |
| `UserDefaults: islandBackground` | 背景主题偏好 | String (glass/dark/light) |

---

## Error Handling

| 场景 | 处理方式 |
|------|----------|
| 空模块列表 | 紧凑态: "No Module"，展开态: "No modules available" |
| Claude pending 文件缺失 | 服务不显示任何内容 |
| 剪贴板图片文件丢失 | 加载时过滤掉不存在的图片条目 |
| nowplaying 脚本无输出 | `hasMusic = false` → 显示 "Not Playing" |
| 天气定位失败 | `conditionText = "Location unavailable"`, `conditionSymbol = "location.slash"` |
| 钩子异常 | `{}` 输出 + exit 0，Claude Code 不受影响 |

---

## Code Cleanup History

| Date | Change | Files Modified |
|------|--------|----------------|
| 2026-05-20 | 添加毛玻璃视觉效果 | IslandContainerView.swift, ExpandedIslandView.swift |
| 2026-05-20 | 删除未使用的 ClipboardCompactView 结构体 | ClipboardModule.swift |
| 2026-05-25 | 新增 Claude Permission 模块 + 钩子集成 | ClaudePermissionModule.swift, ClaudePermissionStreamService.swift, hooks/ |
| 2026-06-14 | Dashboard 重设计：Music+Calendar+Weather 三卡布局替换原 CPU/内存指标 | InfoModule.swift, Services/ |
| 2026-06-14 | 清理死代码：删除 4 个未使用视图、SystemMonitor 子系统、IslandVisibility、6 个过时测试、未使用属性 | 多文件 |

---

## Module 扩展指南

要新增一个 Island 模块，需要：

1. 在 `Modules/` 目录创建新文件，定义符合 `IslandModule` 协议的结构体
2. 实现 `id`, `displayName`, `tabIcon`, `expandedView()` 等必需属性/方法
3. 在 `AppDelegate.applicationDidFinishLaunching` 中注册：
   ```swift
   registry.register(YourModule())
   ```
4. 如需后台数据服务，在 `Services/` 目录创建 `ObservableObject` 单例
5. 更新测试：在 `IslandModuleConformanceTests` 中添加新模块的一致性测试