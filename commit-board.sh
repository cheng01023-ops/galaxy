#!/bin/bash
set -euo pipefail
BOARD="timetable"
MSG="${1:-}"
if [ -z "$MSG" ]; then
  MSG="feat(${BOARD}): 自动提交"
fi
cd "$(dirname "$0")"
git add LifeDashboard/Models/TimetableCourse.swift \
        LifeDashboard/ViewModels/TimetableViewModel.swift \
        LifeDashboard/Services/TimetableReminderService.swift \
        LifeDashboard/Utilities/TimetableSharedStore.swift \
        LifeDashboard/Views/TimetableHomeView.swift \
        LifeDashboard/Views/TimetableCourseEditorView.swift \
        LifeDashboard/Views/TimetableSettingsView.swift \
        LifeDashboard/Views/Components/TimetableCard.swift \
        LifeDashboardWidgets/TimetableWidget.swift \
        LifeDashboard/Views/DashboardView.swift \
        LifeDashboard/AppMain.swift \
        LifeDashboard/Utilities/Color+App.swift \
        LifeDashboard/LifeDashboard.entitlements \
        LifeDashboardWidgets/LifeDashboardWidgets.entitlements \
        LifeDashboardWidgets/LifeDashboardWidgetBundle.swift \
        LifeDashboard.xcodeproj/project.pbxproj \
        work/make_pbxproj.py
if git diff --cached --quiet; then
  echo "本板块没有待提交的改动。"
  exit 0
fi
git commit -m "$MSG"
echo "已自动提交：$MSG"
