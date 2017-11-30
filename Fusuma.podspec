Pod::Spec.new do |s|
  s.name             = "Fusuma"
  s.version          = "2.0.4"
  s.summary          = "Instagram-like photo browser with a few line of code written in Swift"
  s.homepage         = "https://github.com/shu-ua/Fusuma"
  s.license          = 'MIT'
  s.author           = { "ytakzk" => "shyss.ak@gmail.com", "shu-ua" => "bohdan.shcherbyna@gmail.com"}
  s.source           = { :git => "https://github.com/shu-ua/Fusuma.git", :tag => s.version.to_s }
  s.platform     = :ios, '10.0'
  s.requires_arc = true
  s.source_files = 'Sources/**/*.swift'
  s.resources    = ['Sources/Assets.xcassets', 'Sources/**/*.xib']
  s.dependency "NextLevel", "~> 0.8.4"
end

