//
//  ContentView.swift
//  EdupageWidget
//
//  Created by Ivan Hrabcak on 07/05/2024.
//

import SwiftUI

struct ContentView: View {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Version: " +  version)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
