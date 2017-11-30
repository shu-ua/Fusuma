//
//  FSVideoCameraView.swift
//  Fusuma
//
//  Created by Brendan Kirchner on 3/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import NextLevel

@objc protocol FSVideoCameraViewDelegate: class {
    func videoFinished(withFileURL fileURL: URL)
}

final class FSVideoCameraView: UIView {
    
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet var timescaleLabel: UILabel!
    
    weak var delegate: FSVideoCameraViewDelegate? = nil
    
    var focusView: UIView?
    
    var flashOffImage: UIImage?
    var flashOnImage: UIImage?
    var videoStartImage: UIImage?
    var videoStopImage: UIImage?
    
    var startCameraAfterSessionStop: Bool = false
    
    var maxVideoTimescale: Double?
    private var maxVideoTimescaleString: String?
    
    lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    fileprivate var isRecording = false
    
    static func instance() -> FSVideoCameraView {
        
        return UINib(nibName: "FSVideoCameraView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSVideoCameraView
    }
    
    func show() {
        self.backgroundColor = fusumaBackgroundColor
        self.isHidden = false
    }
    
    func initialize() {
        
        self.show()
        self.updateTimestampLabelVisability()
        
        NextLevel.shared.previewLayer.frame = self.previewViewContainer.bounds
        self.previewViewContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.previewViewContainer.backgroundColor = UIColor.black
        self.previewViewContainer.layer.addSublayer(NextLevel.shared.previewLayer)
        
        // Focus View
        self.focusView         = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
        let tapRecognizer      = UITapGestureRecognizer(target: self, action: #selector(FSVideoCameraView.focus(_:)))
        self.previewViewContainer.addGestureRecognizer(tapRecognizer)
        
        let bundle = Bundle(for: self.classForCoder)
        
        flashOnImage = fusumaFlashOnImage != nil ? fusumaFlashOnImage : UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage = fusumaFlashOffImage != nil ? fusumaFlashOffImage : UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage = fusumaFlipImage != nil ? fusumaFlipImage : UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)
        videoStartImage = fusumaVideoStartImage != nil ? fusumaVideoStartImage : UIImage(named: "video_button", in: bundle, compatibleWith: nil)
        videoStopImage = fusumaVideoStopImage != nil ? fusumaVideoStopImage : UIImage(named: "video_button_rec", in: bundle, compatibleWith: nil)
        
        if(fusumaTintIcons) {
            flashButton.tintColor = fusumaBaseTintColor
            flipButton.tintColor  = fusumaBaseTintColor
            shotButton.tintColor  = fusumaBaseTintColor
            
            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            flipButton.setImage(flipImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            shotButton.setImage(videoStartImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
        } else {
            flashButton.setImage(flashOffImage, for: UIControlState())
            flipButton.setImage(flipImage, for: UIControlState())
            shotButton.setImage(videoStartImage, for: UIControlState())
        }
        
        // Configure NextLevel by modifying the configuration ivars
        let nextLevel = NextLevel.shared
        nextLevel.videoDelegate = self
        nextLevel.delegate = self
        
        // video configuration
        nextLevel.videoConfiguration.bitRate = 2000000
        if let maxVideoTimescale = self.maxVideoTimescale {
            nextLevel.videoConfiguration.maximumCaptureDuration = CMTimeMakeWithSeconds(maxVideoTimescale, 1000)
        }
        nextLevel.videoConfiguration.aspectRatio = .square
        nextLevel.videoConfiguration.scalingMode = AVVideoScalingModeResizeAspectFill
        
        // audio configuration
        nextLevel.audioConfiguration.bitRate = 96000
        
        flashConfiguration()
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func startCamera() {
        
        let nextLevel = NextLevel.shared
        
        //
        if nextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
            if NextLevel.shared.session == nil {
            do {
                try nextLevel.start()
            } catch {
                print("NextLevel, failed to start camera session")
            }
            } else {
                self.stopCamera()
                startCameraAfterSessionStop = true
            }
        } else {
            nextLevel.requestAuthorization(forMediaType: AVMediaType.video)
            nextLevel.requestAuthorization(forMediaType: AVMediaType.audio)
        }
        //        }
    }
    
    func stopCamera() {
        NextLevel.shared.stop()
    }
    
    @IBAction func shotButtonPressed(_ sender: UIButton) {
        
        self.toggleRecording()
    }
    
    fileprivate func toggleRecording() {
        
        self.isRecording = !self.isRecording
        
        let shotImage: UIImage?
        if self.isRecording {
            shotImage = videoStopImage
        } else {
            shotImage = videoStartImage
        }
        self.shotButton.setImage(shotImage, for: UIControlState())
        
        if self.isRecording {
            self.flipButton.isEnabled = false
            self.flashButton.isEnabled = false
            NextLevel.shared.record()
        } else {
            self.flipButton.isEnabled = true
            self.flashButton.isEnabled = true
            NextLevel.shared.pause()
        }
        return
    }
    
    func endCapturing(withClip clip: NextLevelClip) {
        
        if let url = clip.url {
            self.delegate?.videoFinished(withFileURL: url)
        } else {
            print("wrong output url")
        }
    }
    
    @IBAction func flipButtonPressed(_ sender: UIButton) {
        
        NextLevel.shared.flipCaptureDevicePosition()
    }
    
    @IBAction func flashButtonPressed(_ sender: UIButton) {
        
        if NextLevel.shared.isFlashAvailable {
            let fleshMode = NextLevel.shared.flashMode
            
            if fleshMode == .off {
                NextLevel.shared.flashMode = .on
                flashButton.setImage(flashOnImage, for: UIControlState())
            } else if fleshMode == .on {
                NextLevel.shared.flashMode = .off
                flashButton.setImage(flashOffImage, for: UIControlState())
            }
        }
    }
    
    //MARK: - Timestamp
    private func updateTimestampLabelVisability() {
        if let _ = maxVideoTimescale {
            updateTimestampLabelValue()
            self.timescaleLabel.isHidden = false
        } else {
            self.timescaleLabel.isHidden = true
        }
    }
    
    fileprivate func updateTimestampLabelValue(withTime time:CMTime? = nil) {
        if self.maxVideoTimescaleString == nil {
            self.maxVideoTimescaleString = timescaleToString(withDouble: self.maxVideoTimescale!)
        }
        
        let currentTimestampString: String?
        if let time = time {
            currentTimestampString = timescaleToString(withTime: time)
        } else {
            currentTimestampString = timescaleToString(withDouble: 0)
        }
        
        self.timescaleLabel.text = "\(currentTimestampString!) / \(self.maxVideoTimescaleString!)"
        
    }
    
    private func timescaleToString(withTime time: CMTime) -> String {
        let seconds = CMTimeGetSeconds(time)
        return timescaleToString(withDouble: seconds)
    }
    
    private func timescaleToString(withDouble doubleValue:Double) -> String {
        return dateComponentsFormatter.string(from: doubleValue)!
    }
    
    private func timeText(from value: Int) -> String {
        return value < 10 ? "0\(value)" : "\(value)"
    }
}

extension FSVideoCameraView: NextLevelVideoDelegate {
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
        
    }
    
    
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
        
    }
    
    
    func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, onQueue queue: DispatchQueue) {
        
    }
    
