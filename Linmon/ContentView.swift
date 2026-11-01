import SwiftUI
import UIKit

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
    @State private var editor: String? = nil
    @State private var recordDate = Date()
    @State private var operand: Decimal? = nil
    @State private var operation: String? = nil
    @State private var freshInput = false
    @State private var calculationError: String? = nil
    @State private var armed = false
    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private var fade: Double { Double(pow(1 - progress, 2)) }
    @State private var succeeded = false
    @State private var checkProgress: CGFloat = 0
    @State private var successLabelVisible = false
    @FocusState private var editingNote: Bool
    var save: (Entry) -> Void
    private let accounts = ["招商银行", "微信零钱", "现金"]
    private var pageBackground: Color { Palette.color(0xF7F9F4, 0x111710, scheme) }
    private var accent: Color { Palette.color(0xC6EF66, 0x86B83F, scheme) }
    private var amountDisplay: String {
        if let operation, let operand {
            return "¥ \(NSDecimalNumber(decimal: operand).stringValue) \(operation)\(freshInput ? "" : " " + amount)"
        }
        return "¥ \(amount)"
    }
    private var valid: Bool { operation == nil && calculationError == nil && (Double(amount) ?? 0) > 0 && (type != "转账" || account != destination) }
    private var categories: [(String, String)] {
        type == "收入" ? [("工资", "briefcase"), ("奖金", "gift"), ("利息", "percent"), ("其他", "ellipsis")]
        : [("餐饮", "fork.knife"), ("交通", "tram"), ("购物", "bag"), ("娱乐", "gamecontroller"), ("居家", "house"), ("健康", "cross.case"), ("其他", "ellipsis")]
    }
    var body: some View {
        NavigationStack {
            GeometryReader { page in
            ScrollView {
                VStack(spacing: 18) {
                    Text(amountDisplay)
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .lineLimit(3).minimumScaleFactor(0.65)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .anchorPreference(key: AmountFrameKey.self, value: .bounds) { $0 }
                        .opacity(0)
                    Spacer(minLength: 8)
                    HStack(spacing: 10) {
                        tool("日期", "calendar")
                        tool("标签", "tag")
                        tool("备注", "pencil")
                    }.opacity(fade)
                    if let calculationError { Text(calculationError).font(.caption).foregroundStyle(.red) }
                    accountPager(type == "收入" ? "收款账户" : "扣款账户", selection: $account).opacity(fade)
                    if type == "转账" {
                        accountPager("转入账户", selection: $destination).opacity(fade)
                        if account == destination { Text("请选择不同的转入账户").font(.caption).foregroundStyle(.secondary).opacity(fade) }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 8)
                .frame(minHeight: max(0, page.size.height - 304), alignment: .top)
                .allowsHitTesting(!armed && !succeeded)
            }
            .safeAreaInset(edge: .bottom) { keypad.padding(.horizontal, 20).padding(.bottom, 2).background(pageBackground) }
            .scrollDisabled(armed || succeeded)
            .overlayPreferenceValue(AmountFrameKey.self) { anchor in
                GeometryReader { overlay in
                if let anchor {
                    let amountFrame = overlay[anchor]
                    let screenCenter = (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }?.windows.first { $0.isKeyWindow }?.bounds.midY) ?? page.frame(in: .global).midY
                    let diameter = min(page.size.width - 48, 270.0)
                    ZStack {
                        Circle().stroke(accent.opacity(0.12), lineWidth: 4)
                            .opacity(Double(progress))
                        Circle().trim(from: 0, to: progress)
                            .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(amountDisplay)
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                            .lineLimit(3).minimumScaleFactor(0.65)
                            .multilineTextAlignment(.center)
                            .frame(width: (page.size.width - 40) * (1 - progress) + (diameter - 40) * progress)
                            .scaleEffect(succeeded ? 0.65 : (reduceMotion ? 1 : 1 + 0.12 * progress))
                            .opacity(succeeded ? 0 : 1)
                        SuccessCheckmark()
                            .trim(from: 0, to: checkProgress)
                            .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                            .frame(width: 84, height: 66)
                    }
                    .frame(width: diameter, height: diameter)
                    .overlay(alignment: .bottom) {
                        Text("记录成功").font(.title3.bold())
                            .offset(y: successLabelVisible ? 60 : 66)
                            .opacity(successLabelVisible ? 1 : 0)
                    }
                    .position(x: page.size.width / 2,
                              y: amountFrame.midY + ((screenCenter - overlay.frame(in: .global).minY) - amountFrame.midY) * (reduceMotion ? 0 : progress))
                    .allowsHitTesting(false)
                }
            }
            }
            .coordinateSpace(name: "compose")
            .background(pageBackground)
            }
            .background(pageBackground.ignoresSafeArea())
            .toolbarBackground(pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("记录类型", selection: $type) {
                        ForEach(["支出", "收入", "转账"], id: \.self) { Text($0).tag($0) }
                    }.pickerStyle(.segmented).frame(width: 220).opacity(fade).disabled(armed || succeeded)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("取消").opacity(fade).disabled(armed || succeeded)
                }
            }
            .tint(scheme == .dark ? .white : .black)
            .buttonStyle(.plain)
            .foregroundStyle(scheme == .dark ? Color.white : Color.black)
            .sensoryFeedback(.selection, trigger: account)
            .sensoryFeedback(.selection, trigger: destination)
            .sensoryFeedback(.success, trigger: successLabelVisible)
            .onChange(of: type) { _, value in category = value == "收入" ? "工资" : "餐饮"; resetConfirmation() }
            .onChange(of: account) { resetConfirmation() }
            .onChange(of: destination) { resetConfirmation() }
            .sheet(isPresented: Binding(get: { editor != nil }, set: { if !$0 { editor = nil } })) {
                NavigationStack {
                    Form {
                        if editor == "日期" { DatePicker("记录时间", selection: $recordDate, displayedComponents: [.date, .hourAndMinute]) }
                        else if editor == "标签" {
                            Picker("标签", selection: $category) { ForEach(categories, id: \.0) { Label($0.0, systemImage: $0.1).tag($0.0) } }.pickerStyle(.inline)
                        } else { TextField("添加备注", text: $note, axis: .vertical).lineLimit(3...6) }
                    }.navigationTitle(editor ?? "")
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { editor = nil } } }
                }.presentationDetents([.medium])
            }
            .interactiveDismissDisabled(armed || succeeded)
            .task(id: succeeded) {
                guard succeeded else { return }
                do {
                    // Finish the circle and amount transition before drawing the check.
                    try await Task.sleep(for: .milliseconds(240))
                    withAnimation(reduceMotion ? .linear(duration: 0.1) : .easeOut(duration: 0.3)) { checkProgress = 1 }
                    try await Task.sleep(for: .milliseconds(300))
                    withAnimation(.easeOut(duration: 0.18)) { successLabelVisible = true }
                    try await Task.sleep(for: .milliseconds(1180))
                    dismiss()
                } catch { return }
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active && !succeeded { resetConfirmation() } }
        }
    }
    private func tool(_ title: String, _ icon: String) -> some View {
        Button { editor = title } label: {
            Label(title == "标签" ? category : (title == "备注" && !note.isEmpty ? "已备注" : title), systemImage: icon)
                .font(.subheadline).lineLimit(1).frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
        }
    }
    private func accountPager(_ title: String, selection: Binding<String>) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TabView(selection: selection) {
                ForEach(accounts, id: \.self) { name in
                    HStack { Image(systemName: "creditcard"); Text(name).font(.headline); Text("CNY").font(.caption).foregroundStyle(.secondary) }.tag(name)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never)).frame(height: 30)
            HStack(spacing: 6) { ForEach(accounts, id: \.self) { name in Circle().fill(name == selection.wrappedValue ? Color.primary : Color.secondary.opacity(0.3)).frame(width: 5, height: 5) } }
        }.padding(10).frame(maxWidth: .infinity).background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
    private func calculatorKey(_ key: String) -> some View {
        Button { editingNote = false; input(key) } label: {
            Text(key == "C" ? "清空" : key)
                .font(.system(size: key == "C" ? 19 : 28, weight: .medium))
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(KeyPressFeedbackStyle())
            .accessibilityLabel(key == "⌫" ? "退格" : (key == "C" ? "清空" : key))
            .opacity(fade).disabled(armed || succeeded)
    }
    private var keypad: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(["1","2","3","+","4","5","6","−","7","8","9","×",".","0","⌫","÷"], id: \.self) { calculatorKey($0) }
            }
            GeometryReader { geometry in
                let unit = (geometry.size.width - 24) / 4
                HStack(spacing: 8) {
                    Color.clear.frame(width: unit).accessibilityHidden(true)
                    calculatorKey("C").frame(width: unit)
                    calculatorKey("=").frame(width: unit * 2 + 8)
                }
            }.frame(height: 54)
        }
        .overlay(alignment: .bottomLeading) {
            GeometryReader { geometry in
                confirmation(width: geometry.size.width)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
    private func confirmation(width: CGFloat) -> some View {
        let initialWidth = (width - 24) / 4
        let travel = max(1, width - 54)
        return ZStack(alignment: .leading) {
            Capsule().fill(Palette.color(0xEDF0E9, 0x303B2E, scheme))
            Capsule().strokeBorder(Palette.color(0x426416, 0xA4CE67, scheme).opacity(valid ? 0.85 : 0.25), lineWidth: 1.5)
            if armed {
                Capsule()
                    .fill(accent)
                    .frame(width: 48 + progress * travel)
                    .allowsHitTesting(false)
                Image(systemName: "chevron.right.2")
                    .font(.headline.bold())
                    .foregroundStyle(Palette.color(0x426416, 0xA4CE67, scheme))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 18)
                    .opacity(Double(1 - progress))
                    .allowsHitTesting(false)
            }
            Text(armed ? "滑动记账" : "记录").font(.headline)
                .foregroundStyle(Palette.color(0x426416, 0xA4CE67, scheme).opacity(valid ? 1 : 0.4))
                .frame(maxWidth: .infinity).opacity(armed ? Double(1-progress) * 0.65 : 1)
            if armed {
                Image(systemName: "arrow.right").font(.title3.bold()).foregroundStyle(Palette.color(0x18210D, 0x101707, scheme))
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.15), in: Circle())
                    .offset(x: 6 + progress * travel)
            }
        }
        .frame(width: armed || succeeded ? width : initialWidth, height: 54)
        .scaleEffect(armed && progress == 0 ? 0.98 : 1, anchor: .leading)
        .contentShape(Capsule())
        .overlay {
            ImmediateSlideTouch(enabled: valid && !succeeded, travel: travel,
                began: {
                    editingNote = false
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) { armed = true }
                }, moved: { translation in
                    guard armed, !succeeded else { return }
                    var transaction = Transaction(); transaction.animation = nil
                    withTransaction(transaction) { progress = min(1, max(0, translation / travel)) }
                }, ended: { translation in
                    guard armed, !succeeded else { return }
                    if translation / travel >= 0.92 { commit() } else { resetConfirmation() }
                }, cancelled: { resetConfirmation() })
        }
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
        save(Entry(name: note.isEmpty ? (type == "转账" ? "转账" : category) : note, category: type == "转账" ? "转账" : category, account: type == "转账" ? "\(account) → \(destination)" : account, amount: value, transfer: type == "转账", destination: type == "转账" ? destination : nil, income: type == "收入", date: recordDate))
        withAnimation(.easeOut(duration: 0.24)) { progress = 1; succeeded = true; armed = false }
    }
    // Calculator-style sequential operations; round the final monetary result to cents.
    private func calculate() {
        guard let lhs = operand, let op = operation, let rhs = Decimal(string: amount) else { return }
        guard !(op == "÷" && rhs == 0) else { calculationError = "不能除以零，请重新输入"; freshInput = true; return }
        var result: Decimal
        switch op { case "+": result = lhs + rhs; case "−": result = lhs - rhs; case "×": result = lhs * rhs; default: result = lhs / rhs }
        guard !result.isNaN, abs(NSDecimalNumber(decimal: result).doubleValue) < 1_000_000_000_000_000 else { calculationError = "金额超出范围"; return }
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, 2, .plain)
        amount = NSDecimalNumber(decimal: rounded).stringValue
        operand = nil; operation = nil; freshInput = true
    }
    private func input(_ key: String) {
        resetConfirmation()
        calculationError = nil
        if key == "C" { amount = "0"; operand = nil; operation = nil; freshInput = false; return }
        if ["+", "−", "×", "÷"].contains(key) {
            if operation != nil && !freshInput { calculate() }
            guard calculationError == nil, let value = Decimal(string: amount) else { return }
            operand = value; operation = key; freshInput = true; return
        }
        if key == "=" { calculate(); return }
        if key == "⌫" {
            if operation != nil, freshInput, let lhs = operand {
                amount = NSDecimalNumber(decimal: lhs).stringValue
                operation = nil; operand = nil; freshInput = false
            } else if operation != nil && amount.count == 1 {
                amount = "0"; freshInput = true
            } else {
                amount = amount.count > 1 ? String(amount.dropLast()) : "0"
                if amount == "-" { amount = "0" }
                freshInput = false
            }
            return
        }
        if freshInput { amount = "0"; freshInput = false }
        if key == "00" { input("0"); input("0"); return }
        if key == "." { if !amount.contains(".") { amount += "." }; return }
        if let dot = amount.firstIndex(of: "."), amount.distance(from: dot, to: amount.endIndex) > 2 { return }
        guard amount.filter({ $0.isNumber }).count < 15 else { return }
        amount = amount == "0" ? key : amount + key
    }
}

