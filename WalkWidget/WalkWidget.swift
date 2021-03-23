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
        var entries: [WidgetEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = WidgetEntry(date: entryDate, walkCnt: 0)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
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

struct WalkWidget_Previews: PreviewProvider {
    static var previews: some View {
        WalkWidgetEntryView(entry: WidgetEntry(date: Date(), walkCnt: 2138))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
