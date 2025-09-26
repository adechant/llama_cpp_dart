cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "llama_cpp_dart")
project(${PROJECT_NAME} LANGUAGES CXX)


set(BUILD_SHARED_LIBS ON)

if(ANDROID)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DANDROID_ARM_NEON=TRUE -DANDROID_TOOLCHAIN=clang -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-23")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DANDROID_ARM_NEON=TRUE -DANDROID_TOOLCHAIN=clang -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-23")
    # Log the flags
    message(STATUS "CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
endif()


add_custom_target(
    ${PROJECT_NAME} ALL
    COMMAND cmake --build build --config Release -j 8
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp
    COMMENT "Building llama library"
)

add_custom_command(
    TARGET ${PROJECT_NAME}
    PRE_BUILD
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp
    COMMAND cmake -B build -DGGML_CUDA=ON -DLLAMA_CURL=OFF
    COMMENT "configuring llama library build"
)
