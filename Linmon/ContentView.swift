import SwiftUI

private enum Palette {
    static func color(_ light: UInt32, _ dark: UInt32, _ scheme: ColorScheme) -> Color {
        let v = scheme == .dark ? dark : light
        return Color(red: Double((v >> 16) & 255)/255, green: Double((v >> 8) & 255)/255, blue: Double(v & 255)/255)
    }
}

private struct Entry: Identifiable {
    let id = UUID()
    var name: String
    var category: String
    var account: String
    var amount: Double
    var transfer = false
    var destination: String? = nil
    var income = false
    var date = Date()
    var icon: String { category == "餐饮" ? "fork.knife" : "bag" }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var tab = "概览"
    @State private var composing = false
    @State private var calendar = false
    @State private var entries = [Entry(name: "午餐", category: "餐饮", account: "招商银行", amount: 68), Entry(name: "咖啡", category: "餐饮", account: "招商银行", amount: 28), Entry(name: "日用品", category: "购物", account: "微信零钱", amount: 32.5)]
    private var accent: Color { Palette.color(0xC6EF66, 0x86B83F, scheme) }
    private var surface: Color { Palette.color(0xFFFFFF, 0x1C241B, scheme) }
    private var spent: Double { entries.filter { !$0.income && !$0.transfer && Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tab).font(.largeTitle.bold())
                        Text(Date.now, format: .dateTime.month().day()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { calendar = true } label: {
                        Image(systemName: "calendar").font(.title2).padding(13).background(accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
                    }.accessibilityLabel("账本日历")
                }
                if tab == "概览" {
                    summary
                    section("我的账户", destination: "账户")
                    accounts
                    section("最近账单", destination: "账单")
                    ledger(Array(entries.filter { Calendar.current.isDateInToday($0.date) }.prefix(3)))
                } else if tab == "账户" { accounts }
                else if tab == "账单" { ledger(entries) }
                else {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("外观随系统切换", systemImage: "circle.lefthalf.filled")
                        Text("当前为交互演示，记录仅保留在本次运行中。").font(.footnote).foregroundStyle(.secondary)
                    }.padding().frame(maxWidth: .infinity, alignment: .leading).background(surface, in: RoundedRectangle(cornerRadius: 22))
                }
            }.padding(20)
        }
        .background(Palette.color(0xF7F9F4, 0x111710, scheme))
        .safeAreaInset(edge: .bottom) { navigation.padding(.horizontal, 20).padding(.bottom, 8) }
        .tint(Palette.color(0x426416, 0xA4CE67, scheme))
        .sheet(isPresented: $composing) { ComposeView { entry in entries.insert(entry, at: 0) } }
        .sheet(isPresented: $calendar) {
            NavigationStack { ContentUnavailableView("账本日历", systemImage: "calendar", description: Text("日历内容即将完善"))
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { calendar = false } } }
            }.presentationDetents([.medium])
        }
    }

    private var summary: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("今日支出").font(.subheadline.weight(.medium))
                Text(spent, format: .currency(code: "CNY")).font(.system(size: 34, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
                Text(spent <= 200 ? "今日剩余预算 ¥\(200-spent, specifier: "%.2f")" : "今日超出预算 ¥\(spent-200, specifier: "%.2f")").font(.caption.weight(.medium))
            }
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                LemonChart(progress: spent/200, dining: spent == 0 ? 0 : entries.filter { !$0.income && !$0.transfer && $0.category == "餐饮" && Calendar.current.isDateInToday($0.date) }.reduce(0) { $0+$1.amount }/spent)
                    .frame(width: 100, height: 100)
                Text("已用 \(spent/2, specifier: "%.1f")%").font(.caption)
            }
        }.foregroundStyle(Palette.color(0x18210D, 0xA4CE67, scheme))
        .padding(20)
        .background {
            let shape = RoundedRectangle(cornerRadius: 24)
            if scheme == .dark {
                if reduceTransparency {
                    shape.fill(Palette.color(0xFFFFFF, 0x263025, scheme))
                } else {
                    shape.fill(.ultraThinMaterial)
                        .overlay { shape.fill(.white.opacity(0.06)) }
                }
            } else {
                shape.fill(accent)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(scheme == .dark ? 0.12 : 0), lineWidth: 0.75)
        }
    }
    private func section(_ title: String, destination: String) -> some View {
        HStack { Text(title).font(.headline); Spacer(); Button { tab = destination } label: { Label("全部", systemImage: "chevron.right").font(.caption).foregroundStyle(.secondary) } }
    }
    private var accounts: some View {
        VStack(spacing: 10) {
            account("招商银行", icon: "building.columns", balance: "¥28,521.50")
            account("微信零钱", icon: "wallet.bifold", balance: "¥856.20")
        }
    }
    private func account(_ name: String, icon: String, balance: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title2).frame(width: 44, height: 44).background(accent.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 5) { Text(name).font(.subheadline.bold()); Text("CNY").font(.caption).foregroundStyle(.secondary) }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) { Text(balance).font(.subheadline.bold()); Text("最近变动 · 今天").font(.caption2).foregroundStyle(.secondary) }
        }.padding(16).background(surface, in: RoundedRectangle(cornerRadius: 20))
    }
    private func ledger(_ items: [Entry]) -> some View {
        VStack(spacing: 0) {
            if items.isEmpty { Text("今天还没有账单").foregroundStyle(.secondary).padding(24) }
            ForEach(items) { entry in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: entry.icon).frame(width: 42, height: 42).background(accent.opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 5) {
                        Text(entry.name).font(.subheadline.bold())
                        Text("\(entry.category) · \(entry.account)").font(.caption).foregroundStyle(.secondary)
                        Text(entry.date, style: .time).font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(entry.transfer ? "↔" : (entry.income ? "+" : "−"))¥\(entry.amount, specifier: "%.2f")").font(.subheadline.weight(.semibold))
                }.padding(16)
            }
        }.frame(maxWidth: .infinity).background(surface, in: RoundedRectangle(cornerRadius: 22))
    }
    private var navigation: some View {
        HStack {
            nav("概览", "house.fill"); nav("账单", "doc.text")
            Button { composing = true } label: { Image(systemName: "plus").font(.title).foregroundStyle(.black).frame(width: 56, height: 56).background(accent, in: Circle()) }.accessibilityLabel("记一笔")
            nav("账户", "creditcard"); nav("设置", "gearshape")
        }.padding(10).glassEffect(.regular, in: Capsule())
    }
    private func nav(_ title: String, _ icon: String) -> some View {
        Button { tab = title } label: {
            VStack(spacing: 5) { Image(systemName: icon).font(.title3); Text(title).font(.caption2) }.frame(maxWidth: .infinity).frame(height: 48)
                .foregroundStyle(tab == title ? Palette.color(0x426416, 0xA4CE67, scheme) : Color.secondary)
        }
    }
}

