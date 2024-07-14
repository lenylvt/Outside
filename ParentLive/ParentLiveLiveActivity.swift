//
//  ParentLiveLiveActivity.swift
//  ParentLive
//
//  Created by Leny Levant on 14/07/2024.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ParentLiveAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ParentLiveLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParentLiveAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension ParentLiveAttributes {
    fileprivate static var preview: ParentLiveAttributes {
        ParentLiveAttributes(name: "World")
    }
}

extension ParentLiveAttributes.ContentState {
    fileprivate static var smiley: ParentLiveAttributes.ContentState {
        ParentLiveAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ParentLiveAttributes.ContentState {
         ParentLiveAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ParentLiveAttributes.preview) {
   ParentLiveLiveActivity()
} contentStates: {
    ParentLiveAttributes.ContentState.smiley
    ParentLiveAttributes.ContentState.starEyes
}
