//
//  WalkWidget.swift
//  WalkWidget
//
//  Created by ParkJonghyun on 2021/03/12.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), walkCnt: 128)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(date: Date(), walkCnt: 128)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
      
        HealthKitManager.shared.getTodayStepCount { (step) in
            MotionManager.shared.startCountingSteps { (step) in
            }
            let entry = WidgetEntry(date: currentDate, walkCnt: Int(step))
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
        
        
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let walkCnt: Int
}

struct WalkWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.date, style: .time)
            Text("걸음 수 : \(entry.walkCnt.withCommas())")
        }
    }
}

@main
struct WalkWidget: Widget {
    let kind: String = "WalkWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WalkWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        
    }
}
