//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Photos

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


public protocol FusumaDelegate: class {
    // MARK: Required
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode)
    func fusumaVideoCompleted(withFileURL fileURL: URL)
    func fusumaCameraRollUnauthorized()
    func fusumaVideoCompleted(withPHAsset phAsset: PHAsset)
    func fusumaFailed(_ withErrorMessage: String)
    
    // MARK: Optional
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode)
    func fusumaClosed()
    func fusumaWillClosed()
}

public extension FusumaDelegate {
    func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {}
    func fusumaClosed() {}
    func fusumaWillClosed() {}
}

public var fusumaBaseTintColor   = UIColor.hex("#FFFFFF", alpha: 1.0)
public var fusumaTintColor       = UIColor.hex("#F38181", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#3B3D45", alpha: 1.0)

public var fusumaAlbumImage : UIImage? = nil
public var fusumaCameraImage : UIImage? = nil
public var fusumaVideoImage : UIImage? = nil
public var fusumaCheckImage : UIImage? = nil
public var fusumaCloseImage : UIImage? = nil
public var fusumaFlashOnImage : UIImage? = nil
public var fusumaFlashOffImage : UIImage? = nil
public var fusumaFlipImage : UIImage? = nil
public var fusumaShotImage : UIImage? = nil

public var fusumaVideoStartImage : UIImage? = nil
public var fusumaVideoStopImage : UIImage? = nil

public var fusumaCropImage: Bool = true

public var fusumaCameraRollTitle = "CAMERA ROLL"
public var fusumaCameraTitle = "PHOTO"
public var fusumaVideoTitle = "VIDEO"
public var fusumaTitleFont = UIFont(name: "AvenirNext-DemiBold", size: 15)

public var fusumaTintIcons : Bool = true

public enum FusumaMode {
    case camera
    case library
    case video
    
    static var all:[FusumaMode] = [.library, .camera, .video]
}

public class FusumaViewController: UIViewController {
    
    public var cropHeightRatio: CGFloat = 1
    public var allowedModes:[FusumaMode] = FusumaMode.all
    public var mode: FusumaMode = .camera
    public var selectedMode: FusumaMode = .library
    public var libraryMediaTypes: [PHAssetMediaType] = [.video, .image]
    public var maxVideoTimescale: Double?
    
    var willFilter = true
    
    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!
    @IBOutlet weak var videoShotContainer: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var libraryButton: FusumaModeButton!
    @IBOutlet weak var cameraButton: FusumaModeButton!
    @IBOutlet weak var videoButton: FusumaModeButton!
    
    @IBOutlet var modeButtonStackView: UIStackView!
    
    lazy var albumView  = FSAlbumView.instance()
    lazy var cameraView = FSCameraView.instance()
    lazy var videoView = FSVideoCameraView.instance()
    
    fileprivate var hasGalleryPermission: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func loadView() {
        
        if let view = UINib(nibName: "FusumaViewController", bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as? UIView {
            
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = fusumaBackgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self
        videoView.delegate = self
        
        albumView.libraryMediaTypes = libraryMediaTypes
        albumView.maxVideoTimescale = maxVideoTimescale
        videoView.maxVideoTimescale = maxVideoTimescale
        
        menuView.backgroundColor = fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.black, width: 1.0)
        
        let bundle = Bundle(for: self.classForCoder)
        
        // Get the custom button images if they're set
        let albumImage = fusumaAlbumImage != nil ? fusumaAlbumImage : UIImage(named: "ic_insert_photo", in: bundle, compatibleWith: nil)
        let cameraImage = fusumaCameraImage != nil ? fusumaCameraImage : UIImage(named: "ic_photo_camera", in: bundle, compatibleWith: nil)
        
        let videoImage = fusumaVideoImage != nil ? fusumaVideoImage : UIImage(named: "ic_videocam", in: bundle, compatibleWith: nil)
        
        let checkImage = fusumaCheckImage != nil ? fusumaCheckImage : UIImage(named: "ic_check", in: bundle, compatibleWith: nil)
        let closeImage = fusumaCloseImage != nil ? fusumaCloseImage : UIImage(named: "ic_close", in: bundle, compatibleWith: nil)
        
        if fusumaTintIcons {
            
            libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            libraryButton.tintColor = fusumaTintColor
            libraryButton.adjustsImageWhenHighlighted = false
            
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            cameraButton.tintColor  = fusumaTintColor
            cameraButton.adjustsImageWhenHighlighted  = false
            
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            closeButton.tintColor = fusumaBaseTintColor
            
            videoButton.setImage(videoImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            videoButton.setImage(videoImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            videoButton.setImage(videoImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            videoButton.tintColor  = fusumaTintColor
            videoButton.adjustsImageWhenHighlighted = false
            
            doneButton.setImage(checkImage?.withRenderingMode(.alwaysTemplate), for: UIControlState())
            doneButton.tintColor = fusumaBaseTintColor
            
        } else {
            
            libraryButton.setImage(albumImage, for: UIControlState())
            libraryButton.setImage(albumImage, for: .highlighted)
            libraryButton.setImage(albumImage, for: .selected)
            libraryButton.tintColor = nil
            
            cameraButton.setImage(cameraImage, for: UIControlState())
            cameraButton.setImage(cameraImage, for: .highlighted)
            cameraButton.setImage(cameraImage, for: .selected)
            cameraButton.tintColor = nil
            
            videoButton.setImage(videoImage, for: UIControlState())
            videoButton.setImage(videoImage, for: .highlighted)
            videoButton.setImage(videoImage, for: .selected)
            videoButton.tintColor = nil
            
            closeButton.setImage(closeImage, for: UIControlState())
            doneButton.setImage(checkImage, for: UIControlState())
        }
        
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true
        videoButton.clipsToBounds = true
        
        changeMode(self.selectedMode, forceUpdate: true)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)
        
        titleLabel.textColor = fusumaBaseTintColor
        titleLabel.font = fusumaTitleFont
        
        for mode in FusumaMode.all {
            if !allowedModes.contains(mode) {
                switch mode {
                case .library:
                    self.modeButtonStackView.removeArrangedSubview(self.libraryButton)
                case .camera:
                    self.modeButtonStackView.removeArrangedSubview(self.cameraButton)
                case .video:
                    self.modeButtonStackView.removeArrangedSubview(self.videoButton)
                }
            }
        }
        
        if fusumaCropImage {
            let heightRatio = getCropHeightRatio()
            cameraView.croppedAspectRatioConstraint = NSLayoutConstraint(item: cameraView.previewViewContainer, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: cameraView.previewViewContainer, attribute: NSLayoutAttribute.width, multiplier: heightRatio, constant: 0)
            
            cameraView.fullAspectRatioConstraint.isActive = false
            cameraView.croppedAspectRatioConstraint?.isActive = true
        } else {
            cameraView.fullAspectRatioConstraint.isActive = true
            cameraView.croppedAspectRatioConstraint?.isActive = false
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        for allowedMode in self.allowedModes {
            switch allowedMode {
            case .library:
                albumView.frame  = CGRect(origin: CGPoint.zero, size: photoLibraryViewerContainer.frame.size)
                albumView.layoutIfNeeded()
                albumView.initialize()
            case .camera:
                cameraView.frame = CGRect(origin: CGPoint.zero, size: cameraShotContainer.frame.size)
                cameraView.layoutIfNeeded()
                cameraView.initialize()
            case .video:
                videoView.frame = CGRect(origin: CGPoint.zero, size: videoShotContainer.frame.size)
                videoView.layoutIfNeeded()
                videoView.initialize()
            }
        }
        
        changeMode(self.selectedMode, forceUpdate: false)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAll()
    }
    
    override public var prefersStatusBarHidden : Bool {
        
        return true
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        self.delegate?.fusumaWillClosed()
        self.dismiss(animated: true, completion: {
            self.delegate?.fusumaClosed()
        })
    }
    
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        
        changeMode(FusumaMode.library)
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
        
        changeMode(FusumaMode.camera)
    }
    
    @IBAction func videoButtonPressed(_ sender: UIButton) {
        
        changeMode(FusumaMode.video)
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        let view = albumView.imageCropView
        
        if self.albumView.phAsset.mediaType == .video {
            
            self.delegate?.fusumaVideoCompleted(withPHAsset: self.albumView.phAsset)
            self.dismiss(animated: true, completion: {
            })
            
        } else {
            if fusumaCropImage {
                let normalizedX = (view?.contentOffset.x)! / (view?.contentSize.width)!
                let normalizedY = (view?.contentOffset.y)! / (view?.contentSize.height)!
                
                let normalizedWidth = (view?.frame.width)! / (view?.contentSize.width)!
                let normalizedHeight = (view?.frame.height)! / (view?.contentSize.height)!
                
                let cropRect = CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
                
                DispatchQueue.global(qos: .default).async(execute: {
                    
                    let options = PHImageRequestOptions()
                    options.deliveryMode = .highQualityFormat
                    options.isNetworkAccessAllowed = true
                    options.normalizedCropRect = cropRect
                    options.resizeMode = .exact
                    
                    let targetWidth = floor(CGFloat(self.albumView.phAsset.pixelWidth) * cropRect.width)
                    let targetHeight = floor(CGFloat(self.albumView.phAsset.pixelHeight) * cropRect.height)
                    let dimensionW = max(min(targetHeight, targetWidth), 1024 * UIScreen.main.scale)
                    let dimensionH = dimensionW * self.getCropHeightRatio()
                    
                    let targetSize = CGSize(width: dimensionW, height: dimensionH)
                    
                    PHImageManager.default().requestImage(for: self.albumView.phAsset, targetSize: targetSize,
                                                          contentMode: .aspectFill, options: options) {
                                                            result, info in
                                                            
                                                            DispatchQueue.main.async(execute: {
                                                                if let image = result {
                                                                    self.delegate?.fusumaImageSelected(image, source: self.mode)
                                                                    
                                                                    self.dismiss(animated: true, completion: {
                                                                        self.delegate?.fusumaDismissedWithImage(image, source: self.mode)
                                                                    })
                                                                } else {
                                                                    self.delegate?.fusumaFailed("We got problem with selected image. Please, make sure that all gallery permissions are allowed in the device settings.")
                                                                }
                                                            })
                    }
                })
            } else {
                print("no image crop ")
                delegate?.fusumaImageSelected((view?.image)!, source: mode)
                
                self.dismiss(animated: true, completion: {
                    self.delegate?.fusumaDismissedWithImage((view?.image)!, source: self.mode)
                })
            }
        }
    }
}

extension FusumaViewController: FSAlbumViewDelegate, FSCameraViewDelegate, FSVideoCameraViewDelegate {
    
    public func getCropHeightRatio() -> CGFloat {
        return cropHeightRatio
    }
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(_ image: UIImage) {
        
        delegate?.fusumaImageSelected(image, source: mode)
        self.dismiss(animated: true, completion: {
            
            self.delegate?.fusumaDismissedWithImage(image, source: self.mode)
        })
    }
    
    func cameraFailed(_ withErrorMessage: String) {
        self.delegate?.fusumaFailed(withErrorMessage)
    }
    
    public func albumViewCameraRollAuthorized() {
        // in the case that we're just coming back from granting photo gallery permissions
        // ensure the done button is visible if it should be
        self.updateDoneButtonVisibility()
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        delegate?.fusumaCameraRollUnauthorized()
    }
    
    func videoFinished(withFileURL fileURL: URL) {
        delegate?.fusumaVideoCompleted(withFileURL: fileURL)
        self.dismiss(animated: true, completion: nil)
    }
    
}

private extension FusumaViewController {
    
    func stopAll() {
        
        if self.allowedModes.contains(.video) {
            self.videoView.stopCamera()
        }
        
        if self.allowedModes.contains(.camera) {
            self.cameraView.stopCamera()
        }
    }
    
    func changeMode(_ mode: FusumaMode, forceUpdate: Bool = false) {
        
        if (!forceUpdate) {
            if self.mode == mode  {
                return
            }
            
            //operate this switch before changing mode to stop cameras
            switch self.mode {
            case .library:
                break
            case .camera:
                self.cameraView.stopCamera()
            case .video:
                self.videoView.stopCamera()
            }
        }
        
        self.mode = mode
        
        dishighlightButtons()
        updateDoneButtonVisibility()
        
        switch mode {
        case .library:
            titleLabel.text = NSLocalizedString(fusumaCameraRollTitle, comment: fusumaCameraRollTitle)
            
            highlightButton(libraryButton)
            self.view.bringSubview(toFront: photoLibraryViewerContainer)
        case .camera:
            titleLabel.text = NSLocalizedString(fusumaCameraTitle, comment: fusumaCameraTitle)
            
            highlightButton(cameraButton)
            self.view.bringSubview(toFront: cameraShotContainer)
            cameraView.startCamera()
        case .video:
            self.cameraView.stopCamera()
            titleLabel.text = fusumaVideoTitle
            
            highlightButton(videoButton)
            self.view.bringSubview(toFront: videoShotContainer)
            videoView.startCamera()
        }
        doneButton.isHidden = !hasGalleryPermission
        updateDoneButtonVisibility()
        self.view.bringSubview(toFront: menuView)
    }
    
    
    func updateDoneButtonVisibility() {
        // don't show the done button without gallery permission
        if !hasGalleryPermission {
            self.doneButton.isHidden = true
            return
        }
        
        switch self.mode {
        case .library:
            self.doneButton.isHidden = false
        default:
            self.doneButton.isHidden = true
        }
    }
    
    func dishighlightButtons() {
        
        cameraButton.isSelected  = false
        libraryButton.isSelected = false
        videoButton?.isSelected = false

    }
    
    func highlightButton(_ button: UIButton) {
        
        button.tintColor = fusumaTintColor
        
        button.isSelected = true
    }
}