private struct LemonChart: View {
    @Environment(\.colorScheme) private var scheme
    let progress: Double
    let dining: Double
    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.35), lineWidth: 7)
            Circle().trim(from: 0, to: min(max(progress, 0), 1)).stroke(Palette.color(0x285C32, 0xA4CE67, scheme), style: StrokeStyle(lineWidth: 7, lineCap: .round)).rotationEffect(.degrees(-90))
            Circle().fill(Palette.color(0xFFF2AB, 0xAD850F, scheme)).padding(9)
            GeometryReader { geo in
                Path { path in
                    let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                    path.move(to: center)
                    path.addArc(center: center, radius: geo.size.width/2-9, startAngle: .degrees(-90), endAngle: .degrees(-90+360*min(max(dining, 0), 1)), clockwise: false)
                    path.closeSubpath()
                }.fill(Palette.color(0xFFDE61, 0xD4AF25, scheme)).stroke(Palette.color(0xF8FBEA, 0x71601D, scheme), lineWidth: 1.5)
            }
            Circle().stroke(Palette.color(0xF8FBEA, 0x71601D, scheme), lineWidth: 1.5).padding(9)
        }.accessibilityLabel("预算已用 \(progress*100, specifier: "%.1f")%，餐饮占比 \(dining*100, specifier: "%.1f")%")
    }
}

