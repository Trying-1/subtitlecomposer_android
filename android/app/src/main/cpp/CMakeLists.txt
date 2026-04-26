cmake_minimum_required(VERSION 3.22.1)

project("typgraphyeditor")

# Define the location of the FFmpeg headers
include_directories(include)

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
add_library(native-lib SHARED native-lib.cpp)

# Find Android logging library
find_library(log-lib log)

# Link our native library with FFmpeg and Android logs
target_link_libraries(
    native-lib
    avformat
    avcodec
    avutil
    swresample
    swscale
    ${log-lib}
)
