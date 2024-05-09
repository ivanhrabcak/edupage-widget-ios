//
//  ContentView.swift
//  EdupageWidget
//
//  Created by Ivan Hrabcak on 07/05/2024.
//

import SwiftUI
import WidgetKit

struct ColorView: View {
    var size: CGFloat
    var color: Color
    
    var body: some View {
        VStack {
            VStack{}.frame(width: size, height: size, alignment: .center)
        }
        .background(color)
    }
}

struct ContentView: View {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    let lessons = [
        Lesson(
            name: "FR",
            classroom: "118",
            time: LessonDuration(
                start: Date.now,
                end: Date.now.addingTimeInterval(TimeInterval
                    .init(integerLiteral: 600))
            ),
            lessonNumber: 1
        ),
        Lesson(
            name: "ENG",
            classroom: "315",
            time: LessonDuration(
                start: Date.now,
                end: Date.now.addingTimeInterval(TimeInterval
                    .init(integerLiteral: 1500))
            ),
            lessonNumber: 2
        ),
        Lesson(
            name: "ART",
            classroom: "13b",
            time: LessonDuration(
                start: Date.now,
                end: Date.now.addingTimeInterval(TimeInterval
                    .init(integerLiteral: 20))
            ),
            lessonNumber: 3
        ),
        Lesson(
            name: "GYM",
            classroom: "0153",
            time: LessonDuration(
                start: Date.now,
                end: Date.now.addingTimeInterval(TimeInterval
                    .init(integerLiteral: 90))
            ),
            lessonNumber: 4
        ),
        Lesson(
            name: "END",
            classroom: "",
            time: LessonDuration(start: Date.now, end: Date.now),
            lessonNumber: 5
        )
    ].enumerated()
        .flatMap { (i, lesson) in
            var newLesson = lesson
            newLesson.lessonNumber += 5
            return [lesson, newLesson]
        }
        .sorted { (a, b) in
            a.lessonNumber > b.lessonNumber
        }
    
    @State
    var xOffset: CGFloat = 0
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(lessons, id: \.lessonNumber) { lesson in
                            NextLessonWidgetEntryView(
                                entry: SimpleEntry(
                                    date: Date.now,
                                    lesson: lesson
                                )
                            ).previewContext(WidgetPreviewContext(family: .systemSmall))
                                .frame(width: 150, height: 150)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 15.0)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15.0)
                                        .stroke(.thickMaterial)
                                )
                                .id(lesson.lessonNumber)
                            
                        }
                    }
                    .offset(x: xOffset, y: 0)
                }
                .padding(0)
                .disabled(true)
                .onAppear {
                    withAnimation(.linear(duration: 10).repeatForever()) {
                        xOffset = -geometry.size.width
                    }
                }
            }.frame(height: 180)
            Text("Made by: [@ivanhrabcak](https://github.com/ivanhrabcak)")
            Text("Version: " +  version)
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