// UIKit delivers touch-down directly; no long-press or pan recognition delay.
private struct ImmediateSlideTouch: UIViewRepresentable {
    var enabled: Bool
    var travel: CGFloat
    var began: () -> Void
    var moved: (CGFloat) -> Void
    var ended: (CGFloat) -> Void
    var cancelled: () -> Void

    func makeUIView(context: Context) -> TouchView { TouchView() }
    func updateUIView(_ view: TouchView, context: Context) {
        view.isUserInteractionEnabled = enabled
        view.slide.travel = travel
        view.began = began; view.moved = moved; view.ended = ended; view.cancelled = cancelled
    }
    final class TouchView: UIView {
        var began: () -> Void = {}
        var moved: (CGFloat) -> Void = { _ in }
        var ended: (CGFloat) -> Void = { _ in }
        var cancelled: () -> Void = {}
        let slide = SlideRecognizer()
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            isMultipleTouchEnabled = false
            slide.addTarget(self, action: #selector(handleSlide))
            addGestureRecognizer(slide)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window == nil { slide.isEnabled = false; slide.isEnabled = true }
        }
        @objc private func handleSlide() {
            switch slide.state {
            case .began: began()
            case .changed: moved(slide.translation)
            case .ended: ended(slide.translation)
            case .cancelled, .failed: cancelled()
            default: break
            }
        }
    }