    // video zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }
    
    // video frame processing
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
    }
    
    // enabled by isCustomContextVideoRenderingEnabled
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
    }
    
    // video recording session
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
        print("setup video")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
        print("setup audio")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
        print("didStartClipInSession")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
        print("nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession)")
        self.endCapturing(withClip: clip)
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        if let _ = self.maxVideoTimescale {
            self.updateTimestampLabelValue(withTime: session.duration)
        }
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        // called when a configuration time limit is specified
        print("nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession)")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        
    }
    
}

extension FSVideoCameraView: NextLevelDelegate {
    
    // permission
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: AVMediaType) {
        print("NextLevel, authorization updated for media \(mediaType) status \(status)")
        if nextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
            do {
                try nextLevel.start()
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else if status == .notAuthorized {
            // gracefully handle when audio/video is not authorized
            print("NextLevel doesn't have authorization for audio or video")
        }
    }
    
    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
    }
    
    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        if startCameraAfterSessionStop {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startCamera()
                self.startCameraAfterSessionStop = false
            }
        }
    }
    
    // interruption
    func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
    }
    
    func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
    }
    
    // preview
    func nextLevelWillStartPreview(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidStopPreview(_ nextLevel: NextLevel) {
    }
    
    // mode
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }
    
}


extension FSVideoCameraView {
    
    @objc func focus(_ recognizer: UITapGestureRecognizer) {
        
        let point = recognizer.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        
        NextLevel.shared.focusExposeAndAdjustWhiteBalance(atAdjustedPoint: newPoint)
        
        self.focusView?.alpha = 0.0
        self.focusView?.center = point
        self.focusView?.backgroundColor = UIColor.clear
        self.focusView?.layer.borderColor = UIColor.white.cgColor
        self.focusView?.layer.borderWidth = 1.0
        self.focusView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.addSubview(self.focusView!)
        
        UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 3.0, options: UIViewAnimationOptions.curveEaseIn, // UIViewAnimationOptions.BeginFromCurrentState
            animations: {
                self.focusView!.alpha = 1.0
                self.focusView!.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: {(finished) in
            self.focusView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.focusView!.removeFromSuperview()
        })
    }
    
    func flashConfiguration() {
        
        if !NextLevel.shared.isFlashAvailable {
            NextLevel.shared.flashMode = .off
            flashButton.setImage(flashOffImage, for: UIControlState())
        }
    }
    
}
