import SwiftUI

struct AverageProgressBar: View {
    let average: Double

    var progress: Double {
        (average - 1) / 4
    }

    var color: Color {
        switch average {
        case 4.5...: return .green
        case 3.5..<4.5: return .blue
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.3))

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        VStack(alignment: .leading) {
            Text("5.0 - Excellent")
                .font(.caption)
            AverageProgressBar(average: 5.0)
        }

        VStack(alignment: .leading) {
            Text("4.2 - Good")
                .font(.caption)
            AverageProgressBar(average: 4.2)
        }

        VStack(alignment: .leading) {
            Text("3.0 - Average")
                .font(.caption)
            AverageProgressBar(average: 3.0)
        }

        VStack(alignment: .leading) {
            Text("2.0 - Below Average")
                .font(.caption)
            AverageProgressBar(average: 2.0)
        }

        VStack(alignment: .leading) {
            Text("1.2 - Poor")
                .font(.caption)
            AverageProgressBar(average: 1.2)
        }
    }
    .padding()
}
