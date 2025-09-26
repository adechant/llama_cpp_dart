# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/lib")

set(llama_cpp_dart_bundled_libraries
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/llama.cpp/build/bin/Release/ggml-base.dll" 
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/llama.cpp/build/bin/Release/ggml-cpu.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/llama.cpp/build/bin/Release/ggml-cuda.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/llama.cpp/build/bin/Release/ggml.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/llama.cpp/build/bin/Release/llama.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/../src/llama.cpp/build/bin/Release/mtmd.dll"
    PARENT_SCOPE
)