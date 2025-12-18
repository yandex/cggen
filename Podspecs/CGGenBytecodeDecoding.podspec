Pod::Spec.new do |s|
  s.name             = 'CGGenBytecodeDecoding'
  s.version          = '1.1.2'
  s.summary          = 'Bytecode decoding for cggen vector graphics'
  s.description      = <<-DESC
    Bytecode decompression and visitor pattern implementation for cggen.
    This is an internal dependency of CGGenRTSupport.
  DESC

  s.homepage         = 'https://github.com/yandex/cggen'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = 'Yandex LLC'
  s.source           = { :git => 'https://github.com/yandex/cggen.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '14.0'

  s.swift_versions = ['5.9', '6.0']

  s.source_files = 'Sources/CGGenBytecodeDecoding/**/*.swift'

  s.frameworks = 'Foundation'
  s.libraries = 'compression'

  s.dependency 'CGGenBytecode', s.version.to_s
end
