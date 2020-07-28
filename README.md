# share_store
Share the store you want to go


AppDelegate.swiftは以下を期待しています。API_KEYを環境変数から読めるようにしたら消します

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    GMSServices.provideAPIKey("YOUR_API_KEY")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```
