import SwiftUI

/// 智能天气卡片：当前温度、天气状况、今日最高/最低温与建议。
struct WeatherCard: View {
    @EnvironmentObject private var weatherService: WeatherService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("天气", systemImage: "cloud.sun.fill")
                    .font(.headline)
                Spacer()
                if weatherService.isLoading {
                    ProgressView()
                }
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
    }
}
