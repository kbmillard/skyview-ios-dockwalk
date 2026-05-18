import SwiftUI

/// Single source of truth for all design values in DockWalk.
/// Zero raw hex, system fonts, or magic numbers allowed outside this file.
enum Tokens {
    
    // MARK: - Color
    
    enum Color {
        
        // MARK: Surface
        enum Surface {
            /// Page background: #FAFAF7 light / #0A1428 dark
            static let canvas = SwiftUI.Color("Surface/Canvas")
            /// Cards, sheets: #FFFFFF light / #111B30 dark
            static let card = SwiftUI.Color("Surface/Card")
            /// Pressed/active card states: #FFFFFF light / #1A2440 dark
            static let elevated = SwiftUI.Color("Surface/Elevated")
        }
        
        // MARK: Ink
        enum Ink {
            /// Primary text: #0A1428 light / #FFFFFF dark
            static let primary = SwiftUI.Color("Ink/Primary")
            /// Secondary text: #5F6878 light / #9CA3AF dark
            static let secondary = SwiftUI.Color("Ink/Secondary")
            /// Tertiary text: #9CA3AF light / #6B7280 dark
            static let tertiary = SwiftUI.Color("Ink/Tertiary")
            /// Text on Accent.horizon fill: #FFFFFF light / #0A1428 dark
            static let inverse = SwiftUI.Color("Ink/Inverse")
        }
        
        // MARK: Accent
        enum Accent {
            /// Brand color - active state, primary CTA, links: #1E7BFF (both modes)
            static let horizon = SwiftUI.Color("Accent/Horizon")
            /// Tint backgrounds: #E8F1FF light / #1E7BFF at 18% opacity dark
            static let horizonSoft = SwiftUI.Color("Accent/HorizonSoft")
        }
        
        // MARK: Signal
        enum Signal {
            /// Completion, healthy counts: #34C77B
            static let success = SwiftUI.Color("Signal/Success")
            /// Attention, moderate severity: #FFB020
            static let warning = SwiftUI.Color("Signal/Warning")
            /// Errors, blockers, critical severity: #FF4D4D
            static let critical = SwiftUI.Color("Signal/Critical")
        }
        
        // MARK: Divider
        enum Divider {
            /// 0.5pt borders, section dividers: #ECEEF2 light / #1F2937 dark
            static let hairline = SwiftUI.Color("Divider/Hairline")
        }
    }
    
    // MARK: - Typography
    
    /// Font definitions without tracking (tracking applied via view modifiers)
    enum Font {
        
        // MARK: Display (SF Pro Display, fixed size, no Dynamic Type)
        
        /// Hero pick quantity: 84pt Black, -3% tracking
        static let displayQuantity: SwiftUI.Font = .system(size: 84, weight: .black, design: .default)
        
        /// Location codes, SKU on confirm: 56pt Bold, -2% tracking
        static let displayHero: SwiftUI.Font = .system(size: 56, weight: .bold, design: .default)
        
        /// Dashboard stat numbers: 44pt Bold, -1.5% tracking
        static let displayMetric: SwiftUI.Font = .system(size: 44, weight: .bold, design: .default)
        
        // MARK: Title (SF Pro Text, supports Dynamic Type)
        
        /// Section headers: 22pt Semibold, -1% tracking
        static let titleSection: SwiftUI.Font = .system(size: 22, weight: .semibold, design: .default)
        
        /// Card titles: 17pt Semibold, -0.3% tracking
        static let titleCard: SwiftUI.Font = .system(size: 17, weight: .semibold, design: .default)
        
        // MARK: Body (SF Pro Text, supports Dynamic Type)
        
        /// Descriptions, item names: 17pt Regular
        static let bodyDefault: SwiftUI.Font = .system(size: 17, weight: .regular, design: .default)
        
        /// Subtitles: 15pt Regular
        static let bodySecondary: SwiftUI.Font = .system(size: 15, weight: .regular, design: .default)
        
        /// UPPERCASE labels: 11pt Medium, +1.2pt tracking
        static let bodyMeta: SwiftUI.Font = .system(size: 11, weight: .medium, design: .default)
        
        // MARK: Mono (SF Mono, fixed size)
        
        /// Barcodes, LPN, SKU strings: 15pt Medium
        static let monoCode: SwiftUI.Font = .system(size: 15, weight: .medium, design: .monospaced)
    }
    
    // MARK: - Tracking Values
    
    /// Letter spacing/tracking values (applied as view modifiers)
    enum Tracking {
        /// Display quantity: -3% of 84pt = -2.52pt
        static let displayQuantity: CGFloat = -2.52
        /// Display hero: -2% of 56pt = -1.12pt
        static let displayHero: CGFloat = -1.12
        /// Display metric: -1.5% of 44pt = -0.66pt
        static let displayMetric: CGFloat = -0.66
        /// Title section: -1% of 22pt = -0.22pt
        static let titleSection: CGFloat = -0.22
        /// Title card: -0.3% of 17pt = -0.051pt
        static let titleCard: CGFloat = -0.051
        /// Body meta (UPPERCASE labels): +1.2pt
        static let bodyMeta: CGFloat = 1.2
    }
    
    // MARK: - Spacing (4pt base grid)
    
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let base: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Radius
    
    enum Radius {
        /// Status chips, role badges
        static let pill: CGFloat = 999
        /// Cards, list rows
        static let card: CGFloat = 16
        /// Bottom sheets
        static let sheet: CGFloat = 28
        /// Fully circular (pass the view's height)
        static func disc(height: CGFloat) -> CGFloat {
            return height / 2
        }
    }
    
    // MARK: - Motion
    
    enum Motion {
        /// Spring for state changes: response 0.45s, damping 0.82
        static let morph: Animation = .spring(response: 0.45, dampingFraction: 0.82)
        /// Spring for settling: response 0.5s, damping 0.88
        static let settle: Animation = .spring(response: 0.5, dampingFraction: 0.88)
        /// Fade in/out: 0.2s ease
        static let fade: Animation = .easeInOut(duration: 0.2)
    }
    
    // MARK: - Tap Targets (workers wear gloves)
    
    enum TapTarget {
        /// Minimum tap target: 56pt (NOT 44pt)
        static let minimum: CGFloat = 56
        /// Primary CTA height
        static let primaryCTA: CGFloat = 56
        /// Secondary button height
        static let secondaryButton: CGFloat = 52
        /// Scan trigger disc diameter
        static let scanDisc: CGFloat = 64
        /// Icon-only button size
        static let iconButton: CGFloat = 56
    }
}
