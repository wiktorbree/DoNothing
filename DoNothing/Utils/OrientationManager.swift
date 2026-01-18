import SwiftUI
import UIKit

class OrientationManager {
    static let shared = OrientationManager()
    
    // Default to portrait for iPhone, all for iPad (handled by system if not locked)
    var currentOrientationLock: UIInterfaceOrientationMask = .portrait
    
    func lock(_ orientation: UIInterfaceOrientationMask) {
        currentOrientationLock = orientation
        
        // Attempt to rotate to a supported orientation if current is invalid
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                // Handle error if needed, usually ignored for orientation request
                print("Orientation update rejected: \(error.localizedDescription)")
            }
        }
        
        // Create a geometry preference update if needed, but for locking
        // we just need to tell the system to re-evaluate supported orientations.
        
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        } else {
            // Fallback for older IDs if needed (not expected for current target)
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    static func setLocked(_ locked: Bool) {
        if UIDevice.current.userInterfaceIdiom == .phone {
             if locked {
                 OrientationManager.shared.lock(.portrait)
             } else {
                 OrientationManager.shared.lock(.allButUpsideDown)
             }
        }
        // iPad is always unlocked/standard behavior
    }
}
