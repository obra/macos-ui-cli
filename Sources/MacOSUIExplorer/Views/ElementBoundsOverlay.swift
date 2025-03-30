// ABOUTME: This file contains the overlay window for visualizing element bounds on screen.
// ABOUTME: It creates a transparent window that highlights the position of accessibility elements.

import SwiftUI
import AppKit
import MacOSUICLILib

/// Window controller for the element bounds overlay
class ElementBoundsOverlayController: NSObject {
    private var window: NSWindow?
    private var currentElement: ElementViewModel?
    
    /// Show the overlay for a specific element
    /// - Parameter element: The element to highlight
    func showOverlay(for element: ElementViewModel) {
        currentElement = element
        
        // Get the element's frame
        guard let frameValue = element.element.getAttributesNoThrow()["AXFrame"] as? CGRect,
              frameValue != .zero else {
            hideOverlay()
            return
        }
        
        // Create window if needed
        if window == nil {
            // Create a view model first
            let viewModel = createOverlayViewModel(for: element)
            
            // Create content view with environment object
            let contentView = ElementBoundsOverlayView()
                .environmentObject(viewModel)
            
            // Create hosting view with the content view
            let hostingView = NSHostingView(rootView: contentView)
            
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            window?.backgroundColor = .clear
            window?.isOpaque = false
            window?.hasShadow = false
            window?.level = .floating
            window?.ignoresMouseEvents = true
            window?.contentView = hostingView
        } else if let hostingView = window?.contentView as? NSHostingView<ElementBoundsOverlayView> {
            // Create new view model
            let viewModel = createOverlayViewModel(for: element)
            
            // Create and update root view
            let newRootView = ElementBoundsOverlayView()
            hostingView.rootView = newRootView
            
            // Apply environment object after setting the root view
            // This is a workaround for SwiftUI type issues
            DispatchQueue.main.async {
                let _ = hostingView.rootView.environmentObject(viewModel)
            }
        }
        
        // Set window frame to match element
        window?.setFrame(frameValue, display: true)
        window?.orderFront(nil)
    }
    
    /// Hide the overlay
    func hideOverlay() {
        window?.orderOut(nil)
        currentElement = nil
    }
    
    /// Create a view model for the overlay
    /// - Parameter element: The element to display
    /// - Returns: A view model for the overlay
    private func createOverlayViewModel(for element: ElementViewModel) -> ElementBoundsOverlayViewModel {
        return ElementBoundsOverlayViewModel(element: element)
    }
}

/// View model for the element bounds overlay
class ElementBoundsOverlayViewModel: ObservableObject {
    let element: ElementViewModel
    
    init(element: ElementViewModel) {
        self.element = element
    }
}

/// View for displaying the element bounds overlay
struct ElementBoundsOverlayView: View {
    @EnvironmentObject var viewModel: ElementBoundsOverlayViewModel
    
    var body: some View {
        ZStack {
            // Transparent background
            Color.clear
            
            // Highlight border
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color.red, lineWidth: 2)
                .background(Color.red.opacity(0.2))
        }
        .edgesIgnoringSafeArea(.all)
    }
}