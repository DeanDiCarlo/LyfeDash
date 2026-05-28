import SwiftUI

enum Brand {
    enum ColorToken {
        static let paper = Color(red: 0.957, green: 0.937, blue: 0.894)
        static let paperElevated = Color(red: 1.000, green: 0.976, blue: 0.929)
        static let forestInk = Color(red: 0.078, green: 0.208, blue: 0.169)
        static let moss = Color(red: 0.376, green: 0.486, blue: 0.345)
        static let sage = Color(red: 0.659, green: 0.718, blue: 0.604)
        static let cork = Color(red: 0.753, green: 0.604, blue: 0.384)
        static let copper = Color(red: 0.725, green: 0.435, blue: 0.235)
        static let electricTeal = Color(red: 0.220, green: 0.780, blue: 0.718)
        static let paleGold = Color(red: 0.851, green: 0.725, blue: 0.357)
        static let rust = Color(red: 0.631, green: 0.306, blue: 0.220)
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 8
        static let control: CGFloat = 8
    }
}

struct PaperCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Brand.Spacing.md)
            .background(Brand.ColorToken.paperElevated)
            .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .stroke(Brand.ColorToken.cork.opacity(0.35), lineWidth: 1)
            }
    }
}

