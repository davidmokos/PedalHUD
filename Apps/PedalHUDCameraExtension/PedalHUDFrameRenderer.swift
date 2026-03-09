@preconcurrency import CoreImage
import CoreVideo
import Foundation
import PedalHUDCore
import SwiftUI

final class PedalHUDFrameRenderer: @unchecked Sendable {
    private let builder = OverlayHUDModelBuilder()
    private let ciContext = CIContext()

    func makeFrame(
        width: Int32,
        height: Int32,
        metrics: LiveMetrics,
        configuration: OverlayConfiguration = .defaultConfiguration,
        inputPixelBuffer: CVPixelBuffer? = nil
    ) -> CVPixelBuffer? {
        let attributes: [CFString: Any] = [
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as [String: Any],
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(width),
            Int(height),
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else {
            return nil
        }

        render(
            metrics: metrics,
            into: pixelBuffer,
            configuration: configuration,
            inputPixelBuffer: inputPixelBuffer
        )
        return pixelBuffer
    }

    func render(
        metrics: LiveMetrics,
        into pixelBuffer: CVPixelBuffer,
        configuration: OverlayConfiguration = .defaultConfiguration,
        inputPixelBuffer: CVPixelBuffer? = nil
    ) {
        let canvasSize = CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        )
        let extent = CGRect(origin: .zero, size: canvasSize)
        let hud = builder.build(metrics: metrics, configuration: configuration)
        let background = backgroundImage(in: extent, using: inputPixelBuffer)

        let baseImage: CIImage
        if hud.items.isEmpty {
            baseImage = background
        } else {
            baseImage = overlayImage(
                for: hud,
                canvasSize: canvasSize,
                configuration: configuration
            )
            .composited(over: background)
        }

        let outputImage = configuration.mirrorsOutput
            ? mirroredImage(from: baseImage, extent: extent)
            : baseImage

        ciContext.render(outputImage, to: pixelBuffer)
    }

    private func backgroundImage(in extent: CGRect, using inputPixelBuffer: CVPixelBuffer?) -> CIImage {
        if let inputPixelBuffer {
            let inputImage = CIImage(cvPixelBuffer: inputPixelBuffer)
            let scaledImage = aspectFill(inputImage: inputImage, extent: extent)
            let vignette = CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0.12))
                .cropped(to: extent)

            return vignette.composited(over: scaledImage)
        }

        let base = CIImage(color: CIColor(red: 0.08, green: 0.11, blue: 0.14, alpha: 1))
            .cropped(to: extent)
        let stripe = CIImage(color: CIColor(red: 0.92, green: 0.47, blue: 0.18, alpha: 0.22))
            .cropped(to: CGRect(x: 0, y: 0, width: extent.width, height: 96))
            .transformed(by: CGAffineTransform(translationX: 0, y: 72))

        return stripe.composited(over: base)
    }

    private func overlayImage(
        for hud: OverlayHUDModel,
        canvasSize: CGSize,
        configuration: OverlayConfiguration
    ) -> CIImage {
        let renderPanel = {
            MainActor.assumeIsolated {
                let panelWidth = min(max(canvasSize.width * 0.22, 250), 300)
                let panel = OverlayPanelView(model: hud)
                    .frame(width: panelWidth)
                    .fixedSize(horizontal: false, vertical: true)

                let renderer = ImageRenderer(content: panel)
                renderer.scale = 2
                renderer.proposedSize = .init(width: panelWidth, height: nil)

                guard let cgImage = renderer.cgImage else {
                    return CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0))
                        .cropped(to: CGRect(origin: .zero, size: canvasSize))
                }

                let image = CIImage(cgImage: cgImage)
                let origin = Self.origin(
                    for: hud.placement,
                    canvasSize: canvasSize,
                    panelSize: image.extent.size,
                    inset: configuration.cornerInset
                )

                return image.transformed(
                    by: CGAffineTransform(translationX: origin.x, y: origin.y)
                )
            }
        }

        if Thread.isMainThread {
            return renderPanel()
        }

        return DispatchQueue.main.sync(execute: renderPanel)
    }

    private static func origin(
        for placement: OverlayPlacement,
        canvasSize: CGSize,
        panelSize: CGSize,
        inset: Double
    ) -> CGPoint {
        let x: Double
        switch placement {
        case .topLeading, .bottomLeading:
            x = inset
        case .bottomCenter:
            x = (canvasSize.width - panelSize.width) / 2
        case .topTrailing, .bottomTrailing:
            x = canvasSize.width - panelSize.width - inset
        }

        let y: Double
        switch placement {
        case .topLeading, .topTrailing:
            y = canvasSize.height - panelSize.height - inset
        case .bottomLeading, .bottomCenter, .bottomTrailing:
            y = inset
        }

        return CGPoint(x: x, y: y)
    }

    private func aspectFill(inputImage: CIImage, extent: CGRect) -> CIImage {
        let scale = max(
            extent.width / inputImage.extent.width,
            extent.height / inputImage.extent.height
        )
        let scaledImage = inputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let xOffset = (extent.width - scaledImage.extent.width) / 2
        let yOffset = (extent.height - scaledImage.extent.height) / 2

        return scaledImage
            .transformed(by: CGAffineTransform(translationX: xOffset, y: yOffset))
            .cropped(to: extent)
    }

    private func mirroredImage(from image: CIImage, extent: CGRect) -> CIImage {
        image
            .transformed(
                by: CGAffineTransform(scaleX: -1, y: 1)
                    .translatedBy(x: -extent.width, y: 0)
            )
            .cropped(to: extent)
    }
}
