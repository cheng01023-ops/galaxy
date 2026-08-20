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

/// 仪表盘：自由画布布局，编辑时可拖动卡片、拖动右下角箭头调整大小。
struct DashboardView: View {
    @EnvironmentObject private var healthService: HealthService
    @EnvironmentObject private var weatherService: WeatherService

    @State private var layout: [DashboardLayoutItem]
    @State private var isEditing = false

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
                        ForEach($layout) { itemBinding in
                            let item = itemBinding.wrappedValue
                            EditableDashboardCard(
                                item: itemBinding,
                                isEditing: isEditing,
                                canvasWidth: canvasWidth,
                                minCardWidth: minCardWidth,
                                minCardHeight: minCardHeight
                            ) {
                                cardView(for: item.kind)
                            }
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

    // MARK: - 布局工具

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

// MARK: - 可编辑卡片容器

private struct EditableDashboardCard<Content: View>: View {
    @Binding var item: DashboardLayoutItem
    let isEditing: Bool
    let canvasWidth: CGFloat
    let minCardWidth: CGFloat
    let minCardHeight: CGFloat
    @ViewBuilder let content: () -> Content

    @GestureState private var moveTranslation: CGSize = .zero
    @GestureState private var resizeTranslation: CGSize = .zero

    var body: some View {
        content()
            .frame(width: liveWidth, height: liveHeight, alignment: .topLeading)
            .clipped()
            .offset(x: item.x + moveTranslation.width, y: item.y + moveTranslation.height)
            .overlay {
                if isEditing {
                    ZStack(alignment: .topTrailing) {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(moveGesture)
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.caption.weight(.bold))
                            .padding(7)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .allowsHitTesting(false)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isEditing {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .bold))
                        .padding(9)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .contentShape(Rectangle())
                        .gesture(resizeGesture)
                        .padding(8)
                }
            }
    }

    private var liveWidth: CGFloat {
        item.width + (isEditing ? resizeTranslation.width : 0)
    }

    private var liveHeight: CGFloat {
        item.height + (isEditing ? resizeTranslation.height : 0)
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($moveTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let maxX = max(0, canvasWidth - item.width)
                item.x = Double(min(max(0, item.x + value.translation.width), maxX))
                item.y = Double(max(0, item.y + value.translation.height))
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($resizeTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let maxWidth = max(minCardWidth, canvasWidth - item.x)
                item.width = Double(min(max(minCardWidth, item.width + value.translation.width), maxWidth))
                item.height = Double(max(minCardHeight, item.height + value.translation.height))
            }
    }
}
