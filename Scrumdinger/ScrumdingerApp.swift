//
//  ScrumdingerApp.swift
//  Scrumdinger
//
//  Created by Miguel Ibañez Patricio on 18/12/20.
//

import SwiftUI

@main
struct ScrumdingerApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ScrumsView(scrums: DailyScrum.data)
            }
        }
    }
}
