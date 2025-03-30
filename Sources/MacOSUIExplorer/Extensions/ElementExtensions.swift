// ABOUTME: This file adds SwiftUI-specific extensions to the Element class.
// ABOUTME: It adds Hashable and Identifiable conformance needed for SwiftUI.

import Foundation
import MacOSUICLILib

// Make Element usable with SwiftUI
// We need to wrap it in our own class that conforms to Hashable
class ElementWrapper: Identifiable, Hashable, ObservableObject {
    let element: Element
    
    var id: UUID = UUID()
    var role: String { element.role }
    var title: String { element.title }
    var roleDescription: String { element.roleDescription }
    var subRole: String { element.subRole }
    var hasChildren: Bool { element.hasChildren }
    var children: [Element] { element.children }
    
    init(_ element: Element) {
        self.element = element
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(role)
        hasher.combine(title)
        hasher.combine(roleDescription)
    }
    
    public static func == (lhs: ElementWrapper, rhs: ElementWrapper) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Helper functions that forward to the underlying Element
    func getAttributesNoThrow() -> [String: Any] {
        return element.getAttributesNoThrow()
    }
    
    func getAvailableActionsNoThrow() -> [String] {
        return element.getAvailableActionsNoThrow()
    }
    
    func loadChildrenIfNeeded() {
        element.loadChildrenIfNeeded()
    }
    
    func performAction(_ action: String) throws {
        try element.performAction(action)
    }
}