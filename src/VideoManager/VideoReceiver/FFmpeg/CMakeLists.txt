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

# Use the runtime from the same SDK as the import libraries for both layouts.
file(GLOB FFMPEG_RUNTIME_DLLS CONFIGURE_DEPENDS
    "${FFmpeg_ROOT}/bin/*.dll"
)
if(NOT FFMPEG_RUNTIME_DLLS)
    message(FATAL_ERROR "No FFmpeg runtime DLLs found in ${FFmpeg_ROOT}/bin")
endif()

install(FILES ${FFMPEG_RUNTIME_DLLS} DESTINATION "${CMAKE_INSTALL_BINDIR}")

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
