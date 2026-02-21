import Foundation
import ActivityKit
import UserNotifications

// MARK: - Live Activity Attributes
public struct NavigationAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic content that updates (e.g. Turn instruction, ETA)
        public var currentInstruction: String
        public var nextInstruction: String?
        public var etaSeconds: TimeInterval
        public var distanceMeters: Double
        public var stepIndex: Int
        public var totalSteps: Int
        
        public init(currentInstruction: String, nextInstruction: String? = nil, etaSeconds: TimeInterval, distanceMeters: Double, stepIndex: Int, totalSteps: Int) {
            self.currentInstruction = currentInstruction
            self.nextInstruction = nextInstruction
            self.etaSeconds = etaSeconds
            self.distanceMeters = distanceMeters
            self.stepIndex = stepIndex
            self.totalSteps = totalSteps
        }
    }

    // Static content (e.g. Destination Name)
    public var destinationName: String
    
    public init(destinationName: String) {
        self.destinationName = destinationName
    }
}
