Pod::Spec.new do |s|
    s.name             = 'llama_cpp_dart'
    s.version          = '0.0.1'
    s.summary          = 'Flutter plugin for llama.cpp'
    s.description      = <<-DESC
  A Flutter plugin wrapper for llama.cpp to run LLM models locally.
                         DESC
    s.homepage         = 'https://github.com/adechant/llama_cpp_dart'
    s.license          = { :type => 'MIT', :file => '../LICENSE' }
    s.author           = { 'Your Name' => 'your-email@example.com' }
    s.source           = { :path => '.' }
    s.dependency 'FlutterMacOS'
    s.platform = :osx, '13.3'
    s.static_framework = true
    s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    s.swift_version = '5.0'
    s.script_phase = 
      {
      :name => 'Precompile Build Llama.cpp',
      :execution_position => :before_compile,
      :script => 'echo "Building Llama.cpp"; cd ${PODS_TARGET_SRCROOT}/../src/llama.cpp; cmake -B build -DGGML_METAL=ON; cmake --build build --config Release -j 8; cp ./build/bin/*.dylib ../../macos/; echo "Building Llama.cpp Complete"'
      }
    s.vendored_libraries = '*.dylib'
  end