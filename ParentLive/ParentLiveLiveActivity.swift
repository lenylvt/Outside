//
//  ParentLiveLiveActivity.swift
//  ParentLive
//
//  Created by Leny Levant on 14/07/2024.
//

import SwiftUI
import ActivityKit
import WidgetKit

struct ReminderAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var reminderInterval: TimeInterval
    }
}

@main
struct ParentLiveWidgetBundle: WidgetBundle {
    var body: some Widget {
        ReminderLiveActivity()
    }
}

struct ReminderLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReminderAttributes.self) { context in
            LockScreenLiveActivityView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("You are outside!")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 20) // Add padding at the top
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Auto-Remember Active")
                        .font(.caption)
                        .padding(.bottom, 20) // Add padding at the bottom
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

struct LockScreenLiveActivityView: View {
    let state: ReminderAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 10) {
            Text("You are outside!")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20) // Add padding at the top
            Text("Auto-Remember Active for Every : \(formatTimeInterval(state.reminderInterval))")
                .font(.caption)
                .padding(.bottom, 20) // Add padding at the bottom
        }
        .padding(.vertical, 20) // Add padding at the top and bottom
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
}
