source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '14.0'
inhibit_all_warnings!
use_frameworks!

target 'Gumroad' do
  pod 'AFNetworking'
  pod 'SSDataKit'
  pod 'ISO8601'
  pod 'PSPDFKit', '~> 12.3' #podspec: 'https://customers.pspdfkit.com/pspdfkit-ios/latest.podspec'
  pod 'NXOAuth2Client'
  pod 'KVOController'
  pod 'KFEpubKit', :git => 'https://github.com/gumroad/KFEpubKit.git'
  pod 'Reachability'
  pod 'FBSDKCoreKit', '~> 16.1'
  pod 'FBSDKLoginKit', '~> 16.1'
  pod 'FBSDKShareKit', '~> 16.1'
  pod 'Fabric'
  pod 'TwitterKit'
  pod 'GoogleSignIn'
  pod 'SSZipArchive'
  pod 'Reveal-iOS-SDK', :configurations => ['Debug']
  pod 'Bugsnag'
  pod 'Cache', '~> 5.3'
  pod 'NYSegmentedControl'
  pod 'FirebaseAnalytics'
end

target 'WidgetExtension' do
  pod 'AFNetworking'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
      xcconfig_path = config.base_configuration_reference.real_path
      xcconfig = File.read(xcconfig_path)
      xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
      File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
    end
  end

  # Strip bitcode from all frameworks
  Dir.glob("Pods/**/*.framework").each do |framework|
    framework_binary = "#{framework}/#{File.basename(framework, '.framework')}"
    if File.exist?(framework_binary)
      puts "Stripping bitcode from #{framework_binary}"
      system("xcrun bitcode_strip #{framework_binary} -r -o #{framework_binary}")
    end
  end
end
