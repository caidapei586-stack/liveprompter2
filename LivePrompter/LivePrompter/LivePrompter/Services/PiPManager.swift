import AVFoundation
import AVKit
import UIKit
import Combine

/// 画中画（PiP）管理器。
/// iOS 不允许第三方 App 画“真正的悬浮窗”，合规做法是把提词内容渲染成视频帧，
/// 通过 AVSampleBufferDisplayLayer 送入 PiP，从而浮在直播间等任何 App 之上。
final class PiPManager: NSObject, ObservableObject {
    @Published var isPiPAvailable = AVPictureInPictureController.isPictureInPictureSupported()
    @Published var isPiPActive = false

    let displayLayer = AVSampleBufferDisplayLayer()
    private var pipController: AVPictureInPictureController?
    private let videoSize = CGSize(width: 540, height: 960)
    private var pool: CVPixelBufferPool?

    override init() {
        super.init()
        displayLayer.videoGravity = .resizeAspectFill
        displayLayer.backgroundColor = UIColor.black.cgColor

        if #available(iOS 15.0, *) {
            let source = AVPictureInPictureController.ContentSource(
                sampleBufferDisplayLayer: displayLayer,
                playbackDelegate: self
            )
            pipController = AVPictureInPictureController(contentSource: source)
            pipController?.delegate = self
        }
        setupPool()
    }

    private func setupPool() {
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(videoSize.width),
            kCVPixelBufferHeightKey as String: Int(videoSize.height),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        CVPixelBufferPoolCreate(nil, nil, attrs as CFDictionary, &pool)
    }

    /// 必须由用户手势触发（按钮点击）。
    func startPiP() {
        guard isPiPAvailable else { return }
        pipController?.startPictureInPicture()
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
    }

    /// 渲染一帧：draw 回调负责把内容画进 CGContext（像素缓冲上下文，y 轴向上）。
    func enqueueFrame(_ draw: (CGContext, CGSize) -> Void) {
        guard let pool = pool else { return }
        var pb: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pb)
        guard let pb = pb else { return }
        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }

        let w = CVPixelBufferGetWidth(pb)
        let h = CVPixelBufferGetHeight(pb)
        guard let ctx = CGContext(
            data: CVPixelBufferGetBaseAddress(pb),
            width: w, height: h,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return }

        draw(ctx, CGSize(width: w, height: h))

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000),
            decodeTimeStamp: .invalid
        )
        var fmt: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pb, formatDescriptionOut: &fmt)
        guard let fmt = fmt else { return }
        var sb: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: nil, imageBuffer: pb, dataReady: true,
            makeDataReadyCallback: nil, refcon: nil,
            formatDescription: fmt, sampleTiming: &timing, sampleBufferOut: &sb
        )
        if let sb = sb { displayLayer.enqueue(sb) }
    }
}

extension PiPManager: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        isPiPActive = true
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        isPiPActive = false
    }
}

@available(iOS 15.0, *)
extension PiPManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ controller: AVPictureInPictureController, setPlaying playing: Bool) {}
    func pictureInPictureControllerTimeRangeForPlayback(_ controller: AVPictureInPictureController) -> CMTimeRange {
        CMTimeRange(start: .zero, duration: CMTime(value: 1, timescale: 1))
    }
    func pictureInPictureControllerIsPlaybackPaused(_ controller: AVPictureInPictureController) -> Bool { false }
    func pictureInPictureController(_ controller: AVPictureInPictureController,
                                    didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ controller: AVPictureInPictureController) -> Bool { false }
}
