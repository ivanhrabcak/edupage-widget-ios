//
//  IntentHandler.swift
//  NextLessonIntent
//
//  Created by Ivan Hrabcak on 07/05/2024.
//

import Intents

class ConfigurationIntentHandler: INExtension, ConfigurationIntentIntentHandling {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
}
