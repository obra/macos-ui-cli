// ABOUTME: This file adds SwiftUI-specific extensions to the Application class.
// ABOUTME: It adds Hashable and Identifiable conformance needed for SwiftUI.

import Foundation
import MacOSUICLILib

// Make Application usable with SwiftUI
// We need to wrap it in our own class that conforms to Hashable
class ApplicationWrapper: Identifiable, Hashable, ObservableObject {
    let application: Application
    
    var id: Int32 { application.pid }
    var name: String { application.name }
    
    init(_ application: Application) {
        self.application = application
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(application.pid)
        hasher.combine(application.name)
    }
    
    public static func == (lhs: ApplicationWrapper, rhs: ApplicationWrapper) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name
    }
}