//
//  ViewController.swift
//  Fusuma
//
//  Created by ytakzk on 01/31/2016.
//  Copyright (c) 2016 ytakzk. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit
import PhotosUI

class ViewController: UIViewController, FusumaDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var playVideo: UIButton!
    
    @IBOutlet weak var fileUrlLabel: UILabel!
    private var videoFileURL: URL? {
        didSet {
            updateVideoPlayButton()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showButton.layer.cornerRadius = 2.0
        self.fileUrlLabel.text = ""
        updateVideoPlayButton()
    }

    @IBAction func showButtonPressed(_ sender: AnyObject) {
        // Show Fusuma
        let fusuma = FusumaViewController()
        
        fusuma.delegate = self
        fusuma.selectedMode = .library
        fusuma.allowedModes = [.library, .video]
        fusuma.maxVideoTimescale = 3

        self.present(fusuma, animated: true, completion: nil)
    }
    
    //MARK: - Video Preview
    @IBAction func playVideoButtonTouchUp(_ sender: Any) {
        guard let url = self.videoFileURL else {
            return
        }
        
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }
    
    private func updateVideoPlayButton() {
        if let _ = videoFileURL {
            self.playVideo.isHidden = false
        } else {
            self.playVideo.isHidden = true
        }
        imageView.image = nil
    }
    
    
    //MARK: - FusumaDelegate Protocol
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
        switch source {
        case .camera:
            print("Image captured from Camera")
        case .library:
            print("Image selected from Camera Roll")
        default:
            print("Image selected")
        }
        
        self.videoFileURL = nil
        imageView.image = image
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        print("video completed and output to file: \(fileURL)")

        self.videoFileURL = fileURL
    }
    
    func fusumaVideoCompleted(withPHAsset phAsset: PHAsset) {
        PHCachingImageManager().requestAVAsset(forVideo: phAsset, options: nil) { (asset, audioMix, info) in
            if let asset = asset as? AVURLAsset {
                self.videoFileURL = asset.url
            }
        }
    }
    
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {
        switch source {
        case .camera:
            print("Called just after dismissed FusumaViewController using Camera")
        case .library:
            print("Called just after dismissed FusumaViewController using Camera Roll")
        default:
            print("Called just after dismissed FusumaViewController")
        }
    }
    
    func fusumaCameraRollUnauthorized() {
        
        print("Camera roll unauthorized")
        
        let alert = UIAlertController(title: "Access Requested", message: "Saving image needs to access your photo album", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) -> Void in
            
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
            }

        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func fusumaFailed(_ withErrorMessage: String) {
        print(withErrorMessage)
    }
    
    func fusumaClosed() {
        print("Called when the FusumaViewController disappeared")
    }
    
    func fusumaWillClose() {
        print("Called when the close button is pressed")
    }

}

