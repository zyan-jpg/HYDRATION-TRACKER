import SwiftUI
import UserNotifications

struct HydrationTracker: View {
    // MARK: - User Data Storage
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userDOB") private var userDOB: Date = Date()
    @AppStorage("userHeight") private var userHeight: Double = 0
    @AppStorage("userWeight") private var userWeight: Double = 0
    @AppStorage("userBedTime") private var userBedTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @AppStorage("userWakeTime") private var userWakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    
    // MARK: - Hydration Data Storage
    @AppStorage("hydrationProgress") private var hydrationProgressData: Data = Data()
    @AppStorage("hydrationLogs") private var hydrationLogsData: Data = Data()
    @AppStorage("lastCalculatedDate") private var lastCalculatedDate: String = ""
    
    // MARK: - State Variables
    @State private var servingsCompleted = 0
    @State private var totalGoal = 0
    @State private var servingSize = 0
    @State private var servingTimes: [Date] = []
    @State private var completedServingTimes: [Date] = []
    
    // MARK: - UI State
    @State private var showSummary = false
    @State private var showHistory = false
    @State private var showResetConfirm = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isDarkMode = false
    @State private var showSettings = false
    
    // MARK: - Constants
    private let maxServings = 8
    private let minimumWeight: Double = 20
    private let maximumWeight: Double = 300
    private let minimumHeight: Double = 100
    private let maximumHeight: Double = 250
    
    // MARK: - Data Models
    struct HydrationProgress: Codable {
        var servingsCompleted: Int = 0
        var completedTimes: [Date] = []
        var date: String = ""
    }
    
    struct HydrationLog: Codable, Identifiable {
        var id: String { date }
        let date: String
        var goal: Int
        var intake: Int
        var servings: Int
        var times: [String]
        var completionPercentage: Double
        var feedback: String
        
        init(date: String, goal: Int, intake: Int = 0, servings: Int = 0, times: [String] = []) {
            self.date = date
            self.goal = goal
            self.intake = intake
            self.servings = servings
            self.times = times
            self.completionPercentage = goal > 0 ? Double(intake) / Double(goal) * 100 : 0
            
            if completionPercentage >= 100 {
                self.feedback = "🎉 Excellent! You've reached your hydration goal!"
            } else if completionPercentage >= 80 {
                self.feedback = "👏 Great job! Almost there!"
            } else if completionPercentage >= 60 {
                self.feedback = "👍 Good progress, keep it up!"
            } else if completionPercentage >= 40 {
                self.feedback = "💪 You're making progress!"
            } else {
                self.feedback = "💧 Remember to stay hydrated throughout the day!"
            }
        }
    }
    
    @State private var hydrationLogs: [String: HydrationLog] = [:]
    
    // MARK: - Main View
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        headerSection
                            .padding(.top, 40)
                            .padding(.horizontal, 20)
                            .frame(maxWidth: 720)
                            .frame(maxWidth: .infinity)
                        
                        if !showSummary && !showHistory {
                            userFormSection
                                .padding(.horizontal, 20)
                                .frame(maxWidth: 720)
                                .frame(maxWidth: .infinity)
                        }
                        
                        if showSummary {
                            summarySection
                                .padding(.horizontal, 20)
                                .frame(maxWidth: 720)
                                .frame(maxWidth: .infinity)
                        }
                        
                        if showHistory {
                            historySection
                                .padding(.horizontal, 20)
                                .frame(maxWidth: 720)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                if showResetConfirm {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    resetConfirmationModal
                        .frame(maxWidth: 360)
                        .frame(maxHeight: 320)
                        .padding(20)
                        .background(containerBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 10)
                }
                
                if showAlert {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    alertModal
                        .frame(maxWidth: 340)
                        .padding(24)
                        .background(containerBackground)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 10)
                }
                
