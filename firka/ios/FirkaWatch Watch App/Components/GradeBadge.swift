import SwiftUI

struct GradeBadge: View {
    let grade: Int
    var size: CGFloat = 24

    var color: Color {
        switch grade {
        case 5: return .green
        case 4: return .blue
        case 3: return .yellow
        case 2: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)

            Text("\(grade)")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        GradeBadge(grade: 5)
        GradeBadge(grade: 4)
        GradeBadge(grade: 3)
        GradeBadge(grade: 2)
        GradeBadge(grade: 1)
    }
    .padding()
}
