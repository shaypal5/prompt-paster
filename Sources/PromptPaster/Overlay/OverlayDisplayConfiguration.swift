import AppKit

enum OverlaySizeMode: String, CaseIterable, Identifiable {
    case percentageOfDisplay
    case fixedPixels

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .percentageOfDisplay:
            "Percentage of display"
        case .fixedPixels:
            "Fixed pixel size"
        }
    }
}

struct OverlayDisplayConfiguration: Equatable {
    static let defaultDisplayPercentage = 80
    static let minimumDisplayPercentage = 40
    static let maximumDisplayPercentage = 95
    static let defaultFixedWidthPixels = 1100
    static let defaultFixedHeightPixels = 720
    static let minimumPercentageModeWidthPixels = 520
    static let minimumPercentageModeHeightPixels = 340
    static let minimumFixedModeWidthPixels = 760
    static let maximumFixedModeWidthPixels = 2400
    static let minimumFixedModeHeightPixels = 480
    static let maximumFixedModeHeightPixels = 1600

    let sizeMode: OverlaySizeMode
    let displayPercentage: Int
    let fixedWidth: Int
    let fixedHeight: Int

    func size(for visibleFrame: NSRect) -> CGSize {
        let requestedSize: CGSize
        let minimumWidth: Int
        let minimumHeight: Int

        switch sizeMode {
        case .percentageOfDisplay:
            let scale = CGFloat(displayPercentage) / 100
            requestedSize = CGSize(
                width: visibleFrame.width * scale,
                height: visibleFrame.height * scale
            )
            minimumWidth = Self.minimumPercentageModeWidthPixels
            minimumHeight = Self.minimumPercentageModeHeightPixels
        case .fixedPixels:
            requestedSize = CGSize(width: fixedWidth, height: fixedHeight)
            minimumWidth = Self.minimumFixedModeWidthPixels
            minimumHeight = Self.minimumFixedModeHeightPixels
        }

        return CGSize(
            width: Self.clampedDimension(
                requestedSize.width,
                minimum: minimumWidth,
                maximum: visibleFrame.width
            ),
            height: Self.clampedDimension(
                requestedSize.height,
                minimum: minimumHeight,
                maximum: visibleFrame.height
            )
        )
    }

    private static func clampedDimension(
        _ value: CGFloat,
        minimum: Int,
        maximum: CGFloat
    ) -> CGFloat {
        guard maximum > 0 else {
            return CGFloat(minimum)
        }
        let displayBoundedMinimum = min(CGFloat(minimum), maximum)
        return min(max(value, displayBoundedMinimum), maximum)
    }
}
