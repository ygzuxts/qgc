message(STATUS "QGC: Adding branded custom build (${QGC_BRAND})")

set_property(DIRECTORY ${CMAKE_SOURCE_DIR}
    APPEND PROPERTY COMPILE_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="BrandedPlugin.h"
    CUSTOMCLASS=BrandedPlugin
)

set(QGC_BRAND_RESOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/res/brand/${QGC_BRAND}")
set(QGC_BRAND_APP_ICON "${QGC_BRAND_RESOURCE_DIR}/app-icon.ico")
set(QGC_BRAND_LOGO "${QGC_BRAND_RESOURCE_DIR}/logo.png")
set(QGC_BRAND_TRANSPARENT_LOGO "${QGC_BRAND_RESOURCE_DIR}/logo-transparent.png")

if(NOT EXISTS "${QGC_BRAND_LOGO}")
    message(FATAL_ERROR "Missing brand logo: ${QGC_BRAND_LOGO}")
endif()

if(NOT EXISTS "${QGC_BRAND_TRANSPARENT_LOGO}")
    message(FATAL_ERROR "Missing transparent brand logo: ${QGC_BRAND_TRANSPARENT_LOGO}")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/brand.qrc.in"
    "${CMAKE_CURRENT_BINARY_DIR}/brand.qrc"
    @ONLY
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/BrandedConfig.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/BrandedConfig.h"
    @ONLY
)

set(CUSTOM_RESOURCES
    "${CMAKE_CURRENT_BINARY_DIR}/brand.qrc"
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/src/BrandedPlugin.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/BrandedPlugin.h"
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_QT_COMPONENTS
    Core
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_LIBRARIES
    Qt6::Core
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_BINARY_DIR}"
    CACHE INTERNAL "" FORCE
)
