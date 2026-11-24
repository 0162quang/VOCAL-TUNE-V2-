import SwiftUI

// MARK: Thành phần dùng chung

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0
    var hint: String? = nil
    let format: (Double) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.system(size: 16))
                Spacer()
                Text(format(value)).font(.system(size: 15, weight: .semibold, design: .rounded)).monospacedDigit().foregroundStyle(Theme.accent)
            }
            Group {
                if step > 0 { Slider(value: $value, in: range, step: step) } else { Slider(value: $value, in: range) }
            }
            .tint(Theme.accent).frame(minHeight: 44)
            .accessibilityLabel(title).accessibilityValue(format(value))
            if let hint { Text(hint).font(.system(size: 12)).foregroundStyle(Theme.textDim).padding(.bottom, 4) }
        }
    }
}

struct SheetHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing
    var body: some View {
        HStack {
            Text(title).font(.system(size: 22, weight: .bold, design: .rounded))
            Spacer()
            trailing
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 8)
    }
}

// MARK: Nâng cao (chia tab, mỗi tab ngắn)

struct AdvancedSheet: View {
    @Environment(AppModel.self) private var model
    @State private var tab = 0
    private let tabs = ["Tune", "Giọng", "Hiệu ứng", "Mix"]

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(title: "Nâng cao") {
                Button("Đặt lại") { model.resetSettings() }
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.accent).frame(minHeight: 44)
            }
            Picker("", selection: $tab) { ForEach(tabs.indices, id: \.self) { Text(tabs[$0]).tag($0) } }
                .pickerStyle(.segmented).padding(.horizontal, 20).padding(.bottom, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    switch tab {
                    case 0: tune
                    case 1: voice
                    case 2: effects
                    default: mix
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
        }
    }

    private var tune: some View {
        Group {
            SliderRow(title: "Tốc độ retune", value: model.binding(\.retuneMs), range: 0...400, step: 1,
                      hint: "Nhỏ = cứng kiểu robot. Lớn = tự nhiên.") { $0 < 1 ? "Robot" : "\(Int($0)) ms" }
            SliderRow(title: "Mức chỉnh", value: model.binding(\.amount), range: 0...1,
                      hint: "Bao nhiêu phần được kéo về nốt chuẩn.") { "\(Int($0 * 100))%" }
            SliderRow(title: "Humanize", value: model.binding(\.flexCents), range: 0...50, step: 1,
                      hint: "Lệch nhẹ dưới ngưỡng này thì giữ nguyên cho tự nhiên.") { $0 < 1 ? "Tắt" : "\(Int($0))¢" }
            SliderRow(title: "Giữ vibrato", value: model.binding(\.vibratoKeep), range: 0...1,
                      hint: "100% giữ nguyên vibrato, 0% làm phẳng hoàn toàn.") { "\(Int($0 * 100))%" }
        }
    }

    private var voice: some View {
        Group {
            SliderRow(title: "Formant", value: model.binding(\.formantSemis), range: -4...4, step: 0.1,
                      hint: "Dương = giọng mỏng, sáng. Âm = giọng dày, trầm.") { String(format: "%+.1f", $0) }
            Stepper("Transpose  \(model.settings.transpose > 0 ? "+" : "")\(model.settings.transpose) nửa cung",
                    value: model.binding(\.transpose), in: -12...12).frame(minHeight: 44)
            SliderRow(title: "Detune", value: model.binding(\.detune), range: -50...50, step: 1) { "\(Int($0))¢" }
            SliderRow(title: "Tần số A4", value: model.binding(\.refA4), range: 415...466, step: 1) { "\(Int($0)) Hz" }
            Text("Dải giọng").font(.system(size: 16)).padding(.top, 8)
            Picker("Dải giọng", selection: model.binding(\.range)) {
                ForEach(VoiceRange.allCases) { Text($0.title).tag($0) }
            }.pickerStyle(.segmented)
            Text("\(model.settings.range.detail). Có hiệu lực ở lần bật «Hát thử» tiếp theo. Giọng càng trầm thì độ trễ càng cao.")
                .font(.system(size: 12)).foregroundStyle(Theme.textDim)
        }
    }

    private var effects: some View {
        Group {
            SliderRow(title: "Compressor", value: model.binding(\.comp), range: 0...1) { "\(Int($0 * 100))%" }
            SliderRow(title: "Reverb", value: model.binding(\.reverbMix), range: 0...1) { "\(Int($0 * 100))%" }
            SliderRow(title: "Kích thước reverb", value: model.binding(\.reverbSize), range: 0...1) { "\(Int($0 * 100))%" }
            SliderRow(title: "Delay", value: model.binding(\.delayMix), range: 0...1) { "\(Int($0 * 100))%" }
            SliderRow(title: "Thời gian delay", value: model.binding(\.delayMs), range: 60...900, step: 10) { "\(Int($0)) ms" }
            SliderRow(title: "Feedback", value: model.binding(\.delayFeedback), range: 0...0.85) { "\(Int($0 * 100))%" }
            Text("Reverb và delay tự tắt khi máy nóng hoặc bật Tiết kiệm pin.").font(.system(size: 12)).foregroundStyle(Theme.textDim)
        }
    }

    private var mix: some View {
        Group {
            SliderRow(title: "Gain mic", value: model.binding(\.inputGainDb), range: -12...24, step: 1) { "\(Int($0)) dB" }
            SliderRow(title: "Gate (cắt nhiễu)", value: model.binding(\.gateDb), range: -80 ... -30, step: 1) { $0 <= -80 ? "Tắt" : "\(Int($0)) dB" }
            SliderRow(title: "Giọng", value: model.binding(\.vocalGain), range: 0...1.5) { "\(Int($0 * 100))%" }
            SliderRow(title: "Beat", value: model.binding(\.beatGain), range: 0...1.2) { "\(Int($0 * 100))%" }
            SliderRow(title: "Âm lượng ra", value: model.binding(\.outputGainDb), range: -12...6, step: 1) { "\(Int($0)) dB" }
            Toggle("Tự nhận key khi thêm beat", isOn: model.binding(\.autoKey)).tint(Theme.accent).frame(minHeight: 44)
        }
    }
}

