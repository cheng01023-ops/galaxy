# 智能生活仪表盘（LifeDashboard）

一个面向 iPhone 的个人生活助手 App，使用 SwiftUI 编写，目标兼容 iOS 17+，并遵循 Apple 人机界面指南。

## 功能模块

1. **健康摘要卡片**：HealthKit 读取今日步数、昨晚睡眠时长、静息心率，并用 Charts 绘制近 7 天步数趋势。
2. **智能天气卡片**：OpenWeatherMap 免费 API，显示当前温度、天气状况、今日最高/最低温，并根据天气和本地时间给出建议。
3. **专注计时器（番茄钟）**：25 分钟工作 + 5 分钟休息，支持开始/暂停/重置，使用 ActivityKit 实现灵动岛与锁屏实时活动，计时结束发送本地通知。
4. **动态待办清单**：SwiftData 本地持久化，支持优先级排序、滑动删除、点击切换完成状态、新建与编辑。
5. **iPhone 主屏幕小组件**：提供小/中/大三种尺寸的天气小组件，无需登录，可直接添加到主屏幕。
6. **每周小结**：每周日生成报告，聚合本周总步数、平均睡眠、专注总时长，并支持“分享为图片”。

## 技术栈

- UI：SwiftUI（TabView + LazyVGrid 圆角卡片）
- 持久化：SwiftData
- 图表：Apple Charts
- 系统框架：HealthKit、ActivityKit、UserNotifications
- 网络：URLSession + async/await
- JSON：Codable

## 项目结构

```
LifeDashboard.xcodeproj
LifeDashboard/
  AppMain.swift
  Models/          # TodoItem, HealthSummary, WeatherData, FocusSession, WeeklyReport, PomodoroAttributes
  Views/           # RootTabView, DashboardView, TodoListView, TodoEditorView, StatisticsView, Components/
  ViewModels/      # PomodoroViewModel
  Services/        # HealthService, WeatherService, NotificationService
  Utilities/       # Formatters, Color+App, WeatherAdvice
  Assets.xcassets
LifeDashboardWidgets/   # 灵动岛 / 锁屏实时活动 Widget Extension
```

## 运行步骤

1. 使用 Xcode 15 或更高版本打开 `LifeDashboard.xcodeproj`。
2. 在 `LifeDashboard/Services/WeatherService.swift` 中填入你的 OpenWeatherMap API Key：

   ```swift
   // TODO: 填入你的 Key
   private let apiKey = ""
   ```

   免费 Key 申请地址：https://home.openweathermap.org/api_keys
3. 在 Target `LifeDashboard` 的 Signing & Capabilities 中选择你的开发团队。
4. HealthKit 权限描述已配置在 `Info.plist`；HealthKit 数据需在**真机**上测试，模拟器不可用。
5. 灵动岛 / 锁屏实时活动需在支持灵动岛或锁屏实时活动的真机上测试。

## 权限说明

- `NSHealthShareUsageDescription`：读取步数、睡眠、心率。
- `NSHealthUpdateUsageDescription`：本应用不写入 HealthKit 数据。
- HealthKit entitlement 已配置于 `LifeDashboard/LifeDashboard.entitlements`。
- `NSSupportsLiveActivities` 已配置，支持实时活动。