                // Settings modal as full screen sheet
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                setupApp()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    userName: $userName,
                    userDOB: $userDOB,
                    userHeight: $userHeight,
                    userWeight: $userWeight,
                    userBedTime: $userBedTime,
                    userWakeTime: $userWakeTime,
                    isDarkMode: $isDarkMode,
                    onCalculate: {
                        calculateHydrationGoal()
                        showSettings = false
                    }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Hydration Tracker")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(titleColor)
                .padding(.leading, 8)
            
            Spacer()
            
            Button(action: { showSettings.toggle() }) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(buttonBackground)
                    .padding(10)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Circle())
                    .hoverEffect(.highlight)
            }
        }
    }
    
    // MARK: - User Form Section
    private var userFormSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Let's set up your hydration plan!")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(titleColor)
                .padding(.bottom, 20)
            
            Group {
                LabelTextField(label: "Name", systemImage: "person.fill", text: $userName, keyboard: .default)
                
                LabelDatePicker(label: "Date of Birth", systemImage: "calendar", selection: $userDOB)
                
                LabelTextField(label: "Height (cm)", systemImage: "ruler", value: $userHeight, formatter: decimalFormatter, keyboard: .decimalPad)
                
                LabelTextField(label: "Weight (kg)", systemImage: "scalemass", value: $userWeight, formatter: decimalFormatter, keyboard: .decimalPad)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(buttonBackground)
                    
                    Text("Sleep Schedule")
                        .fontWeight(.semibold)
                        .foregroundColor(titleColor)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Bedtime")
                            .font(.caption)
                            .foregroundColor(.gray)
                        DatePicker("", selection: $userBedTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("Wake time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        DatePicker("", selection: $userWakeTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                .padding()
                .background(containerBackground)
                .cornerRadius(10)
            }
            
            Button {
                calculateHydrationGoal()
            } label: {
                Text("Calculate My Hydration Goal 💧")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(buttonBackground)
                    .foregroundColor(buttonForeground)
                    .cornerRadius(12)
                    .shadow(radius: 6)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: 36) {
            VStack(spacing: 12) {
                Text("Hello, \(userName)! 👋")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(titleColor)
                
                HStack(spacing: 20) {
                    StatCard(title: "Daily Goal", value: "\(totalGoal) ml", icon: "target")
                    StatCard(title: "Per Serving", value: "\(servingSize) ml", icon: "drop.fill")
                }
                
                ProgressCard(completed: servingsCompleted, total: maxServings, intake: servingsCompleted * servingSize, goal: totalGoal)
            }
            
            waterGlassVisualization
            
            servingScheduleSection
            
            HStack(spacing: 16) {
                Button("History 📊") { showHistory = true }
                    .buttonStyle(SecondaryButtonStyle())
                
                Button("Reset Day 🔄") {
                    showResetConfirm = true
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("New Goal ⚙️") {
                    withAnimation {
                        showSummary = false
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
    
    private var waterGlassVisualization: some View {
        VStack {
            Text("Your Progress")
                .font(.headline)
                .foregroundColor(titleColor)
                .padding(.bottom, 4)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(buttonBackground.opacity(0.5), lineWidth: 3)
                    .frame(width: 140, height: 280)
                
                if servingsCompleted > 0 {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.cyan.opacity(0.7), Color.blue.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 134,
                               height: max(30, CGFloat(servingsCompleted) / CGFloat(maxServings) * 274))
                        .animation(.easeInOut(duration: 0.8), value: servingsCompleted)
                }
                
                VStack(spacing: 0) {
                    ForEach(1..<maxServings, id: \.self) { _ in
                        Spacer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    Spacer()
                }
                .frame(width: 140, height: 280)
            }
            
            Text("\(servingsCompleted)/\(maxServings) servings")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 6)
        }
    }
    
    private var servingScheduleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Schedule")
                .font(.headline)
                .foregroundColor(titleColor)
                .padding(.horizontal, 8)
            
            LazyVStack(spacing: 12) {
                ForEach(0..<maxServings, id: \.self) { index in
                    ServingRow(
                        index: index,
                        time: servingTimes.indices.contains(index) ? servingTimes[index] : Date(),
                        isCompleted: index < servingsCompleted,
                        canComplete: canCompleteServing(at: index),
                        onTap: { logServing(at: index) }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Hydration History 📊")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(titleColor)
                Spacer()
                Button("Close") { showHistory = false }
                    .buttonStyle(SecondaryButtonStyle())
            }
            
            if hydrationLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No history yet")
                        .foregroundColor(.gray.opacity(0.6))
                    Text("Start tracking to see your progress!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: 320)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(sortedLogs, id: \.id) { log in
                            HistoryCard(log: log) {
                                showHistoryDetail(for: log)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding(.horizontal, 12)
    }
    
    // MARK: - Reset Confirmation Modal
    private var resetConfirmationModal: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Reset All Data?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(titleColor)
            
            Text("This will permanently delete all your hydration data and settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    showResetConfirm = false
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Reset") {
                    resetAllData()
                    showResetConfirm = false
                }
                .buttonStyle(DestructiveButtonStyle())
            }
            .padding(.top, 12)
        }
        .padding(24)
    }
    
    // MARK: - Alert Modal
    private var alertModal: some View {
        VStack(spacing: 24) {
            Text(alertMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(titleColor)
            
            Button("OK") {
                showAlert = false
            }
            .buttonStyle(PrimaryButtonStyle(background: buttonBackground, foreground: buttonForeground))
            .frame(maxWidth: 100)
        }
        .padding(24)
    }
    
    // MARK: - Helper Views
    
    struct LabelTextField: View {
        var label: String
        var systemImage: String
        @Binding var text: String
        var keyboard: UIKeyboardType = .default
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundColor(Color.blue)
                    Text(label)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.gray)
                }
                TextField("Enter \(label.lowercased())", text: $text)
                    .font(.body)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .keyboardType(keyboard)
            }
        }
    }
    
    struct LabelTextField<Value>: View where Value: Comparable & LosslessStringConvertible {
        var label: String
        var systemImage: String
        @Binding var value: Value
        var formatter: NumberFormatter
        var keyboard: UIKeyboardType = .decimalPad
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundColor(Color.blue)
                    Text(label)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.gray)
                }
                TextField("Enter \(label.lowercased())", value: $value, formatter: formatter)
                    .font(.body)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .keyboardType(keyboard)
            }
        }
    }
    
    struct LabelDatePicker: View {
        var label: String
        var systemImage: String
        @Binding var selection: Date
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundColor(Color.blue)
                    Text(label)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.gray)
                }
                DatePicker(selection: $selection, displayedComponents: .date) {
                    EmptyView()
                }
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        
        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(Color.blue)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.12))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }
    
    struct ProgressCard: View {
        let completed: Int
        let total: Int
        let intake: Int
        let goal: Int
        
        var body: some View {
            VStack(spacing: 8) {
                HStack {
                    Text("Today's Progress")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(Int(goal > 0 ? Double(intake) / Double(goal) * 100 : 0))%")
                        .font(.headline.bold())
                        .foregroundColor(intake >= goal ? .green : .blue)
                        .monospacedDigit()
                }
                
                ProgressView(value: Double(intake), total: Double(goal))
                    .tint(intake >= goal ? .green : .blue)
                
                HStack {
                    Text("\(intake) ml consumed")
                    Spacer()
                    Text("\(goal) ml goal")
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.12))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }
    
    struct ServingRow: View {
        let index: Int
        let time: Date
        let isCompleted: Bool
        let canComplete: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : (canComplete ? .blue : .gray))
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Serving \(index + 1)")
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(formatTime(time))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if isCompleted {
                        Text("✓ Done")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    } else if canComplete {
                        Text("Tap to log")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text("Not yet")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isCompleted ? Color.green.opacity(0.15) :
                              (canComplete ? Color.blue.opacity(0.15) : Color.gray.opacity(0.10)))
                )
            }
            .disabled(!canComplete || isCompleted)
        }
    }
    
    struct HistoryCard: View {
        let log: HydrationLog
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(formatDate(log.date))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(Int(log.completionPercentage))%")
                            .fontWeight(.semibold)
                            .foregroundColor(log.completionPercentage >= 80 ? .green : .orange)
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(log.intake) ml")
                        Text("•")
                        Text("\(log.servings) servings")
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    
                    Text(log.feedback)
                        .font(.caption)
                        .italic()
                        .foregroundColor(Color.blue)
                }
                .padding()
                .background(Color.gray.opacity(0.12))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
        }
    }
    
    struct SettingsView: View {
        @Binding var userName: String
        @Binding var userDOB: Date
        @Binding var userHeight: Double
        @Binding var userWeight: Double
        @Binding var userBedTime: Date
        @Binding var userWakeTime: Date
        @Binding var isDarkMode: Bool
        
        var onCalculate: () -> Void
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("User Information")) {
                        TextField("Enter your name", text: $userName)
                        DatePicker("Date of Birth", selection: $userDOB, displayedComponents: .date)
                        TextField("Height (cm)", value: $userHeight, formatter: decimalFormatter)
                            .keyboardType(.decimalPad)
                        TextField("Weight (kg)", value: $userWeight, formatter: decimalFormatter)
                            .keyboardType(.decimalPad)
                    }
                    
                    Section(header: Text("Sleep Schedule")) {
                        DatePicker("Bedtime", selection: $userBedTime, displayedComponents: .hourAndMinute)
                        DatePicker("Wake Time", selection: $userWakeTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Section(header: Text("Appearance")) {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                    }
                    
                    Button("Calculate Hydration Goal") {
                        onCalculate()
                    }
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) // Dismiss keyboard
                            onCalculate()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Core Logic
    
    private func setupApp() {
        loadSavedData()
        updateGoalsIfNeeded()
        requestNotificationPermission()
        scheduleNotifications()
    }
    
    private func updateGoalsIfNeeded() {
        let currentDate = getCurrentDateString()
        
        if lastCalculatedDate != currentDate && !lastCalculatedDate.isEmpty {
            resetDailyProgress()
        }
        
        if totalGoal == 0 && userWeight > 0 && !userName.isEmpty {
            calculateHydrationGoal()
        }
    }
    
    private func calculateHydrationGoal() {
        guard validateUserInput() else { return }
        
        totalGoal = Int(userWeight * 35)
        servingSize = max(1, totalGoal / maxServings)
        
        servingsCompleted = 0
        completedServingTimes = []
        servingTimes = calculateOptimalServingTimes()
        
        lastCalculatedDate = getCurrentDateString()
        
        saveHydrationProgress()
        showSummary = true
        showHistory = false
        
        scheduleNotifications()
        
        showCustomAlert("🎉 Your daily hydration goal is \(totalGoal) ml!\nDrink \(servingSize) ml every serving.")
    }
    
    private func validateUserInput() -> Bool {
        if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showCustomAlert("Please enter your name.")
            return false
        }
        
        if userWeight < minimumWeight || userWeight > maximumWeight {
            showCustomAlert("Please enter a valid weight between \(Int(minimumWeight))-\(Int(maximumWeight)) kg.")
            return false
        }
        
        if userHeight < minimumHeight || userHeight > maximumHeight {
            showCustomAlert("Please enter a valid height between \(Int(minimumHeight))-\(Int(maximumHeight)) cm.")
            return false
        }
        
        let calendar = Calendar.current
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: userWakeTime)
        let bedComponents = calendar.dateComponents([.hour, .minute], from: userBedTime)
        
        if wakeComponents.hour == bedComponents.hour && wakeComponents.minute == bedComponents.minute {
            showCustomAlert("Wake time and bed time cannot be the same.")
            return false
        }
        
        return true
    }
    
    private func calculateOptimalServingTimes() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        var wakeTime = calendar.date(bySettingHour: calendar.component(.hour, from: userWakeTime),
                                    minute: calendar.component(.minute, from: userWakeTime),
                                    second: 0, of: now) ?? userWakeTime
        
        var bedTime = calendar.date(bySettingHour: calendar.component(.hour, from: userBedTime),
                                   minute: calendar.component(.minute, from: userBedTime),
                                   second: 0, of: now) ?? userBedTime
        
        if bedTime <= wakeTime {
            bedTime = calendar.date(byAdding: .day, value: 1, to: bedTime) ?? bedTime
        }
        
        let lastDrinkTime = bedTime.addingTimeInterval(-2 * 3600)
        let drinkingDuration = lastDrinkTime.timeIntervalSince(wakeTime)
        let interval = drinkingDuration / Double(maxServings)
        
        var times: [Date] = []
        for i in 0..<maxServings {
            let servingTime = wakeTime.addingTimeInterval(interval * Double(i) + interval / 2)
            times.append(servingTime)
        }
        
        return times
    }
    
    private func logServing(at index: Int) {
        guard index < maxServings else { return }
        
        if index < servingsCompleted {
            showCustomAlert("You've already logged this serving!")
            return
        }
        
        guard canCompleteServing(at: index) else {
            let timeString = formatTime(servingTimes[index])
            showCustomAlert("Please wait until \(timeString) to log this serving.")
            return
        }
        
        servingsCompleted = max(servingsCompleted, index + 1)
        completedServingTimes.append(Date())
        
        saveHydrationProgress()
        updateDailyLog()
        
        let remaining = maxServings - servingsCompleted
        if remaining == 0 {
            showCustomAlert("🎉 Congratulations! You've completed your daily hydration goal!")
        } else {
            showCustomAlert("Great! \(remaining) more serving\(remaining == 1 ? "" : "s") to go!")
        }
    }
    
    private func canCompleteServing(at index: Int) -> Bool {
        guard index < maxServings && index < servingTimes.count else { return false }
        
        let now = Date()
        let targetTime = servingTimes[index]
        let twoHoursLater = targetTime.addingTimeInterval(2 * 3600)
        
        return index == servingsCompleted && now >= targetTime && now <= twoHoursLater
    }
    
    private func updateDailyLog() {
        let dateString = getCurrentDateString()
        let currentIntake = servingsCompleted * servingSize
        
        var log = hydrationLogs[dateString] ?? HydrationLog(
            date: dateString,
            goal: totalGoal,
            intake: 0,
            servings: 0,
            times: []
        )
        
        log.intake = currentIntake
        log.servings = servingsCompleted
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        if log.times.count < servingsCompleted {
            log.times.append(timeFormatter.string(from: Date()))
        }
        
        log.completionPercentage = totalGoal > 0 ? Double(currentIntake) / Double(totalGoal) * 100 : 0
        if log.completionPercentage >= 100 {
            log.feedback = "🎉 Excellent! You've reached your hydration goal!"
        } else if log.completionPercentage >= 80 {
            log.feedback = "👏 Great job! Almost there!"
        } else if log.completionPercentage >= 60 {
            log.feedback = "👍 Good progress, keep it up!"
        } else if log.completionPercentage >= 40 {
            log.feedback = "💪 You're making progress!"
        } else {
            log.feedback = "💧 Remember to stay hydrated throughout the day!"
        }
        
        hydrationLogs[dateString] = log
        saveHydrationLogs()
    }
    
    private func resetDailyProgress() {
        servingsCompleted = 0
        completedServingTimes = []
        lastCalculatedDate = getCurrentDateString()
        saveHydrationProgress()
        
        if totalGoal > 0 {
            servingTimes = calculateOptimalServingTimes()
            scheduleNotifications()
        }
    }
    
    private func resetAllData() {
        userName = ""
        userDOB = Date()
        userHeight = 0
        userWeight = 0
        userBedTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        userWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        
        servingsCompleted = 0
        totalGoal = 0
        servingSize = 0
        servingTimes = []
        completedServingTimes = []
        hydrationLogs = [:]
        lastCalculatedDate = ""
        
        hydrationProgressData = Data()
        hydrationLogsData = Data()
        
        showSummary = false
        showHistory = false
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func showHistoryDetail(for log: HydrationLog) {
        let percentage = Int(log.completionPercentage)
        alertMessage = """
        📅 \(formatHistoryDate(log.date))
        
        💧 Goal: \(log.goal) ml
        ✅ Consumed: \(log.intake) ml (\(percentage)%)
        🥛 Servings: \(log.servings)/\(maxServings)
        
        🕒 Times: \(log.times.isEmpty ? "No records" : log.times.joined(separator: ", "))
        
        \(log.feedback)
        """
        showAlert = true
    }
    
    // MARK: - Data Persistence
    
    private func saveHydrationProgress() {
        let progress = HydrationProgress(
            servingsCompleted: servingsCompleted,
            completedTimes: completedServingTimes,
            date: getCurrentDateString()
        )
        
        if let encoded = try? JSONEncoder().encode(progress) {
            hydrationProgressData = encoded
        }
    }
    
    private func saveHydrationLogs() {
        if let encoded = try? JSONEncoder().encode(hydrationLogs) {
            hydrationLogsData = encoded
        }
    }
    
    private func loadSavedData() {
        if let progressData = try? JSONDecoder().decode(HydrationProgress.self, from: hydrationProgressData) {
            servingsCompleted = progressData.servingsCompleted
            completedServingTimes = progressData.completedTimes
        }
        
        if let logsData = try? JSONDecoder().decode([String: HydrationLog].self, from: hydrationLogsData) {
            hydrationLogs = logsData
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    private func scheduleNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for (index, time) in servingTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Hydration Reminder"
            content.body = "Time to drink your \(servingSize) ml of water!"
            content.sound = .default
            
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            let request = UNNotificationRequest(identifier: "hydrationReminder\(index)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Utility Functions
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return dateString
    }
    
    private func formatHistoryDate(_ dateString: String) -> String {
        formatDate(dateString)
    }
    
    private func showCustomAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    private var backgroundColor: Color {
        Color(UIColor.systemBackground)
    }
    
    private var titleColor: Color {
        Color.primary
    }
    
    private var buttonBackground: Color {
        Color.blue
    }
    
    private var buttonForeground: Color {
        Color.white
    }
    
    private var containerBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
    
    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private var sortedLogs: [HydrationLog] {
        hydrationLogs.values.sorted { $0.date > $1.date }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(background.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(foreground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: 6, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.blue)
            .background(Color.blue.opacity(configuration.isPressed ? 0.12 : 0.06))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .foregroundColor(.white)
            .background(Color.red.opacity(configuration.isPressed ? 0.85 : 1.0))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct HydrationTracker_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HydrationTracker()
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("iPhone 14 Pro - Light")
                .preferredColorScheme(.light)
                .environment(\.sizeCategory, .medium)
                .frame(maxWidth: 1200)
                .padding()

            HydrationTracker()
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("iPhone 14 Pro - Dark")
                .preferredColorScheme(.dark)
                .environment(\.sizeCategory, .medium)
                .frame(maxWidth: 1200)
                .padding()
            
            HydrationTracker()
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad Pro 12.9-inch - Light")
                .preferredColorScheme(.light)
                .environment(\.sizeCategory, .large)
                .frame(maxWidth: 1200)
                .padding()
            
            HydrationTracker()
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad Pro 12.9-inch - Dark")
                .preferredColorScheme(.dark)
                .environment(\.sizeCategory, .large)
                .frame(maxWidth: 1200)
                .padding()
        }
    }
}
