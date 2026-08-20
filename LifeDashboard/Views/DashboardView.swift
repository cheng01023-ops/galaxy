import SwiftUI
import UIKit

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

/// 一个仪表盘卡片的自由布局项（位置 + 宽高）。
struct DashboardLayoutItem: Codable, Identifiable {
    var kind: DashboardCardKind
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    var id: String { kind.rawValue }
}

/// 仪表盘：自由画布布局，编辑时可拖动卡片位置、拖动右下角箭头调整大小。
struct DashboardView: View {
    @EnvironmentObject private var healthService: HealthService
    @EnvironmentObject private var weatherService: WeatherService

    @State private var layout: [DashboardLayoutItem]
    @State private var isEditing = false

    @State private var movingItemID: String?
    @State private var moveStartPoint: CGPoint = .zero
    @State private var resizingItemID: String?
    @State private var resizeStartSize: CGSize = .zero

    private static let layoutKey = "dashboard.layout.v2"
    private let minCardWidth: CGFloat = 120
    private let minCardHeight: CGFloat = 120
    private let cardSpacing: CGFloat = 12

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.layoutKey),
           let saved = try? JSONDecoder().decode([DashboardLayoutItem].self, from: data) {
            _layout = State(initialValue: saved)
        } else {
            _layout = State(initialValue: Self.makeDefaultLayout())
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let canvasWidth = max(280, geo.size.width - cardSpacing * 2)
                let canvasHeight = max(600, (layout.map { $0.y + $0.height }.max() ?? 600) + 40)

                ScrollView {
                    ZStack(alignment: .topLeading) {
                        ForEach(layout) { item in
                            cardView(for: item.kind)
                                .frame(width: item.width, height: item.height, alignment: .topLeading)
                                .clipped()
                                .offset(x: item.x, y: item.y)
                                .contentShape(Rectangle())
                                .disabled(isEditing)
                                .overlay(alignment: .bottomTrailing) {
                                    if isEditing {
                                        resizeHandle(for: item, canvasWidth: canvasWidth)
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if isEditing {
                                        moveHint(for: item)
                                    }
                                }
                                .gesture(isEditing ? moveGesture(for: item, canvasWidth: canvasWidth) : nil)
                        }
                    }
                    .frame(width: canvasWidth, height: canvasHeight, alignment: .topLeading)
                    .padding(.horizontal, cardSpacing)
                }
                .scrollDisabled(isEditing)
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
    private func moveHint(for item: DashboardLayoutItem) -> some View {
        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
            .font(.caption.weight(.bold))
            .padding(7)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(8)
    }

    @ViewBuilder
    private func resizeHandle(for item: DashboardLayoutItem, canvasWidth: CGFloat) -> some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 14, weight: .bold))
            .padding(9)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
            .gesture(resizeGesture(for: item, canvasWidth: canvasWidth))
            .padding(8)
    }

    // MARK: - 手势

    private func moveGesture(for item: DashboardLayoutItem, canvasWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if movingItemID != item.id {
                    movingItemID = item.id
                    moveStartPoint = CGPoint(x: item.x, y: item.y)
                }
                guard let index = index(of: item) else { return }
                let maxX = max(0, canvasWidth - item.width)
                let newX = min(max(0, moveStartPoint.x + value.translation.width), maxX)
                let newY = max(0, moveStartPoint.y + value.translation.height)
                layout[index].x = Double(newX)
                layout[index].y = Double(newY)
            }
            .onEnded { _ in
                movingItemID = nil
                saveLayout()
            }
    }

    private func resizeGesture(for item: DashboardLayoutItem, canvasWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if resizingItemID != item.id {
                    resizingItemID = item.id
                    resizeStartSize = CGSize(width: item.width, height: item.height)
                }
                guard let index = index(of: item) else { return }
                let maxWidth = max(minCardWidth, canvasWidth - item.x)
                let newWidth = min(max(minCardWidth, resizeStartSize.width + value.translation.width), maxWidth)
                let newHeight = max(minCardHeight, resizeStartSize.height + value.translation.height)
                layout[index].width = Double(newWidth)
                layout[index].height = Double(newHeight)
            }
            .onEnded { _ in
                resizingItemID = nil
                saveLayout()
            }
    }

    // MARK: - 布局工具

    private func index(of item: DashboardLayoutItem) -> Int? {
        layout.firstIndex(where: { $0.id == item.id })
    }

    private func saveLayout() {
        guard let data = try? JSONEncoder().encode(layout) else { return }
        UserDefaults.standard.set(data, forKey: Self.layoutKey)
    }

    private static func makeDefaultLayout() -> [DashboardLayoutItem] {
        let canvasWidth = UIScreen.main.bounds.width - 24
        let half = (canvasWidth - 12) / 2
        return [
            DashboardLayoutItem(kind: .weather, x: 0, y: 0, width: half, height: 230),
            DashboardLayoutItem(kind: .pomodoro, x: Double(half + 12), y: 0, width: half, height: 230),
            DashboardLayoutItem(kind: .health, x: 0, y: 242, width: half, height: 230),
            DashboardLayoutItem(kind: .stepTrend, x: 0, y: 484, width: canvasWidth, height: 240)
        ]
    }

    // MARK: - 数据刷新

    private func refresh() async {
        await healthService.requestAuthorizationAndFetch()
        await weatherService.fetchWeather()
    }
}
