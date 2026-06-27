# claus_island 项目目录结构

claus island 是一个 macos siftui 应用程序，它创建了一个动态岛风格的浮动面板位于菜单栏下方。它使用基于插件的模块架构，其中每个功能模块都实现了 IslandModule 协议。该应用程序是一个 LSUIElement，具有浮动面板在顶层窗口级别。

# 项目目录结构

```
├── cisland/
│   ├── Sources/
│   │   ├── claus_island/
│   │   │   ├── AppDelegate.swift
│   │   │   ├── DynamicIslandApp.swift
│   │   │   ├── Core/
│   │   │   │   ├── IslandModule.swift
│   │   │   │   └── ModuleRegistry.swift
│   │   │   ├── Models/
│   │   │   │   ├── SystemMonitorData.swift
│   │   │   │   └── CalendarData.swift
│   │   │   │   └── CalendarService.swift
│   │   │   ├── Modules/
│   │   │   │   ├── InfoModule.swift
│   │   │   │   ├── ClipboardModule.swift
│   │   │   │   ├── QuickInfoModule.swift
│   │   │   │   ├── ClaudePermissionModule.swift
│   │   │   │── Services/
│   │   │   │   ├── SystemMonitor.swift
│   │   │   │   ├── ClaudePermissionStream.swift
│   │   │   │   ├── MusicService.swift
│   │   │   │   └── WeatherService.swift
│   │   │   │   └── IslandSettings.swift
│   │   │   │   └── IslandVisibility.swift
│   │   │   ├── Views/
│   │   │   │   ├── IslandContainerView.swift
│   │   │   │   ├── ExpandedIslandView.swift
│   │   │   │   ├── CompactModuleView.swift
│   │   │   │   ├── IslandCloseButton.swift
│   │   │   │   ├── MetricRow.swift
│   │   │   │   └── PetView.swift
│   │   │   ├── Windows/
│   │   │   │       ├── IslandPanel.swift
│   │   │   │       └── IslandWindowController.swift
│   │   │   └── Resources/
│   │   │       └── Assets.xcassets
│   │   └── Tests/
│   │       └── claus islandTests/
│   │           ├── AppIcon + ClaudeLogo 图片资源
│   │           └── 单元测试(8 个文件)
│   ├── hooks/
│   │   ├── claude_permission hook.py
│   │   ├── nowplaying.swift
│   │   └── test claude permission_stream.py
│   ├── scripts/
│   │   ├── Linstall-hook.sh
│   │   └── ai-soul/
│   └── knowledge/
│       └── specs/
│           ├── XcodeGen 工程定义
│           └── Claude Code 指引
│   └── project.yml
```

### 核心业务流程
用户操作 / 快捷键cmd+shit+O -> AppDelegate
      -> IslandWindowController -> IslandPanel (NSPanel)
      -> IslandContainerView (SwiftUI 根容器)
          -> ExpandedIslandView + TabBarView
          -> ModuleRegistry -> activeModule
              -> ClaudePermissionInfoModule
               -> ClaudePermissionInfoService
              -> ClipboardModule
                -> ClipboardService
              -> QuickInfoModule
                -> quickInfoService(localStorage)
              -> InfoModule(Dashboard)
                -> SystemMonitor
                -> MusicService
                -> wheatherService
                -> CalendarService
            

### 核心模块说明
## 核心模块

  ### IslandModule 协议 (`core/IslandModule.swift`)
  插件协议，所有功能模块必须实现:
  | 属性/方法 | 类型 | 说明 |
  |------------|------|------|
  | `id` | `string` | 唯一模块标识符 |
  | `displayName` | `string` | 显示名称 |
  | `tabIcon` | `string` | Tab 栏 SF Symbol 图标名 |
  | `customIconAsset` | `string?` | 可选自定义 Asset catalog 图标 (默认 `nil`) |
  | `accentColor` | `Color` | 模块强调色 (默认 `.white`) |
  | `expandedHeight` | `CGFloat` | 展开态高度 (默认 `IslandSize.expandedHeight`) |
  | `expandedView()` | `AnyView` | 展开态 SwiftUI 视图 |

  ### ModuleRegistry (`core/ModuleRegistry.swift`)
  模块注册中心 (`@ObservableObject`):
  - `init()` - 空初始化，无硬编码注册
  - `@Published modules` - 有序模块列表
  - `@Published activeModuleIndex` - 当前活跃模块索引
  - `register()` - 注册模块
  - `switchToModule(at:)` - 切换活跃模块，带 `.easeInOut(duration: 0.25)` 动画
  - `activeModule` - 计算属性，返回当前模块

  ## 模块注册流程

  1. `AppDelegate.applicationDidFinishLaunching` 创建 `ModuleRegistry`，按序注册 4 个模块:
     - `InfoModule()` - 信息模块
     - `ClipboardModule()` - 剪贴板模块
     - `QuickInfoModule()` - 快捷信息模块
     - `ClaudePermissionModule()` - Claude 权限审批模块 (**默认活跃 Tab**)

  2. 将 `ModuleRegistry` 传递给 `IslandWindowController`
     - 展开态显示 “TabBarView” (顶部) + `activeModule.expandedView()` (内容区)
     - Tab 栏中还有齿轮按钮打开 `IslandsettingsPopover` (背景主题切换)