// MARK: Key & Scale

struct PianoKeysView: View {
    let mask: UInt16
    let root: Int
    let toggle: (Int) -> Void

    private let whites = [0, 2, 4, 5, 7, 9, 11]
    private let blacks: [(pc: Int, after: Int)] = [(1, 0), (3, 1), (6, 3), (8, 4), (10, 5)]

    var body: some View {
        GeometryReader { g in
            let w = g.size.width / 7, bw = w * 0.62
            ZStack(alignment: .topLeading) {
                HStack(spacing: 2) {
                    ForEach(whites, id: \.self) { pc in
                        let on = (mask >> UInt16(pc)) & 1 == 1
                        Button { toggle(pc) } label: {
                            VStack {
                                Spacer()
                                Text(noteNames[pc]).font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(on ? Color.white : Color.black.opacity(0.6)).padding(.bottom, 8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(on ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Color(white: 0.92)),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(alignment: .top) {
                                if pc == root { Circle().fill(Theme.warn).frame(width: 8, height: 8).padding(.top, 6) }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(noteNames[pc]), \(on ? "bật" : "tắt")")
                    }
                }
                ForEach(blacks, id: \.pc) { b in
                    let on = (mask >> UInt16(b.pc)) & 1 == 1
                    Button { toggle(b.pc) } label: {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(on ? AnyShapeStyle(Theme.accent2) : AnyShapeStyle(Color(white: 0.12)))
                            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .overlay(alignment: .top) {
                                if b.pc == root { Circle().fill(Theme.warn).frame(width: 7, height: 7).padding(.top, 6) }
                            }
                            .frame(width: bw, height: g.size.height * 0.6)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(x: w * CGFloat(b.after + 1) - bw / 2 + 1)
                    .accessibilityLabel("\(noteNames[b.pc]), \(on ? "bật" : "tắt")")
                }
            }
        }
    }
}

struct ScaleSheet: View {
    @Environment(AppModel.self) private var model
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        let s = model.settings
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Key & Scale").font(.system(size: 22, weight: .bold, design: .rounded)).padding(.top, 14)
                Text("Giọng sẽ được kéo về các nốt đang bật. Chọn đúng key của bài thì nghe tự nhiên nhất.")
                    .font(.system(size: 14)).foregroundStyle(Theme.textDim)

                if model.beatName != nil {
                    Button { model.redetectKey() } label: {
                        Chip(icon: "wand.and.stars", text: "Nhận key từ beat", tint: Theme.cyan)
                    }.buttonStyle(.plain)
                }

                label("Nốt chủ (key)")
                LazyVGrid(columns: cols, spacing: 8) {
                    ForEach(0..<12, id: \.self) { i in
                        Button {
                            model.settings.keyRoot = i
                            if model.settings.scale == .custom { model.settings.scale = .chromatic }
                            model.settingsChanged(keepPreset: true)
                        } label: { Chip(icon: nil, text: noteNames[i], tint: Theme.accent, filled: s.keyRoot == i).frame(maxWidth: .infinity) }
                        .buttonStyle(.plain)
                    }
                }

                label("Scale")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ScaleType.allCases.filter { $0 != .custom }) { sc in
                            Button { model.settings.scale = sc; model.settingsChanged(keepPreset: true) } label: {
                                Chip(icon: nil, text: sc.title, tint: Theme.cyan, filled: s.scale == sc)
                            }.buttonStyle(.plain)
                        }
                    }
                }

                label("Nốt được phép · chạm phím để bật/tắt")
                PianoKeysView(mask: s.noteMask, root: s.keyRoot) { pc in
                    var mask = model.settings.noteMask
                    mask ^= (1 << UInt16(pc))
                    if mask == 0 { mask = 1 << UInt16(pc) }
                    model.settings.customMask = mask
                    model.settings.scale = .custom
                    model.settingsChanged(keepPreset: true)
                }
                .frame(height: 150)
                Text("Chấm vàng là nốt chủ.").font(.system(size: 12)).foregroundStyle(Theme.textDim)
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }

    private func label(_ t: String) -> some View {
        Text(t).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textDim)
    }
}

