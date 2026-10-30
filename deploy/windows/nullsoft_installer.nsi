!include "MUI2.nsh"
!include LogicLib.nsh
!include Win\COM.nsh
!include Win\Propkey.nsh
!include "FileFunc.nsh"

!macro DemoteShortCut target
    !insertmacro ComHlpr_CreateInProcInstance ${CLSID_ShellLink} ${IID_IShellLink} r0 ""
    ${If} $0 <> 0
            ${IUnknown::QueryInterface} $0 '("${IID_IPersistFile}",.r1)'
            ${If} $1 P<> 0
                    ${IPersistFile::Load} $1 '("${target}",1)'
                    ${IUnknown::Release} $1 ""
            ${EndIf}
            ${IUnknown::QueryInterface} $0 '("${IID_IPropertyStore}",.r1)'
            ${If} $1 P<> 0
                    System::Call '*${SYSSTRUCT_PROPERTYKEY}(${PKEY_AppUserModel_StartPinOption})p.r2'
                    System::Call '*${SYSSTRUCT_PROPVARIANT}(${VT_UI4},,&i4 ${APPUSERMODEL_STARTPINOPTION_NOPINONINSTALL})p.r3'
                    ${IPropertyStore::SetValue} $1 '($2,$3)'

                    ; Reuse the PROPERTYKEY & PROPVARIANT buffers to set another property
                    System::Call '*$2${SYSSTRUCT_PROPERTYKEY}(${PKEY_AppUserModel_ExcludeFromShowInNewInstall})'
                    System::Call '*$3${SYSSTRUCT_PROPVARIANT}(${VT_BOOL},,&i2 ${VARIANT_TRUE})'
                    ${IPropertyStore::SetValue} $1 '($2,$3)'

                    System::Free $2
                    System::Free $3
                    ${IPropertyStore::Commit} $1 ""
                    ${IUnknown::Release} $1 ""
            ${EndIf}
            ${IUnknown::QueryInterface} $0 '("${IID_IPersistFile}",.r1)'
            ${If} $1 P<> 0
                    ${IPersistFile::Save} $1 '("${target}",1)'
                    ${IUnknown::Release} $1 ""
            ${EndIf}
            ${IUnknown::Release} $0 ""
    ${EndIf}
!macroend

!macro TryUninstallPreviousVersion uninstallKey displayName regView
  SetRegView ${regView}
  ClearErrors
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${uninstallKey}" "UninstallString"
  ${If} $R0 != ""
    DetailPrint "Uninstalling previous ${displayName} version..."
    ExecWait '$R0 /S -LEAVE_DATA=1' $0
    ${If} $0 != 0
      MessageBox MB_OK|MB_ICONEXCLAMATION \
            "Could not remove a previously installed ${displayName} version.$\n$\nPlease remove it before continuing."
      Abort
    ${EndIf}
  ${EndIf}
!macroend

!macro TryUninstallPreviousVersions uninstallKey displayName
  !insertmacro TryUninstallPreviousVersion "${uninstallKey}" "${displayName}" 32
  !insertmacro TryUninstallPreviousVersion "${uninstallKey}" "${displayName}" 64
!macroend

Name "${APPNAME}"
RequestExecutionLevel admin
Var StartMenuFolder

InstallDir "$PROGRAMFILES64\${APPNAME}"

SetCompressor /SOLID /FINAL lzma

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${HEADER_BITMAP}";
!define MUI_ICON "${INSTALLER_ICON}";
!define MUI_UNICON "${INSTALLER_ICON}";

!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Install prerequisites before removing the previous application.
Section "Visual C++ Runtime"
  InitPluginsDir
  SetOutPath "$PLUGINSDIR"
  File "${DESTDIR}\bin\vc_redist.x64.exe"
  ClearErrors
  ExecWait '"$PLUGINSDIR\vc_redist.x64.exe" /install /quiet /norestart' $0
  ${If} ${Errors}
    SetErrorLevel 1
    Abort "Could not launch the Visual C++ runtime installer."
  ${EndIf}
  ${If} $0 == 3010
    SetRebootFlag true
  ${ElseIf} $0 != 0
  ${AndIf} $0 != 1638
  ${AndIf} $0 != -2147023258 ; HRESULT_FROM_WIN32(ERROR_PRODUCT_VERSION)
    SetErrorLevel 1
    Abort "Visual C++ runtime installation failed (exit code $0)."
  ${EndIf}
SectionEnd

