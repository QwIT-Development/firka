import SwiftUI

struct SubjectRow: View {
    let name: String
    let average: Double?
    let gradeCount: Int

    var averageColor: Color {
        guard let avg = average else { return .gray }
        switch avg {
        case 4.5...: return .green
        case 3.5...: return .blue
        case 2.5...: return .yellow
        case 1.5...: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()

            if let avg = average {
                Text(String(format: "%.2f", avg))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(averageColor)
            } else {
                Text("\(gradeCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(white: 0.15))
        .cornerRadius(6)
    }
}
