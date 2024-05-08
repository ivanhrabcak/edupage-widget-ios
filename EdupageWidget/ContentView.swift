//
//  ContentView.swift
//  EdupageWidget
//
//  Created by Ivan Hrabcak on 07/05/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack (alignment: .leading, spacing: 5) {
            Image(systemName: "graduationcap") // 􀫓
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text([
                "",
                "1.  Go to the Home Screen",
                "2.  Go into the jiggle mode",
                "3.  Use the + icon and look for Edupage Widget",
                "4.  Add it",
                "5.  Click on that widget and type in your Edupage login details",
                ""
            ].joined(separator: "\n"))
            Link("Github", destination: URL(string: "https://github.com/ivanhrabcak/edupage-widget-ios")!)
        }
        .padding()
        
    }
}

#Preview {
    ContentView()
}
