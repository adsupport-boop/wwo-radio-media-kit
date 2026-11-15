import SwiftUI

@main
struct WWORadioApp: App {
    @StateObject private var radio = RadioPlayer()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(radio)
        }
    }
}
