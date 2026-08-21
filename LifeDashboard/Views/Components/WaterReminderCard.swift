import SwiftUI

/// 仪表盘上的喝水提醒卡片，点击进入详情页。
struct WaterReminderCard: View {
    @ObservedObject private var service = WaterReminderService.shared

    var body: some View {
        NavigationLink {
            WaterReminderDetailView()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("喝水提醒", systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)

                if let next = service.nextReminder() {
                    Text(String(format: "下次 %02d:%02d", next.hour, next.minute))
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Text("已设置 \(service.reminders.count) 个提醒")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
