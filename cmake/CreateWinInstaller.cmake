message(STATUS "Creating Windows NSIS Installer")

if(NOT CMAKE_INSTALL_CONFIG_NAME STREQUAL "Release")
    message(FATAL_ERROR "Windows delivery installers must use the Release configuration")
endif()
if(DEFINED ENV{QGC_VC_REDIST})
    file(COPY_FILE "$ENV{QGC_VC_REDIST}" "${CMAKE_INSTALL_PREFIX}/bin/vc_redist.x64.exe")
endif()
foreach(required_file IN ITEMS
    "${CMAKE_INSTALL_PREFIX}/bin/${CMAKE_PROJECT_NAME}.exe"
    "${CMAKE_INSTALL_PREFIX}/bin/vc_redist.x64.exe"
    "${CMAKE_INSTALL_PREFIX}/plugins/platforms/qwindows.dll"
    "${CMAKE_INSTALL_PREFIX}/bin/qt.conf")
    if(NOT EXISTS "${required_file}")
        message(FATAL_ERROR "Missing installer dependency: ${required_file}")
    endif()
endforeach()

file(TO_NATIVE_PATH "${QGC_WINDOWS_INSTALLER_SCRIPT}" QGC_NSIS_INSTALLER_SCRIPT)
set(_PF86 "PROGRAMFILES(x86)")
# Qt Quick 3D uses the DirectX shader compiler. windeployqt can miss it outside
# a developer shell, so resolve the x64 redistributable explicitly.
foreach(shader_dll IN ITEMS dxcompiler.dll dxil.dll)
    if(NOT EXISTS "${CMAKE_INSTALL_PREFIX}/bin/${shader_dll}")
        unset(QGC_SHADER_DLL CACHE)
        find_file(QGC_SHADER_DLL NAMES "${shader_dll}"
            PATHS "$ENV{WindowsSdkDir}/Redist/D3D/x64"
                  "$ENV{${_PF86}}/Windows Kits/10/Redist/D3D/x64"
            NO_DEFAULT_PATH
            REQUIRED
        )
        file(COPY_FILE "${QGC_SHADER_DLL}" "${CMAKE_INSTALL_PREFIX}/bin/${shader_dll}")
    endif()
endforeach()
find_program(QGC_NSIS_INSTALLER_CMD makensis
    PATHS "$ENV{PROGRAMFILES}/NSIS" "$ENV{${_PF86}}/NSIS" "$ENV{PROGRAMW6432}/NSIS"
    DOC "Path to the makensis utility."
    REQUIRED
)

file(TO_NATIVE_PATH "${QGC_WINDOWS_ICON_PATH}" QGC_INSTALLER_ICON)
file(TO_NATIVE_PATH "${QGC_WINDOWS_INSTALL_HEADER_PATH}" QGC_INSTALLER_HEADER_BITMAP)
file(TO_NATIVE_PATH "${QGC_WINDOWS_DRIVER_MSI}" QGC_INSTALLER_DRIVER_MSI)
set(QGC_INSTALLER_TEMP_OUT "${QGC_WINDOWS_OUT}.partial")
file(TO_NATIVE_PATH "${QGC_INSTALLER_TEMP_OUT}" QGC_INSTALLER_OUT)

set(QGC_NSIS_INSTALLER_PARAMETERS
    /DDRIVER_MSI=${QGC_INSTALLER_DRIVER_MSI}
    /DINSTALLER_ICON=${QGC_INSTALLER_ICON}
    /DHEADER_BITMAP=${QGC_INSTALLER_HEADER_BITMAP}
    /DAPPNAME=${CMAKE_PROJECT_NAME}
    /DEXENAME=${CMAKE_PROJECT_NAME}
    /DORGNAME=${QGC_ORG_NAME}
    /DDESTDIR=${CMAKE_INSTALL_PREFIX}
    /NOCD
    "/XOutFile \"${QGC_INSTALLER_OUT}\""
    ${QGC_NSIS_INSTALLER_SCRIPT}
)

execute_process(
    COMMAND ${QGC_NSIS_INSTALLER_CMD} ${QGC_NSIS_INSTALLER_PARAMETERS}
    COMMAND_ECHO STDOUT
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
    ECHO_OUTPUT_VARIABLE
    ECHO_ERROR_VARIABLE
    RESULT_VARIABLE QGC_NSIS_RESULT
)
if(NOT QGC_NSIS_RESULT STREQUAL "0")
    file(REMOVE "${QGC_INSTALLER_TEMP_OUT}")
    message(FATAL_ERROR "NSIS failed (${QGC_NSIS_RESULT}); no new installer was published")
endif()
file(RENAME "${QGC_INSTALLER_TEMP_OUT}" "${QGC_WINDOWS_OUT}")
