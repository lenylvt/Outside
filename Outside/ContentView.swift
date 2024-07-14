//
//  ContentView.swift
//  Outside
//
//  Created by Leny Levant on 14/07/2024.
//

import SwiftUI
import UserNotifications
import ActivityKit
import WidgetKit

struct ReminderAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var reminderInterval: TimeInterval
    }
}

@MainActor
class ReminderManager: ObservableObject {
    @Published var reminderInterval: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
    @Published var seconds: Int = 0
    @Published var isTimerActive: Bool = false
    @Published var nextReminderTime: Date?
    
    var intervalSeconds: TimeInterval {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderInterval)
        return TimeInterval((components.hour! * 3600) + (components.minute! * 60) + seconds)
    }
    
    private var liveActivity: Activity<ReminderAttributes>?
    
    func startTimer() {
        isTimerActive = true
        scheduleRepeatingNotifications()
        startLiveActivity()
    }
    
    func stopTimer() {
        isTimerActive = false
        nextReminderTime = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        endLiveActivity()
    }
    
    private func scheduleRepeatingNotifications() {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Time to Prevent ⚠️"
        content.body = "It's time to prevent your parent about how you are!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        
        let request = UNNotificationRequest(identifier: "parentPreventionReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Repeating notifications scheduled successfully")
                self.updateNextReminderTime()
            }
        }
    }
    
    private func updateNextReminderTime() {
        nextReminderTime = Date().addingTimeInterval(intervalSeconds)
    }
    
    private func startLiveActivity() {
        let attributes = ReminderAttributes()
        let contentState = ReminderAttributes.ContentState(reminderInterval: intervalSeconds)
        
        do {
            let content = ActivityContent(state: contentState, staleDate: nil)
            liveActivity = try Activity.request(attributes: attributes, content: content)
            print("Requested a Live Activity \(liveActivity?.id ?? "")")
        } catch {
            print("Error requesting Live Activity \(error.localizedDescription)")
        }
    }
    
    private func endLiveActivity() {
        Task {
            for activity in Activity<ReminderAttributes>.activities {
                await activity.end(activity.content, dismissalPolicy: .immediate)
            }
        }
    }
}

struct ReminderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReminderAttributes.self) { context in
            VStack(spacing: 8) {
                Text("You are outside!")
                    .font(.headline)
                Text("Remember to send message to parent")
                    .font(.subheadline)
                Text("Auto-Remember Active")
                    .font(.caption)
                Text("Every \(formatTimeInterval(context.state.reminderInterval))")
                    .font(.caption2)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("You are outside!")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Auto-Remember Active")
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Remember to send message to parent")
                        .font(.caption2)
                    Text("Every \(formatTimeInterval(context.state.reminderInterval))")
                        .font(.caption2)
                }
            } compactLeading: {
                Image(systemName: "person.wave.2")
            } compactTrailing: {
                Text(formatTimeInterval(context.state.reminderInterval))
                    .font(.caption2)
            } minimal: {
                Image(systemName: "person.wave.2")
            }
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
}

struct ContentView: View {
    @StateObject private var reminderManager = ReminderManager()
    @State private var showingAlert = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("Parent Prevention")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(15)
                
                VStack {
                    Text("Set Reminder Interval")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    DatePicker("", selection: $reminderManager.reminderInterval, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .cornerRadius(15)
                
                Text("Interval: \(intervalFormatted(reminderManager.reminderInterval, seconds: reminderManager.seconds))")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Button(action: {
                    if reminderManager.isTimerActive {
                        reminderManager.stopTimer()
                    } else {
                        reminderManager.startTimer()
                    }
                }) {
                    Text(reminderManager.isTimerActive ? "I'm at home" : "Start Reminders")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 200)
                        .background(reminderManager.isTimerActive ? Color.green : Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                if reminderManager.isTimerActive {
                    VStack {
                        Text("Reminders active")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        if let nextReminder = reminderManager.nextReminderTime {
                            Text("Next reminder at: \(nextReminderTimeFormatted(nextReminder))")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                }
            }
            .padding()
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied")
                    showingAlert = true
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Permissions required"),
                message: Text("To receive notifications, please allow notifications for this app in your device settings."),
                primaryButton: .default(Text("Open Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func intervalFormatted(_ date: Date, seconds: Int) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d:%02d", components.hour!, components.minute!, seconds)
    }
    
    func nextReminderTimeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