## 四大模块详解

### 1. InfoModule(Dashboard)

**基本信息**

| 属性 | 值 |
|------|-----|
| `id` | `"info"` |
| `tabIcon` | `square.grid.2x2` |
| `accentColor` | 蓝 `(0.35, 0.65, 1.0)` |
| `expandedHeight` | `200` |

**展开态布局**

展开态为 `DashboardView`，采用 HStack 水平三卡布局：

| 子视图 | 功能 | 数据源 |
|--------|------|--------|
| **MusicCard** | 专辑封面 + 歌曲名/艺术家 + 音乐频谱动画 | `MusicService.shared` |
| **CalendarCard** | 月份标题 + 一周日期条(高亮今日) + 实时时钟(渐变色) + 星期标签 | `calendarService.shared` |
| **WeatherCard** | 天气图标(渐变色) + 温度 + 城市名 + 天气描述 | `WeatherService.shared` |


### 2. ClipboardModule

**基本信息**

| 属性 | 值 |
|------|-----|
| `id` | `"clipboard"` |
| `tabIcon` | `doc.on.clipboard` |
| `accentColor` | 橙 `(1.0, 0.65, 0.2)` |

**ClipboardService** (`clipboardModule.swift` 内)

- 单例，1s 轮询 `NSPasteboard.general.changeCount`
- 支持文本和图片剪贴内容
- 图片保存到 `~/.claus_island/clipboard/images/`
- 文本去重（相同内容提升到顶部）
- 最多 100 条历史，FIFO 淘汰
- 持久化到 `~/.claus_island/clipboard/history.json` (ISO8601 日期格式)
- 图片缓存（内存 `imageCache`）

**ClipboardExpandedView**

- 搜索框 (`ClipboardSearchField`, NSViewRepresentable，支持方向键/回车) + 历史列表
- 点击条目 → 写入粘贴板 → 发送 `.islandShouldHide` 通知收起 Island

### 3. QuickInfoModule

**基本信息**

| 属性 | 值 |
|------|-----|
| `id` | `"quickinfo"` |
| `tabIcon` | `person.text.rectangle` |
| `accentColor` | 绿 `(0.3, 0.8, 0.6)` |

**QuickInfoStore** (`QuickInfoModule.swift` 内)

- 单例，管理自定义 KV 条目
- 数据持久化到 `~/.claus_island/quickinfo.json`
- 支持 `add` / `remove` / `update` 操作

**QuickInfoView**

- 头部标题 + 添加按钮
- 可展开的添加表单（Label + Value 输入框）
- 条目列表：
- 点击复制值到粘贴板
- hover 显示编辑/删除按钮
- 编辑模式：内联 TextField 修改

### 4. ClaudePermissionModule

**基本信息**

| 属性 | 值 |
|------|-----|
| `id` | `"claude-permissions"` |
| `tabIcon` | `sparkle` |
| `customIconAsset` | `"claudeLogo"` |
| `accentColor` | 紫 `(0.85, 0.45, 0.95)` |


## 视图结构
状态｜视图
有 pendding 请求(工具) ｜toolApprovalCard 工具徽章+命令预览+approve/Deny 按钮
有 pendding 请求(问题)  |questionCard 问题文本+选项按钮+文本输入框
无 pending 有历史 审理历史列表
无 pending 无历史 claude is ready 占位
 
**通知联动**：新请求来到时，isLandShouldShow 显示 isLand + isLandSwitchToModule 切换到 Claude Tab


