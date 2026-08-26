# CODEX_CONTEXT

本工作区专职负责 **大学课程表** 模块。

## 代码主路径

- `LifeDashboard/Models/TimetableCourse.swift`（SwiftData 模型 Course / WeekPattern）
- `LifeDashboard/ViewModels/TimetableViewModel.swift`（学期设置 + 小组件数据同步）
- `LifeDashboard/Services/TimetableReminderService.swift`（上课提醒通知）
- `LifeDashboard/Utilities/TimetableSharedStore.swift`（App Group 共享数据，主 App 与小组件共用）
- `LifeDashboard/Views/TimetableHomeView.swift`（今日 / 周课表 / 全部课程）
- `LifeDashboard/Views/TimetableCourseEditorView.swift`（课程新增/编辑表单）
- `LifeDashboard/Views/TimetableSettingsView.swift`（学期开始日期等设置）
- `LifeDashboard/Views/Components/TimetableCard.swift`（仪表盘入口卡片）
- `LifeDashboardWidgets/TimetableWidget.swift`（桌面小组件）

## 只读依赖（可引用，不要修改）

- `LifeDashboard/Views/DashboardView.swift`（课程表卡片在仪表盘中的入口）
- `LifeDashboard/AppMain.swift`（SwiftData schema 已包含 `Course.self`）
- `LifeDashboard/Utilities/Color+App.swift`（`Color(hex:)` 与 `TimetablePalette` 配色）
- `LifeDashboard/LifeDashboard.entitlements`、`LifeDashboardWidgets/LifeDashboardWidgets.entitlements`（App Group）
- `LifeDashboardWidgets/LifeDashboardWidgetBundle.swift`（小组件入口已注册 `TimetableWidget()`）
- `work/make_pbxproj.py`（工程文件生成器；新增文件需在此登记后重新生成）

## 约束

- 禁止修改其他板块的代码。
- App Group ID 固定为 `group.com.k4rulxu3k4.Galaxy`，不要更改，否则小组件无法读取课程数据。
- 本板块开发完成并验证通过后，自动提交到 `feature/timetable` 分支。
