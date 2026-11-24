import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var m = model
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                TopBar()
                if let b = model.banner { BannerView(banner: b).transition(.opacity) }
                RollPanel().frame(minHeight: 150, maxHeight: .infinity)
                BeatCard()
                PresetStrip()
                KnobRow()
                TransportBar()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            .animation(.easeOut(duration: 0.2), value: model.banner)

            VStack(spacing: 8) {
                if let t = model.toast {
                    Label(t.text, systemImage: t.icon).font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Theme.surface2, in: Capsule()).overlay(Capsule().stroke(Theme.hairline))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { model.toast = nil }
                }
                if let t = model.busyText {
                    HStack(spacing: 8) { ProgressView().tint(.white); Text(t).font(.system(size: 14, weight: .semibold)) }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(Theme.surface2, in: Capsule()).overlay(Capsule().stroke(Theme.hairline))
                }
            }
            .padding(.top, 62).animation(.easeOut(duration: 0.2), value: model.toast)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .sheet(item: $m.sheet) { kind in
            Group {
                switch kind {
                case .advanced: AdvancedSheet()
                case .scale: ScaleSheet()
                case .takes: TakesSheet()
                }
            }
            .environment(model)
            .presentationDetents(kind == .scale ? [.medium, .large] : [.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.surface)
        }
        .fileImporter(isPresented: $m.showBeatImporter, allowedContentTypes: [.audio]) { model.importBeat($0) }
        .alert("Có lỗi", isPresented: Binding(get: { model.errorMessage != nil },
                                               set: { if !$0 { model.errorMessage = nil; model.errorOpensSettings = false } })) {
            if model.errorOpensSettings {
                Button("Mở Cài đặt") {
                    if let u = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(u) }
                }
            }
            Button("Đóng", role: .cancel) {}
        } message: { Text(model.errorMessage ?? "") }
    }
}

// MARK: Thanh trên: Key (chính) + trạng thái tuyến âm thanh

struct TopBar: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        HStack(spacing: 10) {
            Button { model.sheet = .scale } label: {
                HStack(spacing: 10) {
                    Image(systemName: "pianokeys").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("KEY").font(.system(size: 10, weight: .bold)).foregroundStyle(Theme.textDim)
                        Text(model.keyTitle).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Theme.text)
                    }
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.textDim)
                }
                .padding(.horizontal, 14).frame(height: 48).card(radius: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Key và scale: \(model.keyTitle)")

            Spacer(minLength: 0)

            if model.saverMode {
                Image(systemName: "leaf.fill").foregroundStyle(Theme.good).frame(width: 44, height: 44)
                    .accessibilityLabel("Đang ở chế độ tiết kiệm pin")
            }
            Menu {
                Section("Đầu ra: \(model.route.title)") {
                    Button("Độ trễ ước tính \(model.latencyText)") {}.disabled(true)
                    if model.route == .speaker {
                        Toggle("Cho phép nghe giọng khi ra loa (dễ hú)", isOn: Binding(
                            get: { model.forceMonitor },
                            set: { model.forceMonitor = $0; model.settingsChanged(keepPreset: true) }))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: model.route.icon).font(.system(size: 16, weight: .semibold))
                    Text(model.latencyText).font(.system(size: 14, weight: .semibold, design: .rounded)).monospacedDigit()
                }
                .foregroundStyle(model.route == .wired ? Theme.good : Theme.warn)
                .padding(.horizontal, 14).frame(height: 44).card(radius: 22)
            }
            .accessibilityLabel("Đầu ra \(model.route.title), độ trễ \(model.latencyText)")
        }
        .frame(height: 52)
    }
}

// MARK: Vùng biểu đồ cao độ + hướng dẫn khi chưa chạy

struct RollPanel: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        ZStack {
            PitchRollView()
            if !model.engineRunning { StartGuide() }
            if model.isRecording, let start = model.recordStart {
                HStack(spacing: 6) {
                    Circle().fill(Theme.rec).frame(width: 9, height: 9)
                    TimelineView(.periodic(from: start, by: 1)) { ctx in
                        let s = max(0, Int(ctx.date.timeIntervalSince(start)))
                        Text(String(format: "%02d:%02d", s / 60, s % 60))
                            .font(.system(size: 15, weight: .bold, design: .rounded)).monospacedDigit()
                    }
                }
                .padding(.horizontal, 12).frame(height: 32)
                .background(Theme.rec.opacity(0.18), in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 10).padding(.trailing, 20)
                .accessibilityLabel("Đang thu")
            }
        }
    }
}

struct StartGuide: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Sẵn sàng hát?").font(.system(size: 20, weight: .bold, design: .rounded))
            step(model.route == .wired ? "checkmark.circle.fill" : "headphones",
                 model.route == .wired ? Theme.good : Theme.warn,
                 model.route == .wired ? "Đã có tai nghe" : "Cắm tai nghe có dây để nghe giọng đã chỉnh, tránh hú và trễ")
            Button { model.sheet = .scale } label: {
                step("pianokeys", Theme.accent, "Key hiện tại \(model.keyTitle). Chạm để đổi hoặc nhận từ beat")
            }.buttonStyle(.plain)
            step("ear", Theme.cyan, "Nhấn «Hát thử» để nghe thử, rồi «Thu» khi sẵn sàng")
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func step(_ icon: String, _ tint: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(tint).frame(width: 26)
            Text(text).font(.system(size: 15)).foregroundStyle(Theme.text).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 44)
    }
}

// MARK: Beat

