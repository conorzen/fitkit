

import SwiftUI

struct StatCard: View {
    let stat: StatItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stat.title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(stat.value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(stat.unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 2) {
                Image(systemName: stat.trend.hasPrefix("+") ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text(stat.trend)
                    .font(.caption)
            }
            .foregroundColor(stat.trend.hasPrefix("+") ? .customColors.emerald : .customColors.rose)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8)
    }
}