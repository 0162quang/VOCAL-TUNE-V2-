import SwiftUI

/// Hệ thiết kế: nền đen thuần (OLED), bề mặt phẳng, viền mảnh. Không blur, không bóng đổ lớn.
/// Mọi vùng chạm tối thiểu 44 pt.
enum Theme {
    static let bg = Color.black
    static let surface = Color(red: 0.055, green: 0.055, blue: 0.075)
    static let surface2 = Color(red: 0.09, green: 0.09, blue: 0.12)
    static let hairline = Color.white.opacity(0.08)
    static let text = Color.white.opacity(0.92)
    static let textDim = Color.white.opacity(0.58)
    static let accent = Color(red: 0.55, green: 0.36, blue: 0.98)
    static let accent2 = Color(red: 0.93, green: 0.28, blue: 0.60)
    static let cyan = Color(red: 0.13, green: 0.83, blue: 0.93)
    static let good = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let warn = Color(red: 1.0, green: 0.70, blue: 0.20)
    static let rec = Color(red: 1.0, green: 0.23, blue: 0.30)

    static var gradient: LinearGradient {
        LinearGradient(colors: [accent, accent2], startPoint: .leading, endPoint: .trailing)
    }
}

extension View {
    func card(radius: CGFloat = 18) -> some View {
        background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
    }
}

/// Chip bấm được, cao tối thiểu 44 pt.
struct Chip: View {
    let icon: String?
    let text: String
    var tint: Color = Theme.textDim
    var filled = false

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 14, weight: .semibold)) }
            Text(text).font(.system(size: 14, weight: .semibold, design: .rounded)).lineLimit(1)
        }
        .foregroundStyle(filled ? Color.black : tint)
        .padding(.horizontal, 14).frame(minHeight: 44)
        .background(filled ? tint : Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .contentShape(Capsule())
    }
}

/// Nút tròn có nhãn bên dưới (hàng điều khiển dưới cùng).
struct RoundAction: View {
    let icon: String
    let label: String
    var active = false
    var tint: Color = Theme.good
    var badge: Int = 0

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon).font(.system(size: 22, weight: .medium))
                    .foregroundStyle(active ? Color.black : Theme.text)
                    .frame(width: 56, height: 56)
                    .background(active ? tint : Theme.surface, in: Circle())
                    .overlay(Circle().stroke(Theme.hairline, lineWidth: 1))
                if badge > 0 {
                    Text("\(badge)").font(.system(size: 11, weight: .bold)).foregroundStyle(.black)
                        .padding(.horizontal, 6).frame(minWidth: 20, minHeight: 20)
                        .background(Theme.accent, in: Capsule()).offset(x: 4, y: -2)
                }
            }
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(active ? tint : Theme.textDim)
        }
        .frame(minWidth: 64, minHeight: 44)
        .contentShape(Rectangle())
    }
}

struct BannerView: View {
    let banner: Banner
    var body: some View {
        let tint = banner.level == .danger ? Theme.rec : (banner.level == .warn ? Theme.warn : Theme.cyan)
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: banner.icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(tint).frame(width: 22)
            Text(banner.text).font(.system(size: 14)).foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tint.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

func noteLabel(_ midi: Int) -> String {
    "\(noteNames[((midi % 12) + 12) % 12])\(midi / 12 - 1)"
}
