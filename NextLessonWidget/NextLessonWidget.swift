//
//  NextLessonWidget.swift
//  NextLessonWidget
//
//  Created by Ivan Hrabcak on 07/05/2024.
//

import WidgetKit
import SwiftUI
import Foundation

fileprivate class Box<ResultType> {
    var result: Result<ResultType, Error>? = nil
}

/// Unsafely awaits an async function from a synchronous context.
@available(*, deprecated, message: "Migrate to structured concurrency")
func _unsafeWait<ResultType>(_ f: @escaping () async throws -> ResultType) throws -> ResultType {
    let box = Box<ResultType>()
    let sema = DispatchSemaphore(value: 0)
    Task {
        do {
            let val = try await f()
            box.result = .success(val)
        } catch {
            box.result = .failure(error)
        }
        sema.signal()
    }
    sema.wait()
    return try box.result!.get()
}

struct Provider: IntentTimelineProvider {
    typealias Entry = SimpleEntry
    typealias Intent = ConfigurationIntentIntent
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(
            date: Date.now,
            lesson: Lesson(
                name: "ANJ",
                classroom: "318",
                time: LessonDuration(
                    start: Date(timeIntervalSince1970: 1715090628),
                    end: Date(timeIntervalSince1970: 1715090628)
                ),
                lessonNumber: 3
            )
        )
    }
    
    func getSnapshot(for configuration: ConfigurationIntentIntent, in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(
            date: Date.now,
            lesson: Lesson(
                name: "ANJ",
                classroom: "318",
                time: LessonDuration(
                    start: Date(timeIntervalSince1970: 1715090628),
                    end: Date(timeIntervalSince1970: 1715090628)
                ),
                lessonNumber: 3
            )
        ))
    }
    
    func getTimeline(for configuration: ConfigurationIntentIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []
        print(configuration)
        
        var edupage = Edupage()

        let resultEntry: SimpleEntry? = try? _unsafeWait {
            let loginResult = await edupage.login(username: configuration.username ?? "", password: configuration.password ?? "", subdomain: configuration.subdomain ?? "")
            
            switch loginResult {
                case .success:
                    return nil
                case .invalidCredentials:
                    return SimpleEntry(date: Date.now, lesson: Lesson.nullLesson(), message: "Invalid credentials")
                case .networkError:
                    return SimpleEntry(date: Date.now, lesson: Lesson.nullLesson(), message: "Network error")
                case .missingConfiguration:
                    return SimpleEntry(date: Date.now, lesson: Lesson.nullLesson(), message: "Missing configuration")
            }
        }
        
        if resultEntry != nil {
            completion(Timeline(
                entries: [resultEntry!],
                policy: .after(
                    Calendar.current.date(
                        byAdding: .minute,
                        value: 10,
                        to: Date.now
                    )!
                )
            ))
            
            return
        }
        
        var timetableResult: TimetableResult = try! _unsafeWait {
            return await edupage.getTimetable(date: Date.now)
        }
        
        var timetable: Timetable? = nil
        switch timetableResult {
            case .success(let t):
                timetable = t
            case .missingData:
                completion(Timeline(
                    entries: [
                        SimpleEntry(
                            date: Date.now,
                            lesson: Lesson.nullLesson(),
                            message: "Unknown error - missing data"
                        )
                    ],
                    policy: .after(
                        Calendar.current.date(
                            byAdding: .minute,
                            value: 10,
                            to: Date.now
                        )!
                    )
                ))
                return
            case .noTimetableForDate:
                timetableResult = try! _unsafeWait { return await edupage.getTimetable(date: Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!) }
        }
        
        if timetable == nil {
            switch timetableResult {
                case .success(var t):
                    timetable = t
                case .missingData:
                    timetable = nil
                case .noTimetableForDate:
                    timetable = nil
            }
            
            
            if timetable == nil {
                completion(Timeline(entries: [], policy: .after(
                    Calendar.current.date(
                        byAdding: .minute,
                        value: 10,
                        to: Date.now
                    )!
                )))
                return
            }
        }
        
        for (i, lesson) in timetable!.lessons.enumerated() {
            entries.append(
                SimpleEntry(date: lesson.time.start, lesson: lesson)
            )
            
            if i == timetable!.lessons.endIndex - 1 {
                entries.append(
                    SimpleEntry(
                        date: lesson.time.end,
                        lesson: Lesson(
                            name: "END",
                            classroom: "",
                            time: LessonDuration(
                                start: Date.now,
                                end: Date.now
                            ),
                            lessonNumber: i + 1
                        )
                    )
                )
            }
        }
        
        if !entries.isEmpty {
            completion(
                Timeline(
                    entries: entries,
                    policy: .after(
                        Calendar.current.startOfDay(
                            for: Calendar.current.date(
                                byAdding: .day,
                                value: 1,
                                to: Date.now
                            )!
                        )
                    )
                )
            )

        } else {
            completion(
                Timeline(
                    entries: [
                        SimpleEntry(date: Date.now, lesson: Lesson.nullLesson(), message: "No school for today!")
                    ],
                    policy: .after(
                        Calendar.current.startOfDay(
                            for: Calendar.current.date(
                                byAdding: .day,
                                value: 1,
                                to: Date.now
                            )!
                        )
                    )
                )
            )
        }
        
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lesson: Lesson
    var message: String? = nil
    
    static func error(s: String) -> Timeline<SimpleEntry> {
        var entry = SimpleEntry(
            date: Date.now,
            lesson: Lesson(
                name: "",
                classroom: "",
                time: LessonDuration(start: Date.now, end: Date.now),
                lessonNumber: -1
            )
        )
        entry.message = s
        return Timeline(
            entries: [entry],
            policy: .after(
                Calendar.current.date(
                    byAdding: .minute,
                    value: 10,
                    to: Date.now
                )!
            )
            
        )
    }
}

struct NextLessonWidgetEntryView : View {
    var entry: Provider.Entry
    
    static func createDateFormatter() -> DateFormatter {
        let format = DateFormatter()
        format.locale = Locale.autoupdatingCurrent
        format.dateFormat = "hh:mm"
        
        return format
    }
    
    var format = createDateFormatter()

    var body: some View {
        VStack {
            if entry.message != nil {
                Text(entry.message!)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
            } else if entry.lesson.name != "END" {
                Text(
                    format.string(from: entry.lesson.time.start) + " - " + format.string(from: entry.lesson.time.end)
                ).font(.system(size: 18))
                Text(entry.lesson.name)
                    .bold()
                    .font(.system(size: 45))
                Text(entry.lesson.classroom)
                    .font(.system(size: 20))
            } else {
                Text("No more school for today!")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
            }
        }
    }
}

struct NextLessonWidget: Widget {
    let kind: String = "NextLessonWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntentIntent.self, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                NextLessonWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                NextLessonWidgetEntryView(entry: entry)
                    .padding()
            }
        }
        .configurationDisplayName("Next Lesson Widget")
        .description("Configure your edupage credentials.")
    }
}
