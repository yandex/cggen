# CocoaPods Support

CocoaPods support is provided **only for the runtime library** (`CGGenRTSupport`).

The cggen CLI tool is not available via CocoaPods. Use Swift Package Manager for the CLI.

## Usage

Add to your Podfile:

```ruby
platform :ios, '13.0'

CGGEN = 'https://raw.githubusercontent.com/yandex/cggen/main/Podspecs'

target 'MyApp' do
  use_frameworks!

  pod 'CGGenBytecode', :podspec => "#{CGGEN}/CGGenBytecode.podspec"
  pod 'CGGenBytecodeDecoding', :podspec => "#{CGGEN}/CGGenBytecodeDecoding.podspec"
  pod 'CGGenRTSupport', :podspec => "#{CGGEN}/CGGenRTSupport.podspec"
end
```

For multiple targets, use a function:

```ruby
CGGEN = 'https://raw.githubusercontent.com/yandex/cggen/main/Podspecs'

def cggen_runtime
  pod 'CGGenBytecode', :podspec => "#{CGGEN}/CGGenBytecode.podspec"
  pod 'CGGenBytecodeDecoding', :podspec => "#{CGGEN}/CGGenBytecodeDecoding.podspec"
  pod 'CGGenRTSupport', :podspec => "#{CGGEN}/CGGenRTSupport.podspec"
end

target 'MyApp' do
  use_frameworks!
  cggen_runtime
end

target 'MyAppTests' do
  use_frameworks!
  cggen_runtime
end
```

Then run:

```bash
pod install
```

## Note

CocoaPods trunk is scheduled to become read-only in December 2026. Consider migrating to Swift Package Manager.
