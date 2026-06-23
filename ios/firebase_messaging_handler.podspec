#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint firebase_messaging_handler.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'firebase_messaging_handler'
  s.version          = '1.0.6'
  s.summary          = 'Production-ready Flutter plugin for Firebase Cloud Messaging with inbox, in-app UX, badges, diagnostics, and scheduling.'
  s.description      = <<-DESC
Production-ready Flutter plugin for Firebase Cloud Messaging with a unified click stream, notification inbox, in-app messaging, diagnostics, badges, and scheduling.
                       DESC
  s.homepage         = 'https://github.com/qoder-official/firebase_messaging_handler'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Qoder' => 'neel@qoder.com' }
  s.source           = { :path => '.' }
  s.source_files = 'firebase_messaging_handler/Sources/firebase_messaging_handler/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
