# HarmonyVideoEditor

> 基于 HarmonyOS ArkTS 的视频编辑器应用，目标 SDK 6.1.0(23)，兼容 6.0.0(20)。

## 项目概览

HarmonyVideoEditor 是一个运行在 HarmonyOS 上的视频编辑应用，采用模块化架构，通过 Action 总线模式解耦编辑指令与 UI 响应。目前处于**早期基础建设阶段**，已完成数据模型层和缩略图管线的基础搭建。

| 项目 | 值 |
|------|------|
| Bundle | `com.homo.videoeditor` |
| 版本 | 1.0.0 (1000000) |
| 目标 SDK | 6.1.0 (API 23) |
| 兼容 SDK | 6.0.0 (API 20) |
| 语言 | ArkTS (strict mode) |

## 模块架构

```
HarmonyVideoEditor/
├── AppScope/                  # 应用全局配置（图标、名称、版本）
├── entry/                     # 入口 Ability（主应用壳）
├── foundation/                # 基础库 HAR — Action 总线 + 通用工具
├── lib_data/                  # 数据模型 HAR — Asset / Segment / 时间轴模型
├── lib_editor/                # 编辑引擎 HAR — 缩略图管线 + UI 组件
├── build-profile.json5        # 工程级构建配置
└── oh-package.json5           # 工程级依赖声明
```

### 模块依赖关系

```
entry (Ability)
  └── lib_editor (编辑 UI)
        ├── lib_data (数据模型)
        │     └── foundation (基础库)
        └── foundation (基础库)
```

### 各模块职责

| 模块 | 类型 | 职责 | 当前状态 |
|------|------|------|----------|
| `foundation` | HAR | Action 总线、通用工具函数 | ✅ 基础可用 |
| `lib_data` | HAR | 素材/片段/时间轴数据模型 | ✅ 基础可用 |
| `lib_editor` | HAR | 缩略图管线、编辑 UI 组件 | 🚧 开发中 |
| `entry` | Entry | App 壳、Ability 生命周期 | 🚧 待接入 |

---

## 设计理念

### 1. Action 总线模式

`foundation/src/main/ets/core/action/EditorBridge.ets` 提供了一个**中心化的 Action 派发器**：

```
UI / 控制层  ──dispatch(action)──▶  EditorBridge  ──route──▶  Handler
                                    (单例)                   (按 type 注册)
```

- **`IAction`** — 所有编辑动作的标记接口，`type: string` 用于路由
- **`IActionHandler<T>`** — 处理器接口，`handle(action): void | Promise<void>`
- **`EditorBridge`** — 单例，维护 `Map<type, Handler>`，支持异步派发

这种设计的优势：
- 编辑指令与 UI 完全解耦，可独立测试
- 支持异步处理（视频解码、特效加载等耗时操作）
- 天然支持撤销/重做（通过记录 Action 序列）
- 插件化扩展（新增编辑能力只需注册新 Handler）

### 2. 数据模型分层

`lib_data` 模块采用**三层继承体系**建模素材与片段：

```
AbsAsset (基类: id, uri, name, fileSize, mediaType)
  ├── VideoAsset  (duration, width, height)
  ├── AudioAsset  (duration)
  └── ImageAsset  (width, height)

AbsSegment (基类: id, type, timelineRange, scale, posX, posY)
  └── MediaSegment (asset)
        ├── AVSegment (sourceRange, speed)  — 音视频特有
        │     ├── VideoSegment
        │     └── AudioSegment
        └── ImageSegment                    — 图片无 sourceRange
```

设计要点：
- 时间轴统一使用微秒 (`μs`) 作为时间单位
- `TimeRange` 内置不变量校验 (`end >= start`)
- `SegmentType` 枚举与 `MediaType` 对齐，扩展 `TEXT` / `EFFECT` 预留
- 图片素材通过 `timelineRange` 控制时长，无 `sourceRange` 概念

### 3. 缩略图管线（策略模式）

```
ThumbnailStrip (UI 组件)
  │  @Prop segment, segmentWidth, thumbnailHeight
  │  @Watch → 自动重新计算帧分布
  ▼
calculateAndFetchFrames()
  │  按 segmentWidth / thumbHeight 计算需要多少帧
  │  按 duration 均匀分布时间戳
  ▼
ThumbnailManager (单例 + 缓存)
  │  cacheKey 对齐 → 查缓存
  │  Provider 路由: VIDEO → VideoThumbnailProvider
  │                 IMAGE → ImageThumbnailProvider
  ▼
IThumbnailProvider (策略接口)
  ├── ImageThumbnailProvider  → 直接返回 uri
  └── VideoThumbnailProvider  → AVImageGenerator 抽帧
```

---

## 当前进度

### ✅ 已完成

