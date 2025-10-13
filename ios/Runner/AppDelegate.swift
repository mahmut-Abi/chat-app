import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 启用 iOS 玻璃效果和视觉优化
    if let window = self.window {
      // 设置窗口透明度，支持毛玻璃效果
      window.backgroundColor = UIColor.clear
      window.isOpaque = false
      
      // 启用深色模式支持
      if #available(iOS 13.0, *) {
        window.overrideUserInterfaceStyle = .unspecified
      }
    }
    
    // 启用性能优化
    if #available(iOS 15.0, *) {
      // 支持 ProMotion 显示器
      if let flutterViewController = window?.rootViewController as? FlutterViewController {
        flutterViewController.view.layer.shouldRasterize = false
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
