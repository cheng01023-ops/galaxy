import SwiftUI

/// 仪表盘卡片的种类。
enum DashboardCardKind: String, Codable, CaseIterable {
    case weather
    case pomodoro
    case health
    case stepTrend

    var title: String {
        switch self {
        case .weather: return "天气"
        case .pomodoro: return "番茄钟"
        case .health: return "健康"
        case .stepTrend: return "近 7 天步数"
        }
    }
}

/// 卡片尺寸：半宽或全宽（仪表盘为两列网格）。
enum DashboardCardSize: String, Codable {
    case half
    case full
}

/// 一个仪表盘卡片的布局项（种类 + 尺寸 + 顺序）。
struct DashboardLayoutItem: Codable, Identifiable {
    var kind: DashboardCardKind
    var size: DashboardCardSize

    var id: String { kind.rawValue }
}

/// 仪表盘：支持编辑模式，自定义卡片大小和摆放位置。
struct DashboardView: View {
    @EnvironmentObject private var healthService: HealthService
    @EnvironmentObject private var weatherService: WeatherService

    @State private var layout: [DashboardLayoutItem]
    @State private var isEditing = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private static let layoutKey = "dashboard.layout.v1"

    private static let defaultLayout: [DashboardLayoutItem] = [
        DashboardLayoutItem(kind: .weather, size: .half),
        DashboardLayoutItem(kind: .pomodoro, size: .half),
        DashboardLayoutItem(kind: .health, size: .half),
        DashboardLayoutItem(kind: .stepTrend, size: .full)
    ]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.layoutKey),
           let saved = try? JSONDecoder().decode([DashboardLayoutItem].self, from: data) {
            _layout = State(initialValue: saved)
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
                            .gridCellColumns(item.size == .full ? 2 : 1)
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
            .navigationTitle("仪表盘")
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
        }
    }

    // MARK: - 编辑控件

    @ViewBuilder
    private func editControls(for item: DashboardLayoutItem) -> some View {
        VStack(spacing: 6) {
            Text(item.kind.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

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

                Button {
                    toggleSize(item)
                } label: {
                    Image(systemName: item.size == .full ? "rectangle.split.1x2" : "rectangle.split.2x1")
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
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