// MARK: Bản thu

struct TakesSheet: View {
    @Environment(AppModel.self) private var model
    @State private var showAdvanced = false

    var body: some View {
        @Bindable var m = model
        VStack(spacing: 0) {
            SheetHeader(title: "Bản thu") { EmptyView() }
            if model.takes.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "waveform.badge.mic").font(.system(size: 36)).foregroundStyle(Theme.textDim)
                    Text("Chưa có bản thu nào").font(.system(size: 16, weight: .semibold))
                    Text("Nhấn nút Thu ở màn hình chính để bắt đầu.").font(.system(size: 14)).foregroundStyle(Theme.textDim)
                    Spacer()
                }.frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(model.takes) { t in
                        HStack(spacing: 4) {
                            Button { model.togglePlay(t) } label: {
                                Image(systemName: model.playingTake == t.id ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 34)).foregroundStyle(Theme.accent).frame(width: 52, height: 52)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(model.playingTake == t.id ? "Dừng" : "Nghe")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.title).font(.system(size: 16, weight: .semibold))
                                Text(String(format: "%d:%02d%@", Int(t.duration) / 60, Int(t.duration) % 60, t.rendered ? " · đã render lại" : ""))
                                    .font(.system(size: 13)).foregroundStyle(Theme.textDim)
                            }
                            Spacer()
                            Menu {
                                Button("Render lại với cài đặt hiện tại", systemImage: "wand.and.stars") { model.rerender(t) }
                                Button("Xuất M4A", systemImage: "square.and.arrow.up") { model.export(t, .m4a) }
                                Button("Xuất WAV", systemImage: "square.and.arrow.up") { model.export(t, .wav) }
                                Button("Xóa", systemImage: "trash", role: .destructive) { model.delete(t) }
                            } label: {
                                Image(systemName: "ellipsis.circle").font(.system(size: 22)).foregroundStyle(Theme.textDim).frame(width: 48, height: 48)
                            }
                            .accessibilityLabel("Tùy chọn bản thu")
                        }
                        .listRowBackground(Theme.surface2)
                        .swipeActions { Button("Xóa", role: .destructive) { model.delete(t) } }
                    }
                    Section {
                        DisclosureGroup("Khớp giọng với beat khi xuất", isExpanded: $showAdvanced) {
                            SliderRow(title: "Dịch giọng", value: $m.exportNudgeMs, range: -300...300, step: 5,
                                      hint: "Nếu giọng nghe chậm hơn beat, kéo về phía âm.") { "\(Int($0)) ms" }
                        }
                        .listRowBackground(Theme.surface2)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .sheet(item: Binding(get: { model.shareURL.map { ShareItem(url: $0) } },
                             set: { if $0 == nil { model.shareURL = nil } })) { item in
            ShareSheet(url: item.url).presentationDetents([.medium, .large])
        }
    }
}

struct ShareItem: Identifiable { let url: URL; var id: URL { url } }

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