struct BeatCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if let name = model.beatName { loaded(name) } else { empty }
        }
        .card()
    }

    private var empty: some View {
        Button { model.showBeatImporter = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(Theme.cyan)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Thêm nhạc nền").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
                    Text("Tùy chọn · tự nhận key của beat").font(.system(size: 12)).foregroundStyle(Theme.textDim)
                }
                Spacer()
            }
            .padding(.horizontal, 14).frame(height: 60).contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func loaded(_ name: String) -> some View {
        HStack(spacing: 4) {
            Button { model.toggleBeatPreview() } label: {
                Image(systemName: model.beatPreviewing ? "pause.fill" : "play.fill").font(.system(size: 18))
                    .foregroundStyle(model.isRecording ? Theme.textDim : Theme.cyan).frame(width: 52, height: 52)
            }
            .disabled(model.isRecording)
            .accessibilityLabel(model.beatPreviewing ? "Dừng beat" : "Nghe thử beat")

            VStack(alignment: .leading, spacing: 6) {
                Text(name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                TimelineView(.animation(minimumInterval: 0.25, paused: !(model.beatPreviewing || model.isRecording))) { _ in
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.10))
                            Capsule().fill(Theme.cyan).frame(width: g.size.width * model.beatProgress)
                        }
                    }
                }
                .frame(height: 4)
            }

            Menu {
                Button("Nhận lại key từ beat", systemImage: "wand.and.stars") { model.redetectKey() }
                Button("Đổi nhạc nền", systemImage: "folder") { model.showBeatImporter = true }
                Button("Bỏ nhạc nền", systemImage: "trash", role: .destructive) { model.removeBeat() }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.textDim)
                    .frame(width: 52, height: 52).contentShape(Rectangle())
            }
            .accessibilityLabel("Tùy chọn beat")
        }
        .padding(.leading, 4).frame(height: 60)
    }
}

// MARK: Preset

struct PresetStrip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if model.presetID == nil { card(id: "custom", name: "Tùy chỉnh", sub: "Đã sửa tay", selected: true) {} }
                    ForEach(Preset.all) { p in
                        card(id: p.id, name: p.name, sub: p.subtitle, selected: model.presetID == p.id) { model.applyPreset(p) }
                    }
                }
                .padding(.horizontal, 1)
            }
            .onChange(of: model.presetID) { _, id in withAnimation { proxy.scrollTo(id ?? "custom", anchor: .center) } }
        }
        .frame(height: 64)
    }

    private func card(id: String, name: String, sub: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(selected ? Theme.text : Theme.text.opacity(0.85))
                Text(sub).font(.system(size: 12)).foregroundStyle(Theme.textDim).lineLimit(1)
            }
            .padding(.horizontal, 14).frame(width: 128, height: 62, alignment: .leading)
            .background(selected ? Theme.accent.opacity(0.18) : Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Theme.hairline), lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(.plain).id(id)
        .accessibilityLabel("\(name), \(sub)").accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: Núm chỉnh nhanh

struct KnobRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                KnobView(title: "Retune", value: model.binding(\.retuneMs), range: 0...400, defaultValue: 80) { $0 < 1 ? "Robot" : "\(Int($0))ms" }
                Spacer(minLength: 0)
                KnobView(title: "Amount", value: model.binding(\.amount), range: 0...1, defaultValue: 1) { "\(Int($0 * 100))%" }
                Spacer(minLength: 0)
                KnobView(title: "Formant", value: model.binding(\.formantSemis), range: -4...4, defaultValue: 0) { String(format: "%+.1f", $0) }
                Spacer(minLength: 0)
                KnobView(title: "Reverb", value: model.binding(\.reverbMix), range: 0...1, defaultValue: 0.15) { "\(Int($0 * 100))%" }
            }
            .padding(.horizontal, 6)
            HStack {
                Text("Kéo dọc để chỉnh · chạm đúp để đặt lại").font(.system(size: 11)).foregroundStyle(Theme.textDim)
                Spacer()
                Button { model.sheet = .advanced } label: {
                    Label("Nâng cao", systemImage: "slider.horizontal.3").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
                        .frame(minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
        }
        .padding(.top, 8).card()
    }
}

// MARK: Hàng điều khiển dưới cùng (vùng ngón cái)

struct TransportBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(alignment: .top) {
            Button { model.toggleMonitor() } label: {
                RoundAction(icon: "ear", label: "Hát thử", active: model.monitorOn || model.isRecording)
            }
            .buttonStyle(.plain).disabled(model.isRecording)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(model.monitorOn ? "Tắt hát thử" : "Bật hát thử")

            Button { model.toggleRecord() } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.85), lineWidth: 4).frame(width: 76, height: 76)
                        RoundedRectangle(cornerRadius: model.isRecording ? 8 : 30, style: .continuous)
                            .fill(Theme.rec).frame(width: model.isRecording ? 30 : 60, height: model.isRecording ? 30 : 60)
                    }
                    .animation(.easeOut(duration: 0.15), value: model.isRecording)
                    Text(model.isRecording ? "Dừng" : "Thu").font(.system(size: 12, weight: .medium))
                        .foregroundStyle(model.isRecording ? Theme.rec : Theme.textDim)
                }
            }
            .buttonStyle(.plain).frame(maxWidth: .infinity)
            .sensoryFeedback(.impact, trigger: model.isRecording)
            .accessibilityLabel(model.isRecording ? "Dừng thu" : "Bắt đầu thu")

            Button { model.sheet = .takes } label: {
                RoundAction(icon: "square.stack", label: "Bản thu", badge: model.takes.count)
            }
            .buttonStyle(.plain).disabled(model.isRecording)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Các bản thu, \(model.takes.count) bản")
        }
        .frame(height: 96)
    }
}
