cmake_minimum_required(VERSION 3.22.1)

project("typgraphyeditor")

# Define the location of the FFmpeg headers
include_directories(include)
include_directories(whisper-src/include)
include_directories(whisper-src/src)
include_directories(whisper-src/ggml/include)
include_directories(whisper-src/ggml/src) 
include_directories(whisper-src/ggml/src/ggml-cpu)

# Add some flags for GGML
add_definitions(-DGGML_USE_CPU)

# ARM NEON optimizations for Android
if(ANDROID_ABI STREQUAL "arm64-v8a")
    add_definitions(-DGGML_USE_NEON)
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    add_definitions(-DGGML_USE_NEON)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mfpu=neon")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mfpu=neon")
endif()

# Define the location of the shared libraries
set(FFMPEG_LIBS_DIR ${CMAKE_SOURCE_DIR}/../jniLibs/${ANDROID_ABI})

# Add the FFmpeg libraries as imported shared libraries
add_library(avcodec SHARED IMPORTED)
set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libavcodec.so)

add_library(avformat SHARED IMPORTED)
set_target_properties(avformat PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libavformat.so)

add_library(avutil SHARED IMPORTED)
set_target_properties(avutil PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libavutil.so)

add_library(swresample SHARED IMPORTED)
set_target_properties(swresample PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libswresample.so)

add_library(swscale SHARED IMPORTED)
set_target_properties(swscale PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libswscale.so)

# Add our native library
add_library(native-lib SHARED 
    native-lib.cpp 
    audio_engine.cpp
    whisper-lib.cpp
    whisper-src/src/whisper.cpp
    whisper-src/ggml/src/ggml.c
    whisper-src/ggml/src/ggml-alloc.c
    whisper-src/ggml/src/ggml-backend.cpp
    whisper-src/ggml/src/ggml-quants.c
    whisper-src/ggml/src/ggml-threading.cpp
    whisper-src/ggml/src/ggml-backend-reg.cpp
    whisper-src/ggml/src/ggml-cpu/ggml-cpu.c
    whisper-src/ggml/src/ggml-cpu/ggml-cpu.cpp
    whisper-src/ggml/src/ggml-cpu/ggml-cpu-quants.c
    whisper-src/ggml/src/ggml-cpu/cpu-feats-x86.cpp
    whisper-src/ggml/src/ggml-cpu/ggml-cpu-aarch64.cpp
    whisper-src/ggml/src/ggml-cpu/ggml-cpu-traits.cpp
)

add_library(avfilter SHARED IMPORTED)
set_target_properties(avfilter PROPERTIES IMPORTED_LOCATION ${FFMPEG_LIBS_DIR}/libavfilter.so)

# Find Android logging library
find_library(log-lib log)

# Link our native library with FFmpeg and Android logs
target_link_libraries(
    native-lib
    avformat
    avcodec
    avfilter
    avutil
    swresample
    swscale
    swscale
    jnigraphics
    GLESv2
    OpenSLES
    ${log-lib}
)

# Support 16 KB memory page sizes
target_link_options(
    native-lib
    PRIVATE
    "-Wl,-z,max-page-size=16384"
)
