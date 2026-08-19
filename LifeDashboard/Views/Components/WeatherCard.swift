import SwiftUI

/// 智能天气卡片：当前温度、天气状况、今日最高/最低温与建议，并支持地区切换。
struct WeatherCard: View {
    @EnvironmentObject private var weatherService: WeatherService

    @State private var showsCustomCityAlert = false
    @State private var customCityText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("天气", systemImage: "cloud.sun.fill")
                    .font(.headline)
                Spacer()
                if weatherService.isLoading {
                    ProgressView()
                }
                regionMenu
            }

            if let weather = weatherService.weather {
                Text(weather.city)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int(weather.temperature.rounded()))°")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                    Text(weather.condition)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label("最高 \(Int(weather.high.rounded()))°", systemImage: "arrow.up")
                    Label("最低 \(Int(weather.low.rounded()))°", systemImage: "arrow.down")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Text(weatherService.advice)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else if let error = weatherService.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("天气数据加载中…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
        .alert("自定义城市", isPresented: $showsCustomCityAlert) {
            TextField("输入城市名，如 上海 / Shanghai", text: $customCityText)
            Button("确定") {
                weatherService.setCity(customCityText)
                customCityText = ""
            }
            Button("取消", role: .cancel) {
                customCityText = ""
            }
        } message: {
            Text("输入城市名称后，天气卡片会立即切换到该地区。")
        }
    }

    /// 地区切换菜单：内置常用城市 + 自定义城市入口。
    private var regionMenu: some View {
        Menu {
            ForEach(WeatherService.supportedRegions) { region in
                Button {
                    weatherService.selectRegion(region)
                } label: {
                    if isSelected(region) {
                        Label(region.name, systemImage: "checkmark")
                    } else {
                        Text(region.name)
                    }
                }
            }

            Divider()

            Button {
                customCityText = weatherService.city
                showsCustomCityAlert = true
            } label: {
                Label("自定义城市…", systemImage: "text.cursor")
            }
        } label: {
            Image(systemName: "location.circle")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel("切换天气地区")
    }

    private func isSelected(_ region: WeatherRegion) -> Bool {
        weatherService.city == region.query || weatherService.city == region.name
    }
}
