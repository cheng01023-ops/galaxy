import SwiftUI

/// 喝水提醒详情页：自定义每天的提醒时间。
struct WaterReminderDetailView: View {
    @ObservedObject private var service = WaterReminderService.shared
    @State private var isAdding = false
    @State private var newDate = Date()
    @State private var showLiveAlert = false

    var body: some View {
        List {
            Section("每天提醒时间") {
                if service.reminders.isEmpty {
                    Text("还没有提醒")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(service.reminders) { reminder in
                        HStack {
                            Text(String(format: "%02d:%02d", reminder.hour, reminder.minute))
                                .font(.body.monospacedDigit())
                            Spacer()
                        }
                    }
                    .onDelete(perform: delete)
                }
            }

            Section {
                Button {
                    isAdding = true
                } label: {
                    Label("添加提醒", systemImage: "plus")
                }
            }

            Section {
                Button {
                    if !service.triggerLiveActivity() {
                        showLiveAlert = true
                    }
                } label: {
                    Label("测试灵动岛（8秒）", systemImage: "iphone.dynamic.island")
                }
            } footer: {
                Text("测试时请保持 App 在前台。如果点了没反应，请到 设置 → Galaxy → 实时活动 开启后重试。")
            }
        }
        .navigationTitle("喝水提醒")
        .alert("实时活动未开启", isPresented: $showLiveAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text("请到 设置 → Galaxy → 实时活动 开启后重试。")
        }
        .sheet(isPresented: $isAdding) {
            NavigationStack {
                DatePicker("提醒时间", selection: $newDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .navigationTitle("添加提醒时间")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { isAdding = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("添加") {
                                addReminder()
                                isAdding = false
                            }
                        }
                    }
            }
            .presentationDetents([.height(320)])
        }
    }

    private func addReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
        let reminder = WaterReminder(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
        service.save(service.reminders + [reminder])
    }

    private func delete(at offsets: IndexSet) {
        var list = service.reminders
        list.remove(atOffsets: offsets)
        service.save(list)
    }
}
