## Fusuma

Fusuma is a Swift library that provides an Instagram-like photo browser with a camera feature using only a few lines of code. 

## Installation

#### Using [CocoaPods](http://cocoapods.org/)

Add `pod 'Fusuma'` to your `Podfile` and run `pod install`. Also add `use_frameworks!` to the `Podfile`.

```
use_frameworks!
pod 'Fusuma', :git => 'https://github.com/shu-ua/Fusuma.git'
```

## Fusuma Usage
Import Fusuma ```import Fusuma``` then use the following codes in some function except for viewDidLoad and give FusumaDelegate to the view controller.  

```Swift
let fusuma = FusumaViewController()
fusuma.delegate = self
fusuma.hasVideo = true // If you want to let the users allow to use video.
self.presentViewController(fusuma, animated: true, completion: nil)
```

#### Delegate methods

```Swift
// Return the image which is selected from camera roll or is taken via the camera.
func fusumaImageSelected(image: UIImage) {

  print("Image selected")
}

// Return the image but called after is dismissed.
func fusumaDismissedWithImage(image: UIImage) {
        
  print("Called just after FusumaViewController is dismissed.")
}

func fusumaVideoCompleted(withFileURL fileURL: NSURL) {

  print("Called just after a video has been selected.")
}

// When camera roll is not authorized, this method is called.
func fusumaCameraRollUnauthorized() {

  print("Camera roll unauthorized")
}
```

#### Colors

```Swift
fusumaTintColor: UIColor // tint color

fusumaBackgroundColor: UIColor // background color
```

#### Customize Image Output 
You can deselect image crop mode with: 

```Swift
fusumaCropImage:Bool // default is true for cropping the image 
```

## Fusuma for Xamarin
Cheesebaron developed Chafu for Xamarin.  
https://github.com/Cheesebaron/Chafu

## Author
ytakzk  
 [http://ytakzk.me](http://ytakzk.me)
 
## Donation
Your support is welcome through Bitcoin 16485BTK9EoQUqkMmSecJ9xN6E9nhW8ePd
 
## License
Fusuma is released under the MIT license.  
See LICENSE for details.
