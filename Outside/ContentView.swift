//
//  ContentView.swift
//  Outside
//
//  Created by Leny Levant on 14/07/2024.
//

import SwiftUI
import UserNotifications

class ReminderManager: ObservableObject {
    @Published var reminderInterval: Date = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
    @Published var seconds: Int = 0
    @Published var isTimerActive: Bool = false
    @Published var nextReminderTime: Date?
    
    var intervalSeconds: TimeInterval {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderInterval)
        return TimeInterval((components.hour! * 3600) + (components.minute! * 60) + seconds)
    }
    
    func startTimer() {
        isTimerActive = true
        scheduleRepeatingNotifications()
    }
    
    func stopTimer() {
        isTimerActive = false
        nextReminderTime = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleRepeatingNotifications() {
        let content = UNMutableNotificationContent()
        content.title = "Parent Prevention Reminder"
        content.body = "It's time to prevent your parent!"
        content.sound = .default
        
        // Créer un déclencheur qui se répète
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: true)
        
        // Créer la demande de notification
        let request = UNNotificationRequest(identifier: "parentPreventionReminder", content: content, trigger: trigger)
        
        // Ajouter la notification à planifier
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de la planification de la notification : \(error.localizedDescription)")
            } else {
                print("Notifications répétées planifiées avec succès")
                self.updateNextReminderTime()
            }
        }
    }
    
    private func updateNextReminderTime() {
        nextReminderTime = Date().addingTimeInterval(intervalSeconds)
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
                Text("Parent Prevention Reminder")
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
                    
                    Stepper(value: $reminderManager.seconds, in: 0...59) {
                        Text("Seconds: \(reminderManager.seconds)")
                            .foregroundColor(.white)
                    }
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
                    print("Permission de notification accordée")
                } else {
                    print("Permission de notification refusée")
                    showingAlert = true
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Permissions requises"),
                message: Text("Pour recevoir des notifications, veuillez autoriser les notifications pour cette application dans les paramètres de votre appareil."),
                primaryButton: .default(Text("Ouvrir les paramètres"), action: openSettings),
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
