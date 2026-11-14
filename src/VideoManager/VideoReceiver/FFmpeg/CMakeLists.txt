set(FFmpeg_ROOT "C:/deps/ffmpeg" CACHE PATH
    "FFmpeg development package directory")

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        FFmpegReceiver.h
        FFmpegReceiver.cpp
        FFmpegWorker.h
        FFmpegWorker.cc
        FFmpegVideoItem.h
        FFmpegVideoItem.cc
)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        "${FFmpeg_ROOT}/include"
)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        "${FFmpeg_ROOT}/lib/avformat.lib"
        "${FFmpeg_ROOT}/lib/avcodec.lib"
        "${FFmpeg_ROOT}/lib/avutil.lib"
        "${FFmpeg_ROOT}/lib/swscale.lib"
)

# 将 FFmpeg DLL 复制到程序所在目录
file(GLOB FFMPEG_RUNTIME_DLLS
    "${FFmpeg_ROOT}/bin/*.dll"
)

add_custom_target(CopyFFmpegDLLs
    COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_FILE_DIR:${CMAKE_PROJECT_NAME}>"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${FFMPEG_RUNTIME_DLLS}
        "$<TARGET_FILE_DIR:${CMAKE_PROJECT_NAME}>"
    COMMENT "Copying FFmpeg runtime DLLs"
    VERBATIM
)

add_dependencies(${CMAKE_PROJECT_NAME} CopyFFmpegDLLs)

target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE QGC_FFMPEG_STREAMING)