    // Claim this touch immediately, before an ancestor scroll/sheet pan can steal it.
    // Keep tracking in window coordinates even outside the expanding track's bounds.
    final class SlideRecognizer: UIGestureRecognizer {
        var travel: CGFloat = 1
        private(set) var translation: CGFloat = 0
        private var origin: CGFloat = 0
        private var tracked: UITouch?
        private var lastPulse: TimeInterval = 0
        private var pulseTimer: Timer?
        private var heldProgress: CGFloat = 0
        private var lastPosition: CGFloat = 0
        private var reachedEnd = false
        private let impact = UIImpactFeedbackGenerator(style: .rigid)
        private let arrival = UINotificationFeedbackGenerator()

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            guard tracked == nil, let touch = touches.first else { return }
            tracked = touch
            origin = touch.location(in: view?.window).x
            translation = 0
            impact.prepare(); arrival.prepare()
            impact.impactOccurred(intensity: 0.3)
            lastPulse = Date.timeIntervalSinceReferenceDate
            heldProgress = 0
            pulseTimer?.invalidate()
            let timer = Timer(timeInterval: 0.025, repeats: true) { [weak self] _ in
                guard let self, self.tracked != nil, !self.reachedEnd else { return }
                let now = Date.timeIntervalSinceReferenceDate
                let interval = 0.11 - Double(self.heldProgress) * 0.05
                guard now - self.lastPulse >= interval else { return }
                self.impact.impactOccurred(intensity: 0.15 + 0.65 * self.heldProgress)
                self.lastPulse = now
            }
            pulseTimer = timer
            RunLoop.main.add(timer, forMode: .common)
            state = .began
        }
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            guard let touch = tracked, touches.contains(touch) else { return }
            translation = touch.location(in: view?.window).x - origin
            let progress = min(1, max(0, translation / max(1, travel)))
            heldProgress = progress
            if progress >= 0.98 && !reachedEnd {
                arrival.notificationOccurred(.success)
                reachedEnd = true
                // Arrival silences the continuous pulses while held at the endpoint.
                lastPulse = Date.timeIntervalSinceReferenceDate + 0.18
            }
            // Hysteresis avoids repeated arrival signals from tiny finger jitter.
            if progress < 0.85 { reachedEnd = false }
            state = .changed
        }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            guard let touch = tracked, touches.contains(touch) else { return }
            translation = touch.location(in: view?.window).x - origin
            pulseTimer?.invalidate(); pulseTimer = nil
            state = .ended
        }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            pulseTimer?.invalidate(); pulseTimer = nil
            state = .cancelled
        }
        override func reset() {
            super.reset()
            pulseTimer?.invalidate(); pulseTimer = nil
            tracked = nil; translation = 0; reachedEnd = false; lastPosition = 0
        }
        override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
            // System cancellation still arrives through touchesCancelled.
            false
        }
    }
}

private struct KeyPressFeedbackStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light, intensity: 0.45), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

private struct SuccessCheckmark: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.52))
            path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.82))
            path.addLine(to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.15))
        }
    }
}

private struct AmountFrameKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

#Preview("浅色") { ContentView().preferredColorScheme(.light) }
#Preview("深色") { ContentView().preferredColorScheme(.dark) }
