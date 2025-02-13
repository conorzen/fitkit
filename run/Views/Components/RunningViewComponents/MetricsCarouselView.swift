 
 import SwiftUI
 import HealthKit
 
 struct MetricsCarouselView: View {
    @State private var currentPage = 0
    private let metrics: [MetricComparison] = [
        MetricComparison(
            title: "Weekly Distance",
            currentValue: "32.5",
            previousValue: "28.2",
            unit: "km",
            trend: "+15%",
            icon: "figure.run",
            gradient: [.customColors.emerald, .customColors.teal]
        ),
        MetricComparison(
            title: "Average Pace",
            currentValue: "5:32",
            previousValue: "5:45",
            unit: "/km",
            trend: "-2%",
            icon: "speedometer",
            gradient: [.customColors.blue, .customColors.indigo]
        ),
        MetricComparison(
            title: "Total Time",
            currentValue: "3:45",
            previousValue: "3:15",
            unit: "hours",
            trend: "+15%",
            icon: "clock.fill",
            gradient: [.customColors.purple, .customColors.indigo]
        ),
        MetricComparison(
            title: "Calories",
            currentValue: "2,450",
            previousValue: "2,100",
            unit: "kcal",
            trend: "+16%",
            icon: "flame.fill",
            gradient: [.customColors.orange, .customColors.red]
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.title3)
                .fontWeight(.bold)
            
            TabView(selection: $currentPage) {
                ForEach(metrics.indices, id: \.self) { index in
                    MetricComparisonCard(metric: metrics[index])
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
        }
    }
}

struct MetricComparison: Identifiable {
    let id = UUID()
    let title: String
    let currentValue: String
    let previousValue: String
    let unit: String
    let trend: String
    let icon: String
    let gradient: [Color]
}

struct MetricComparisonCard: View {
    let metric: MetricComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon
            HStack {
                Image(systemName: metric.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(metric.title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Current value
            HStack(alignment: .lastTextBaseline) {
                Text(metric.currentValue)
                    .font(.system(size: 36, weight: .bold))
                Text(metric.unit)
                    .font(.body)
            }
            .foregroundColor(.white)
            
            // Comparison section
            HStack {
                VStack(alignment: .leading) {
                    Text("Last Week")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text(metric.previousValue)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Trend indicator
                HStack {
                    Image(systemName: metric.trend.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                    Text(metric.trend)
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: metric.gradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: metric.gradient[0].opacity(0.3), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

#Preview {
    MetricsCarouselView()
    
}
