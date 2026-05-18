import CoreHaptics
import UIKit

/// Haptic feedback patterns for DockWalk.
/// Uses CoreHaptics (not UIImpactFeedbackGenerator) to avoid cold-start latency.
/// Engine is started at app launch and kept warm.
final class Haptics {
    
    static let shared = Haptics()
    
    private var engine: CHHapticEngine?
    private let fallbackImpact = UIImpactFeedbackGenerator(style: .medium)
    
    private init() {
        prepareEngine()
    }
    
    // MARK: - Engine Lifecycle
    
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return // Fallback to UIImpactFeedbackGenerator
        }
        
        do {
            engine = try CHHapticEngine()
            
            // Register restart handler for system interruptions
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error.localizedDescription)")
                }
            }
            
            // Register stopped handler
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason.rawValue)")
            }
            
            // Start the engine and keep it warm
            try engine?.start()
            
        } catch {
            print("Failed to create haptic engine: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public API
    
    /// Single sharp transient: item scanned successfully
    static func scanSuccess() {
        shared.play(.scanSuccess)
    }
    
    /// Transient + 80ms continuous fade-out tail: item completed
    static func itemComplete() {
        shared.play(.itemComplete)
    }
    
    /// Three transients 50ms apart: exception, non-blocking warning
    static func exception() {
        shared.play(.exception)
    }
    
    /// 0.4s continuous full intensity + transient: critical error, blocker
    static func critical() {
        shared.play(.critical)
    }
    
    // MARK: - Pattern Definitions
    
    private enum Pattern {
        case scanSuccess
        case itemComplete
        case exception
        case critical
        
        var events: [CHHapticEvent] {
            switch self {
            case .scanSuccess:
                // Single sharp transient, intensity 1.0, sharpness 1.0, 60ms
                return [
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                        ],
                        relativeTime: 0,
                        duration: 0.06
                    )
                ]
                
            case .itemComplete:
                // Transient + 80ms continuous fade-out tail
                return [
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                        ],
                        relativeTime: 0
                    ),
                    CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                        ],
                        relativeTime: 0.02,
                        duration: 0.08
                    )
                ]
                
            case .exception:
                // Three transients 50ms apart, intensity 0.6
                return [
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                        ],
                        relativeTime: 0
                    ),
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                        ],
                        relativeTime: 0.05
                    ),
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                        ],
                        relativeTime: 0.10
                    )
                ]
                
            case .critical:
                // 0.4s continuous full intensity + transient
                return [
                    CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                        ],
                        relativeTime: 0,
                        duration: 0.4
                    ),
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                        ],
                        relativeTime: 0.4
                    )
                ]
            }
        }
    }
    
    // MARK: - Playback
    
    private func play(_ pattern: Pattern) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            // Fallback to UIImpactFeedbackGenerator
            fallbackImpact.impactOccurred()
            return
        }
        
        guard let engine = engine else {
            fallbackImpact.impactOccurred()
            return
        }
        
        do {
            let hapticPattern = try CHHapticPattern(events: pattern.events, parameters: [])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
            fallbackImpact.impactOccurred()
        }
    }
}