private struct ComposeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var amount = "0"
    @State private var type = "支出"
    @State private var category = "餐饮"
    @State private var account = "招商银行"
    @State private var destination = "微信零钱"
    @State private var note = ""
    @State private var armed = false
    @State private var progress: CGFloat = 0
    @State private var amountFrame: CGRect = .zero
    @GestureState private var touching = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private var fade: Double { Double(pow(1 - progress, 2)) }
    @State private var succeeded = false
    @FocusState private var editingNote: Bool
    var save: (Entry) -> Void
    private let accounts = ["招商银行", "微信零钱", "现金"]
    private var accent: Color { Palette.color(0xC6EF66, 0x86B83F, scheme) }
    private var valid: Bool { (Double(amount) ?? 0) > 0 && (type != "转账" || account != destination) }
    private var categories: [(String, String)] {
        type == "收入" ? [("工资", "briefcase"), ("奖金", "gift"), ("利息", "percent"), ("其他", "ellipsis")]
        : [("餐饮", "fork.knife"), ("交通", "tram"), ("购物", "bag"), ("娱乐", "gamecontroller"), ("居家", "house"), ("健康", "cross.case"), ("其他", "ellipsis")]
    }
    var body: some View {
        NavigationStack {
            GeometryReader { page in
            ScrollView {
                VStack(spacing: 18) {
                    Picker("记录类型", selection: $type) {
                        ForEach(["支出", "收入", "转账"], id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(.segmented).opacity(fade)
                    Text("¥ \(amount)")
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(key: AmountFrameKey.self, value: geometry.frame(in: .named("compose")))
                        })
                        .opacity(armed || progress > 0 || succeeded ? 0 : 1)
                    if type != "转账" {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(categories, id: \.0) { item in
                                    Button { category = item.0 } label: {
                                        VStack(spacing: 9) { Image(systemName: item.1).font(.title3); Text(item.0).font(.subheadline) }
                                            .frame(width: 76, height: 76)
                                            .background(category == item.0 ? accent : Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
                                    }.accessibilityAddTraits(category == item.0 ? .isSelected : [])
                                }
                            }
                        }.opacity(fade)
                    }
                    accountPager(type == "收入" ? "收款账户" : "扣款账户", selection: $account).opacity(fade)
                    if type == "转账" {
                        accountPager("转入账户", selection: $destination).opacity(fade)
                        if account == destination { Text("请选择不同的转入账户").font(.caption).foregroundStyle(.secondary).opacity(fade) }
                    }
                    TextField("添加备注", text: $note).focused($editingNote).padding(14).background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14)).opacity(fade)
                }.padding(20).allowsHitTesting(!armed && !succeeded)
            }
            .safeAreaInset(edge: .bottom) { keypad.padding(.horizontal, 20).padding(.bottom, 12).background { Rectangle().fill(.bar).opacity(fade) } }
            .scrollDisabled(armed || succeeded)
            .onPreferenceChange(AmountFrameKey.self) { amountFrame = $0 }
            .overlay {
                if armed || progress > 0 || succeeded {
                    Text("¥ \(amount)")
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .frame(width: max(1, page.size.width - 40))
                        .scaleEffect(reduceMotion ? 1 : 1 + 0.22 * progress)
                        .position(x: page.size.width / 2,
                                  y: amountFrame.midY + (page.size.height * 0.43 - amountFrame.midY) * (reduceMotion ? 0 : progress))
                        .allowsHitTesting(false)
                }
                if succeeded {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 60)).foregroundStyle(accent)
                            .symbolEffect(.bounce, value: succeeded)
                        Text("记录成功").font(.title3.bold())
                        Button("完成") { dismiss() }.padding(12)
                    }.position(x: page.size.width / 2, y: page.size.height * 0.65)
                        .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.9)))
                }
            }
            .coordinateSpace(name: "compose")
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Text("记账").font(.headline).opacity(fade) }; ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() }.opacity(fade).disabled(armed || succeeded) } }
            .tint(scheme == .dark ? .white : .black)
            .buttonStyle(.plain)
            .foregroundStyle(scheme == .dark ? Color.white : Color.black)
            .sensoryFeedback(.selection, trigger: account)
            .sensoryFeedback(.selection, trigger: destination)
            .sensoryFeedback(.success, trigger: succeeded)
            .onChange(of: type) { _, value in category = value == "收入" ? "工资" : "餐饮"; resetConfirmation() }
            .onChange(of: account) { resetConfirmation() }
            .onChange(of: destination) { resetConfirmation() }
            .interactiveDismissDisabled(armed || succeeded)
            .sensoryFeedback(.impact(weight: .light), trigger: armed)
            .onChange(of: touching) { _, active in
                if !active && armed && !succeeded { resetConfirmation() }
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active && !succeeded { resetConfirmation() } }
        }
    }
    private func accountPager(_ title: String, selection: Binding<String>) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TabView(selection: selection) {
                ForEach(accounts, id: \.self) { name in
                    HStack { Image(systemName: "creditcard"); Text(name).font(.headline); Text("CNY").font(.caption).foregroundStyle(.secondary) }.tag(name)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 44)
            HStack(spacing: 6) { ForEach(accounts, id: \.self) { name in Circle().fill(name == selection.wrappedValue ? Color.primary : Color.secondary.opacity(0.3)).frame(width: 5, height: 5) } }
        }.padding(10).frame(maxWidth: .infinity).background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
    private var keypad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(["1","2","3","4","5","6","7","8","9","记录","0","⌫"], id: \.self) { key in
                if key == "记录" { Color.clear.frame(height: 62) }
                else {
                    Button { editingNote = false; input(key) } label: {
                        Text(key).font(.system(size: 28, weight: .medium)).frame(maxWidth: .infinity).frame(height: 62)
                            .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
                    }.accessibilityLabel(key == "⌫" ? "退格" : key).opacity(fade).disabled(armed || succeeded)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            GeometryReader { geometry in
                confirmation(width: geometry.size.width)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .contextMenu { Button("输入小数点") { input(".") } }
    }
    private func confirmation(width: CGFloat) -> some View {
        let initialWidth = (width - 16) / 3
        let travel = max(1, width - 62)
        return ZStack(alignment: .leading) {
            Capsule().fill(accent.opacity(valid ? 1 : 0.25))
            Text(armed ? "滑动记账" : "记录").font(.headline)
                .frame(maxWidth: .infinity).opacity(armed ? Double(1-progress) * 0.65 : 1)
            if armed {
                Image(systemName: "arrow.right").font(.title3.bold()).foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(.black.opacity(0.15), in: Circle())
                    .offset(x: 6 + progress * travel)
            }
        }
        .frame(width: armed || succeeded ? width : initialWidth, height: 62)
        .scaleEffect(armed && progress == 0 ? 0.98 : 1, anchor: .leading)
        .contentShape(Capsule())
        .gesture(DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                guard valid, !succeeded else { return }
                if !armed {
                    editingNote = false
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { armed = true }
                }
                // Drag progress has no implicit animation: reverse motion follows the finger too.
                var transaction = Transaction(); transaction.animation = nil
                withTransaction(transaction) { progress = min(1, max(0, value.translation.width / travel)) }
            }
            .onEnded { value in
                guard armed, !succeeded else { return }
                if value.translation.width / travel >= 0.92 { commit() }
                else { resetConfirmation() }
            })
        .opacity(succeeded ? 0 : 1)
        .allowsHitTesting(!succeeded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("记录，向右滑动确认")
        .accessibilityAction { if valid { commit() } }
    }
    private func resetConfirmation() {
        guard !succeeded else { return }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) { armed = false; progress = 0 }
    }
    private func commit() {
        guard valid, !succeeded, let value = Double(amount) else { return }
        save(Entry(name: note.isEmpty ? (type == "转账" ? "转账" : category) : note, category: type == "转账" ? "转账" : category, account: type == "转账" ? "\(account) → \(destination)" : account, amount: value, transfer: type == "转账", destination: type == "转账" ? destination : nil, income: type == "收入"))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { progress = 1; succeeded = true; armed = false }
    }
    private func input(_ key: String) {
        resetConfirmation()
        if key == "⌫" { amount = amount.count > 1 ? String(amount.dropLast()) : "0"; return }
        if key == "." { if !amount.contains(".") { amount += "." }; return }
        if let dot = amount.firstIndex(of: "."), amount.distance(from: dot, to: amount.endIndex) > 2 { return }
        guard amount.count < 12 else { return }
        amount = amount == "0" ? key : amount + key
    }
}

private struct AmountFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

#Preview("浅色") { ContentView().preferredColorScheme(.light) }
#Preview("深色") { ContentView().preferredColorScheme(.dark) }
