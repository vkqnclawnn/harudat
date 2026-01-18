//
//  ddotWidgetLiveActivity.swift
//  ddotWidget
//
//  Created by builder on 1/17/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ddotWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ddotWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ddotWidgetAttributes.self) { context in
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

extension ddotWidgetAttributes {
    fileprivate static var preview: ddotWidgetAttributes {
        ddotWidgetAttributes(name: "World")
    }
}

extension ddotWidgetAttributes.ContentState {
    fileprivate static var smiley: ddotWidgetAttributes.ContentState {
        ddotWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ddotWidgetAttributes.ContentState {
         ddotWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ddotWidgetAttributes.preview) {
   ddotWidgetLiveActivity()
} contentStates: {
    ddotWidgetAttributes.ContentState.smiley
    ddotWidgetAttributes.ContentState.starEyes
}
