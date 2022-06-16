# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

target ‘ShoutaroundTest’ do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for InstagramFirebase

pod 'Firebase/Auth’
pod 'Firebase/Database’
pod 'Firebase/Storage’
pod ‘Firebase/Messaging’
pod ‘FirebaseAnalytics’
pod 'Firebase'
pod 'GooglePlaces'
pod 'GoogleMaps'
pod 'SwiftyJSON', '~> 4.0'
pod 'GeoFire', :git => 'https://github.com/firebase/geofire-objc.git'
pod 'Alamofire', '~> 5.0.0.beta.1'
pod 'mailgun', '~> 1.0.3'
pod 'GoogleAPIClientForREST/Gmail', '~> 1.2.1'
pod 'GoogleSignIn'
pod 'Cosmos', '~> 18.0'
pod 'IQKeyboardManagerSwift'
pod 'UIFontComplete'
pod 'EmptyDataSet-Swift', '~> 5.0.0'
pod "BSImagePicker"
pod 'SKPhotoBrowser', :git => 'https://github.com/suzuki-0000/SKPhotoBrowser.git', :branch => 'master'
pod 'DropDown', '2.3.4'
pod 'CLImageEditor/AllTools'
pod 'CropViewController'
pod 'TLPhotoPicker'
pod 'FacebookCore'
pod 'FacebookLogin'
pod 'SVProgressHUD', :git => 'https://github.com/SVProgressHUD/SVProgressHUD.git'
pod 'Smile'
pod 'Kingfisher', '~> 5.0'
pod 'RevenueCat'
end

post_install do |installer|
   installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64 i386"
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
   end
   end
 end