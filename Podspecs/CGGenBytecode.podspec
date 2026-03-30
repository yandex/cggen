Pod::Spec.new do |s|
  s.name             = 'CGGenBytecode'
  s.version          = '1.1.4'
  s.summary          = 'Bytecode definitions for cggen vector graphics'
  s.description      = <<-DESC
    Low-level bytecode command definitions and data structures for cggen.
    This is an internal dependency of CGGenRTSupport.
  DESC

  s.homepage         = 'https://github.com/yandex/cggen'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = 'Yandex LLC'
  s.source           = { :git => 'https://github.com/yandex/cggen.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '14.0'

  s.swift_versions = ['5.9', '6.0']

  s.source_files = 'Sources/CGGenBytecode/**/*.swift'

  s.frameworks = 'Foundation', 'CoreGraphics'
end
