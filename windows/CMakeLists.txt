# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "llama_cpp_dart")
project(${PROJECT_NAME} LANGUAGES CXX)

set(llama_cpp_dart_bundled_libraries
    "${CMAKE_CURRENT_SOURCE_DIR}/ggml-base.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/ggml-cpu.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/ggml-cuda.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/ggml.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/llama.dll"
    "${CMAKE_CURRENT_SOURCE_DIR}/mtmd.dll"
    PARENT_SCOPE
)