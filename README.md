# Linmon

一款以青柠色与柠檬图表为视觉主题的 iOS 记账应用，使用 SwiftUI 构建，探索轻量、直观且富有触感的日常记账体验。

> 当前为开发中的交互原型。账单仅保存在本次运行的内存中，重启后恢复示例数据；账户余额为静态展示。

## 功能

- **今日概览**：显示今日支出、剩余预算和预算使用进度，柠檬图表同时展示餐饮支出占比。
- **收支记录**：支持支出、收入和转账，可选择分类、账户、日期并填写备注。
- **金额计算**：内置数字键盘，支持加、减、乘、除及连续运算，计算结果四舍五入至小数点后两位。
- **滑动确认**：向右滑动确认记账，提供进度动画、触觉反馈和成功提示；未完成滑动时松手可取消。
- **账单与账户**：浏览本次运行中的记录，以及示例账户信息。
- **系统外观适配**：支持浅色与深色模式、玻璃材质导航，并针对减少动态效果和减少透明度提供部分适配。

## 开发环境

- macOS 与 Xcode，需支持 iOS 26.2 SDK 或更新版本。
- iOS / iPadOS 26.2 或更新版本的模拟器或设备。
- 使用 SwiftUI、UIKit 和 SwiftData，无需安装第三方依赖。

工程的 Swift 语言版本设置为 Swift 5。

## 本地运行

在仓库根目录打开工程：

```bash
open Linmon.xcodeproj
```

在 Xcode 中选择 `Linmon` Scheme，选择符合最低系统版本的 iPhone 或 iPad 模拟器，按 `⌘R` 运行。

如需在真机运行，请在应用 Target 的 **Signing & Capabilities** 中选择自己的开发团队，并按需修改 Bundle Identifier。

也可在命令行构建模拟器版本：

```bash
xcodebuild \
  -project Linmon.xcodeproj \
  -scheme Linmon \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 使用方式

1. 点击底部中央的 `+`，打开记账面板。
2. 选择支出、收入或转账，输入金额；使用算式时先按 `=` 得到结果。
3. 选择账户，并按需调整日期、分类标签和备注。转账时需选择不同的转出、转入账户。
4. 从「记录」入口向右拖动，达到确认位置后松手；显示成功提示后，记账面板会自动关闭。

首页的今日预算目前固定为 **¥200**，统计仅包含当天支出，不包含收入和转账。

## 项目结构

```text
.
├── Linmon.xcodeproj/       # Xcode 工程
├── Linmon/
│   ├── LinmonApp.swift     # 应用入口与 SwiftData 容器
│   ├── ContentView.swift   # 概览、账单、记账面板与滑动交互
│   ├── Item.swift          # SwiftData 示例模型
│   ├── Assets.xcassets/    # 图片与颜色资源
│   └── LinmonIcon.icon/    # 分层应用图标
├── LinmonTests/            # 单元测试模板
└── LinmonUITests/          # 启动与启动性能测试
```

## 当前状态

- 应用已初始化 SwiftData 容器，但记账记录尚未接入持久化；`Item` 仍为示例模型。
- 账户列表和余额为示例数据，新增收支或转账不会更新账户余额。
- 日历入口目前展示占位页面，设置页面仅提供演示说明。
- 单元测试仍为模板，UI 测试主要覆盖启动与启动性能，尚未覆盖记账业务流程。

后续可逐步完善账单持久化、账户余额联动、日历查询、自定义预算及业务测试。