Section
  !insertmacro TryUninstallPreviousVersions "${APPNAME}" "${APPNAME}"
  !if "${APPNAME}" == "FutureWings"
    !insertmacro TryUninstallPreviousVersions "FutureWing" "FutureWing"
  !endif

  SetRegView 64
  SetOutPath $INSTDIR
  File /r /x *.pdb /x *.lib /x *.exp "${DESTDIR}\*.*"

  ; Driver location is http://firmware.ardupilot.org/Tools/MissionPlanner/driver.msi
  ; Whenever this driver is updated in the repo QGCCURRENTDRIVERVERSION must be bumped by 1
  File "${DRIVER_MSI}"

  WriteUninstaller $INSTDIR\${EXENAME}-Uninstall.exe
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
  WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\${EXENAME}-Uninstall.exe$\""
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe" "DumpCount" 5
  WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe" "DumpType" 1
  WriteRegExpandStr HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe" "DumpFolder" "%LOCALAPPDATA%\QGCCrashDumps"

  ; QGC stores its own driver version key to prevent installation if already up to date
  ; This prevents running the driver install a second time which will start up in repair mode which is confusing
  !define QGCDRIVERVERSIONKEY "SOFTWARE\QGroundControlUAVDrivers"
  !define QGCCURRENTDRIVERVERSION 3

  ; If the drivers are already installed the key "HKCU/SOFTWARE\MichaelOborne\driver\installed" will be present and set to 1
  SetRegView 64
  !define DRIVERKEY "SOFTWARE\MichaelOborne\driver"
  ReadRegDWORD $0 HKCU "${DRIVERKEY}" "installed"
  IntCmp $0 1 driversInstalled driversNotInstalled driversNotInstalled

driversInstalled:
  DetailPrint "UAV Drivers already installed. Checking version..."
  ; Check if the installed drivers are out of date.
  ; Missing key also indicates out of date driver install.
  ReadRegDWORD $0 HKCU "${QGCDRIVERVERSIONKEY}" "version"
  IntCmp $0 ${QGCCURRENTDRIVERVERSION} done driversOutOfDate done

driversOutOfDate:
  DetailPrint "UAV Drivers out of date."
  goto installDrivers

driversNotInstalled:
  DetailPrint "UAV Drivers not installed."
  ; Delete abandoned possibly out of date version key
  DeleteRegKey HKCU "SOFTWARE\QGroundControlUAVDrivers"

installDrivers:
  DetailPrint "Installing UAV Drivers..."
  ClearErrors
  ExecWait '"$SYSDIR\msiexec.exe" /i "$INSTDIR\driver.msi" /qn /norestart /L*v "$TEMP\${EXENAME}-driver-install.log"' $0
  ${If} ${Errors}
    SetErrorLevel 1
    Abort "Could not launch the UAV driver installer."
  ${EndIf}
  ${If} $0 == 3010
    SetRebootFlag true
  ${ElseIf} $0 != 0
    SetErrorLevel 1
    Abort "UAV driver installation failed (exit code $0). See $TEMP\${EXENAME}-driver-install.log."
  ${EndIf}
  ; Set current driver version value
  WriteRegDWORD HKCU "${QGCDRIVERVERSIONKEY}" "version" ${QGCCURRENTDRIVERVERSION}
  goto done

done:
  SetRegView lastused
SectionEnd

Section "Uninstall"
  SetRegView 64
  ${GetParameters} $R0
  ${GetOptions} $R0 "-LEAVE_DATA=" $R1
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  SetShellVarContext all
  RMDir /r /REBOOTOK $INSTDIR
  RMDir /r /REBOOTOK "$SMPROGRAMS\$StartMenuFolder\"
  SetShellVarContext current
  ${If} $R1 != 1
    RMDir /r /REBOOTOK "$APPDATA\${ORGNAME}\"
  ${Endif}
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\${EXENAME}.exe"
  ; NOTE: We specifically do not delete the driver version key since we need it to persist around uninstalls
SectionEnd

Section "create Start Menu Shortcuts"
  SetRegView 64
  SetShellVarContext all
  CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME}.lnk" "$INSTDIR\bin\${EXENAME}.exe" "" "$INSTDIR\bin\${EXENAME}.exe" 0
  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME} (GPU Compatibility Mode).lnk" "$INSTDIR\bin\${EXENAME}.exe" "-desktop" "$INSTDIR\bin\${EXENAME}.exe" 0
  !insertmacro DemoteShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME} (GPU Compatibility Mode).lnk"
  CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME} (GPU Safe Mode).lnk" "$INSTDIR\bin\${EXENAME}.exe" "-swrast" "$INSTDIR\bin\${EXENAME}.exe" 0
  !insertmacro DemoteShortCut "$SMPROGRAMS\$StartMenuFolder\${APPNAME} (GPU Safe Mode).lnk"
SectionEnd

