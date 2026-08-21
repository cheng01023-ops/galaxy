import SwiftUI

/// 喝水提醒详情页：自定义每天的提醒时间。
struct WaterReminderDetailView: View {
    @ObservedObject private var service = WaterReminderService.shared
    @State private var isAdding = false
    @State private var newDate = Date()

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

        }
        .navigationTitle("喝水提醒")
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
