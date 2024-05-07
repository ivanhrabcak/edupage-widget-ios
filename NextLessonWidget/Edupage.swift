//
//  Edupage.swift
//  EdupageWidget
//
//  Created by Ivan Hrabcak on 06/05/2024.
//

import Alamofire
import Foundation

struct LessonDuration {
    let start: Date
    let end: Date
}

struct Lesson {
    let name: String
    let classroom: String
    let time: LessonDuration
    let lessonNumber: Int
}

struct Timetable {
    let lessons: [Lesson]
}

struct Edupage {
    private var cookie: String? = nil
    private var session: Session
    private var data: [String: Any]? = nil
    
    init() {
        session = Session.init()
        session.sessionConfiguration.httpCookieStorage?.removeCookies(since: Date.distantPast)
    }
    
    mutating func login(username: String, password: String, subdomain: String) async throws {
        if subdomain == "" {
            return
        }
        
        let requestUrl = "https://\(subdomain).edupage.org/login/index.php"
        print(requestUrl)
        
        let response = await session.request(requestUrl)
            .serializingString()
            .response
        
        cookie = String(response.response!.headers["Set-Cookie"]!.split(separator: "PHPSESSID=")[0].split(separator: ";")[0])
        let csrfToken = String(
            String(decoding: response.data!, as: UTF8.self)
                .split(separator: "name=\"csrfauth\" value=\"")[1]
                .split(separator: "\"")[0]
        )
        
        let parameters = [
            "csrfauth": csrfToken,
            "username": username,
            "password": password
        ]
        
        let loginRequestUrl = "https://\(subdomain).edupage.org/login/edubarLogin.php"
        let loginResponse = await session.request(
            loginRequestUrl,
            method: .post,
            parameters: parameters
        )
            .serializingString()
            .response
        
        let rawData = (String(decoding: loginResponse.data!, as: UTF8.self))
        
        let jsonString = rawData.split(separator: "$j(document).ready(function() {")[1]
            .split(separator: ");")[0]
            .split(separator: "userhome(")[1]
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        
        data = try? JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as? [String: Any]
    }
    
    func idToSubject(subjectId: String) -> String {
        let dbi = data!["dbi"] as! [String: Any]
        let subjects = dbi["subjects"]! as! [String: Any]
        let subject = subjects[subjectId]! as! [String: Any]
        return subject["short"]! as! String
    }
    
    func idToClassroom(classroomId: String) -> String {
        let dbi = data!["dbi"] as! [String: Any]
        let subjects = dbi["classrooms"]! as! [String: Any]
        let subject = subjects[classroomId]! as! [String: Any]
        return subject["short"]! as! String
    }
    
    func getTimetable(date: Date) async -> Timetable? {
        if data == nil {
            return nil
        }
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        
        let dp = data?["dp"] as? [String: Any]
        if dp == nil {
            return nil
        }
        
        let dates = dp!["dates"] as? [String: Any]
        if dates == nil {
            return nil
        }
        
        let datePlans = dates![dateFormat.string(from: date)] as? [String: Any]
        if datePlans == nil {
            return nil
        }
        
        let plan = datePlans!["plan"] as? [[String: Any]]
        if plan == nil {
            return nil
        }
        
        var lessons = [Lesson]()
        for lesson in plan! {
            let header = lesson["header"]! as! [Any]
            if header.isEmpty || lesson["type"]! as! String != "lesson" {
                continue
            }
            
            let subjectId = lesson["subjectid"]! as! String
            let subject = idToSubject(subjectId: subjectId)
            
            let classroomIds = lesson["classroomids"]! as! [String]
            let classroomId = classroomIds[0]
            let classroomNumber = idToClassroom(classroomId: classroomId)
            
            let start = lesson["starttime"]! as! String
            let end = lesson["endtime"]! as! String
            
            let startParts = start.split(separator: ":", maxSplits: 2)
                .map { s in String(s) }
            let (startHour, startMinute) = (startParts.first!, startParts.last!)
            
            let endParts = end.split(separator: ":", maxSplits: 2)
                .map { s in String(s) }
            let (endHour, endMinute) = (endParts.first!, endParts.last!)
            
            let calendar = Calendar.current
            
            let lessonStart = calendar.date(
                bySettingHour: Int(startHour)!,
                minute: Int(startMinute)!,
                second: 0,
                of: Date.now
            )!
            
            let lessonEnd = calendar.date(
                bySettingHour: Int(endHour)!,
                minute: Int(endMinute)!,
                second: 0,
                of: Date.now
            )!
            
            let lessonDuration = LessonDuration(start: lessonStart, end: lessonEnd)
            let lessonNumber = Int(lesson["period"]! as! String)!
            
            lessons.append(
                Lesson(
                    name: subject,
                    classroom: classroomNumber,
                    time: lessonDuration,
                    lessonNumber: lessonNumber
                )
            )
            
        }
        
        return Timetable(lessons: lessons)
    }
}
