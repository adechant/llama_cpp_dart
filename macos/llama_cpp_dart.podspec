Pod::Spec.new do |s|
    s.name             = 'llama_cpp_dart'
    s.version          = '0.0.1'
    s.summary          = 'Flutter plugin for llama.cpp'
    s.description      = <<-DESC
  A Flutter plugin wrapper for llama.cpp to run LLM models locally.
                         DESC
    s.homepage         = 'https://github.com/netdur/llama_cpp_dart'
    s.license          = { :type => 'MIT', :file => '../LICENSE' }
    s.author           = { 'Your Name' => 'your-email@example.com' }
    s.source           = { :path => '.' }
    s.dependency 'FlutterMacOS'
    s.vendored_libraries = '*.dylib'
    s.platform = :osx, '10.15'
    s.static_framework = true
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    s.swift_version = '5.0'
  end