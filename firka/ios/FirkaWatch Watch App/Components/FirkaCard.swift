import SwiftUI

struct FirkaCard<Content: View>: View {
    let content: Content
    var isHighlighted: Bool = false
    var backgroundColor: Color? = nil

    init(
        isHighlighted: Bool = false,
        backgroundColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isHighlighted = isHighlighted
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(
                backgroundColor ??
                    (isHighlighted ? Color.green.opacity(0.2) : Color(white: 0.12))
            )
            .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 12) {
        FirkaCard {
            Text("Normal Card")
                .foregroundColor(.primary)
        }

        FirkaCard(isHighlighted: true) {
            Text("Highlighted Card")
                .foregroundColor(.primary)
        }
    }
    .padding()
}
