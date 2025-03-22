// ABOUTME: This file wraps the Haxcessibility library with Swift-friendly interfaces.
// ABOUTME: It provides Swift access to the Objective-C accessibility API.

import Foundation

#if HAXCESSIBILITY_AVAILABLE
import Haxcessibility
#endif

public class SystemAccessibility {
#if HAXCESSIBILITY_AVAILABLE
    public static func getSystem() -> HAXSystem? {
        return HAXSystem.system()
    }
    
    public static func getFocusedApplication() -> HAXApplication? {
        return HAXSystem.system().focusedApplication
    }
    
    public static func getApplicationWithPID(_ pid: pid_t) -> HAXApplication? {
        return HAXApplication.application(withPID: pid)
    }
#else
    public static func isAvailable() -> Bool {
        return false
    }
#endif
}