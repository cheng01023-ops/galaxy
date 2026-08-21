import SwiftUI

/// 仪表盘卡片的种类。
enum DashboardCardKind: String, Codable, CaseIterable {
    case weather
    case pomodoro
    case health
    case stepTrend
    case water
    case cppLearning

    var title: String {
        switch self {
        case .weather: return "天气"
        case .pomodoro: return "番茄钟"
        case .health: return "健康"
        case .stepTrend: return "近 7 天步数"
        case .water: return "喝水提醒"
        case .cppLearning: return "C++学习"
        }
    }
}

/// 卡片预设尺寸：半宽或全宽（仪表盘为两列网格）。
enum DashboardCardSize: String, Codable {
    case half
    case full
}

/// 一个仪表盘卡片的布局项（种类 + 预设尺寸 + 顺序）。
struct DashboardLayoutItem: Codable, Identifiable {
    var kind: DashboardCardKind
    var size: DashboardCardSize

    var id: String { kind.rawValue }
}

/// 仪表盘：编辑模式下可上移/下移卡片，并切换半宽/全宽预设尺寸。
struct DashboardView: View {
    @EnvironmentObject private var healthService: HealthService
    @EnvironmentObject private var weatherService: WeatherService

    @State private var layout: [DashboardLayoutItem]
    @State private var isEditing = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    /// 半宽小卡片统一高度，和天气卡片保持一致。
    private let halfCardHeight: CGFloat = 240

    private static let layoutKey = "dashboard.layout.v3"

    private static let defaultLayout: [DashboardLayoutItem] = [
        DashboardLayoutItem(kind: .weather, size: .half),
        DashboardLayoutItem(kind: .pomodoro, size: .half),
        DashboardLayoutItem(kind: .health, size: .half),
        DashboardLayoutItem(kind: .water, size: .half),
        DashboardLayoutItem(kind: .cppLearning, size: .half),
        DashboardLayoutItem(kind: .stepTrend, size: .full)
    ]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.layoutKey),
           let saved = try? JSONDecoder().decode([DashboardLayoutItem].self, from: data) {
            // 自动补齐：老版本保存的布局里没有的新卡片（如喝水提醒）会自动追加。
            var merged = saved
            for kind in DashboardCardKind.allCases where !merged.contains(where: { $0.kind == kind }) {
                merged.append(DashboardLayoutItem(kind: kind, size: kind == .stepTrend ? .full : .half))
            }
            _layout = State(initialValue: merged)
        } else {
            _layout = State(initialValue: Self.defaultLayout)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(layout) { item in
                        cardView(for: item.kind)
                            .gridCellColumns(1)
                            .frame(height: halfCardHeight, alignment: .topLeading)
                            .disabled(isEditing)
                            .overlay(alignment: .topTrailing) {
                                if isEditing {
                                    editControls(for: item)
                                }
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Galaxy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "完成" : "编辑") {
                        withAnimation(.snappy) {
                            isEditing.toggle()
                        }
                    }
                }
            }
            .task {
                await refresh()
            }
            .refreshable {
                await refresh()
            }
        }
    }

    // MARK: - 卡片视图

    @ViewBuilder
    private func cardView(for kind: DashboardCardKind) -> some View {
        switch kind {
        case .weather:
            WeatherCard()
        case .pomodoro:
            PomodoroCard()
        case .health:
            HealthSummaryCard()
        case .stepTrend:
            StepTrendCard()
        case .water:
            WaterReminderCard()
        case .cppLearning:
            CppLearningCard()
        }
    }

    // MARK: - 编辑控件

    @ViewBuilder
    private func editControls(for item: DashboardLayoutItem) -> some View {
        HStack(spacing: 8) {
            Button {
                move(item, by: -1)
            } label: {
                Image(systemName: "arrow.up")
            }
            .disabled(isFirst(item))

            Button {
                move(item, by: 1)
            } label: {
                Image(systemName: "arrow.down")
            }
            .disabled(isLast(item))
        }
        .font(.subheadline.weight(.semibold))
        .padding(8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(8)
    }

    // MARK: - 布局操作

    private func index(of item: DashboardLayoutItem) -> Int? {
        layout.firstIndex(where: { $0.id == item.id })
    }

    private func isFirst(_ item: DashboardLayoutItem) -> Bool {
        index(of: item) == 0
    }

    private func isLast(_ item: DashboardLayoutItem) -> Bool {
        index(of: item) == layout.count - 1
    }

    private func move(_ item: DashboardLayoutItem, by offset: Int) {
        guard let index = index(of: item) else { return }
        let newIndex = index + offset
        guard layout.indices.contains(newIndex) else { return }
        withAnimation(.snappy) {
            layout.swapAt(index, newIndex)
        }
        saveLayout()
    }

    private func toggleSize(_ item: DashboardLayoutItem) {
        guard let index = index(of: item) else { return }
        withAnimation(.snappy) {
            layout[index].size = layout[index].size == .full ? .half : .full
        }
        saveLayout()
    }

    private func saveLayout() {
        guard let data = try? JSONEncoder().encode(layout) else { return }
        UserDefaults.standard.set(data, forKey: Self.layoutKey)
    }

    // MARK: - 数据刷新

    private func refresh() async {
        await healthService.requestAuthorizationAndFetch()
        await weatherService.fetchWeather()
    }
}