| 功能 | 模块 | 说明 |
|------|------|------|
| 数据模型 | `lib_data` | Asset/Segment/TimeRange 完整建模，类型安全 |
| Action 总线 | `foundation` | EditorBridge 单例，register/dispatch 基础链路 |
| 缩略图管理器 | `lib_editor` | ThumbnailManager 单例 + 缓存 + Provider 路由 |
| 缩略图策略 | `lib_editor` | ImageThumbnailProvider / VideoThumbnailProvider |
| 缩略图 UI | `lib_editor` | ThumbnailStrip 组件，支持缩放时自动重算帧 |

### 🚧 待完成

| 优先级 | 功能 | 说明 |
|--------|------|------|
| P0 | 视频抽帧落地 | `VideoThumbnailProvider` 中 `fd: 0` 需替换为真实的 `resourceManager`/`fileIO` 打开 FD |
| P0 | 缓存策略升级 | `ThumbnailManager.frameCache` 当前为普通 Map，需替换为 LRU Cache 防止内存溢出 |
| P0 | EditorBridge 接入 | entry 模块需注册 Handler 并将 EditorBridge 与 UI 交互打通 |
| P1 | 缩略图宽高比适配 | 当前硬编码为正方形，需根据视频实际宽高比适配 16:9 / 9:16 / 1:1 等 |
| P1 | 帧缓存批量清理 | `releaseSegment()` 需同步清理对应 frameCache 条目 |
| P1 | 缩略图占位图 | 抽帧失败时返回空字符串，需替换为默认占位图 |
| P2 | 时间轴渲染 | 基于 `AbsSegment.timelineRange` 实现可滚动/可缩放的时间轴 |
| P2 | 撤销/重做 | 利用 Action 总线记录操作序列，实现历史栈 |
| P2 | 多轨道支持 | 扩展 `ThumbnailStrip` 为多轨道布局 |

---

## 后续开发建议

### 第一阶段：核心链路打通

1. **视频抽帧落地** — 通过 `resourceManager.getRawFd()` 或 `fileIO.open()` 获取实际 FD，替换 `VideoThumbnailProvider` 中的占位 `fd: 0`
2. **缓存升级** — 实现 `LRUCache<string, image.PixelMap | string>` 替换 `ThumbnailManager.frameCache`，按内存或条目数上限淘汰
3. **事件循环连通** — 在 `entry/EntryAbility` 中初始化 `EditorBridge` 单例，注册首批 Handler（如 `AddSegmentHandler`、`RemoveSegmentHandler`），验证 Action 链路端到端可用

### 第二阶段：编辑能力扩展

4. **时间轴交互** — 基于 `ThumbnailStrip` 实现可拖拽的时间轴视图，支持：
   - 水平滚动（`Scroll` + `List`）
   - 捏合缩放（`PinchGesture` → 改变 `segmentWidth` → `@Watch` 自动触发帧重算）
   - 长按拖拽重排片段
5. **裁剪/分割** — 实现 `SplitSegmentAction`、`TrimSegmentAction`，操作 `sourceRange` 和 `timelineRange`
6. **特效/滤镜** — 利用 `SegmentType.EFFECT` 预留，实现特效素材的叠加与时间轴绑定

### 第三阶段：产品化

7. **导出管线** — 基于 `AVTranscoder` 或 `MediaCodec` 实现多轨道合成导出
8. **性能优化** — 缩略图预加载、帧缓存复用、大项目内存管理
9. **测试覆盖** — 补充 `lib_data` 模型单元测试、`EditorBridge` 派发测试、`ThumbnailManager` 缓存命中测试

---

## 开发约定

### ArkTS 硬约束

- 禁止 `any` / `unknown` 类型逃逸
- 禁止 `var` 声明，一律使用 `let` / `const`
- 禁止解构声明（对象/数组）
- 避免 `!` 非空断言（`arkts-no-definite-assignment` warning）
- 类型收窄优先使用 `instanceof` + `as T`（已通过 type discriminant 守卫）
- 不使用 `delete`、`as const`、生成器函数等 TS 独有特性

详见 `.claude` 全局 CLAUDE.md 及 `hmos-arkts-coding-standard` skill。

### 模块边界

- `foundation` 不依赖任何业务模块，只提供通用能力
- `lib_data` 仅依赖 `foundation`，只定义数据模型，不含 UI
- `lib_editor` 依赖 `lib_data` + `foundation`，负责 UI 与编辑逻辑
- `entry` 作为壳，组装所有模块并管理 Ability 生命周期

### 命名规范

- 文件名：PascalCase（`ThumbnailStrip.ets`、`VideoSegment.ets`）
- 接口：`I` 前缀（`IAction`、`IThumbnailProvider`）
- 抽象类：`Abs` 前缀（`AbsSegment`、`AbsAsset`）
- 枚举：PascalCase，值使用小写字符串（`SegmentType.VIDEO = 'video'`）

---

## 快速开始

```bash
# 安装依赖
ohpm install

# 编译
hvigorw assembleHap

# 安装到设备
hdc install -r entry/build/default/outputs/default/entry-default-signed.hap
```

> 需要安装 DevEco Studio 并配置好 SDK 6.1.0(23)。

---

## 许可证

Apache-2.0