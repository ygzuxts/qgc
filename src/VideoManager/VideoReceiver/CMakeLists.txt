target_sources(${CMAKE_PROJECT_NAME} PRIVATE VideoReceiver.h)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

add_subdirectory(GStreamer)
add_subdirectory(QtMultimedia)
if(QGC_ENABLE_FFMPEG_VIDEOSTREAMING)
    if(NOT WIN32)
        message(FATAL_ERROR "The custom FFmpeg video backend requires Windows FFmpeg libraries. Disable QGC_ENABLE_FFMPEG_VIDEOSTREAMING for this target.")
    endif()
    add_subdirectory(FFmpeg)
endif()
