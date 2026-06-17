Unicode true
CRCCheck On
SetCompressor /solid lzma

!include "MUI.nsh"
!include "FileFunc.nsh"

!define APPNAME "TV Rename"

Name "${APPNAME}"
Caption "${APPNAME} ${VERSION} Setup"
BrandingText " "

InstallDir "$PROGRAMFILES\TVRename"

OutFile "TVRename-${TAG}.exe"

!define MUI_ICON "TVRename\App\app.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\win-uninstall.ico"

Var STARTMENU_FOLDER
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\TVRename"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"

!define MUI_ABORTWARNING

!define MUI_FINISHPAGE_RUN "$INSTDIR\TVRename.exe"
!define MUI_FINISHPAGE_LINK "Visit the TV Rename site for the latest news and support"
!define MUI_FINISHPAGE_LINK_LOCATION "http://www.tvrename.com/"

!define MUI_TEXT_LICENSE_TITLE "End-User License Agreement"
!define MUI_TEXT_LICENSE_SUBTITLE "Please read the following license agreement carefully"
!define MUI_LICENSEPAGE_TEXT_TOP "Please read the following license agreement carefully"
!define MUI_LICENSEPAGE_BUTTON Accept
!define MUI_LICENSEPAGE_CHECKBOX

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "Licence.rtf"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Check for .NET 8 Desktop Runtime
!macro CheckDotNet8
    ReadRegStr $0 HKLM "SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App" "8.0"
    StrCmp $0 "" 0 dotnet8_found
    ; Try enumerating installed 8.x versions
    StrCpy $1 0
    dotnet8_loop:
        EnumRegValue $2 HKLM "SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedfx\Microsoft.WindowsDesktop.App" $1
        StrCmp $2 "" dotnet8_missing
        StrCpy $3 $2 1   ; first char of version string
        StrCmp $3 "8" dotnet8_found
        IntOp $1 $1 + 1
        Goto dotnet8_loop
    dotnet8_missing:
        MessageBox MB_YESNO|MB_ICONEXCLAMATION \
            "TV Rename requires .NET 8 Desktop Runtime which does not appear to be installed.$\n$\nDownload it from https://dotnet.microsoft.com/download/dotnet/8.0$\n$\nContinue installation anyway?" \
            IDYES dotnet8_found
        Abort
    dotnet8_found:
!macroend

Section "Install"
    SetOutPath "$INSTDIR"

    !insertmacro CheckDotNet8

    Delete "$INSTDIR\Ionic.Utils.Zip.dll" ; Remove old dependency

    ; Main application files
    File "TVRename\bin\x64\Release\net8.0-windows\TVRename.exe"
    File "TVRename\bin\x64\Release\net8.0-windows\TVRename.dll"
    File "TVRename\bin\x64\Release\net8.0-windows\TVRename.runtimeconfig.json"
    File "TVRename\bin\x64\Release\net8.0-windows\TVRename.deps.json"
    File "TVRename\bin\x64\Release\net8.0-windows\TVRename.dll.config"
    File "TVRename\bin\x64\Release\net8.0-windows\NLog.config"
    File "TVRename\bin\x64\Release\net8.0-windows\*.dll"
    File "TVRename\bin\x64\Release\net8.0-windows\*.json"

    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Managed CefSharp DLLs (x64)
    SetOutPath "$INSTDIR\x64"
    File "TVRename\bin\x64\Release\net8.0-windows\x64\*.dll"

    ; CEF native binaries
    SetOutPath "$INSTDIR\runtimes\win-x64\native"
    File "TVRename\bin\x64\Release\net8.0-windows\runtimes\win-x64\native\*.dll"
    File "TVRename\bin\x64\Release\net8.0-windows\runtimes\win-x64\native\*.exe"
    File "TVRename\bin\x64\Release\net8.0-windows\runtimes\win-x64\native\*.json"
    File "TVRename\bin\x64\Release\net8.0-windows\runtimes\win-x64\native\*.dat"
    File "TVRename\bin\x64\Release\net8.0-windows\runtimes\win-x64\native\*.pak"
    File "TVRename\bin\x64\Release\net8.0-windows\runtimes\win-x64\native\*.bin"

    SetOutPath "$INSTDIR\runtimes\win-x64\native\locales"
    File "TVRename\bin\x64\Release\net8.0-windows\runtimes\win-x64\native\locales\*.pak"

    SetOutPath "$INSTDIR"

    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\${APPNAME}.lnk" "$INSTDIR\TVRename.exe"
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\${APPNAME} (Recover).lnk" "$INSTDIR\TVRename.exe" /recover
    CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
    !insertmacro MUI_STARTMENU_WRITE_END

    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "DisplayIcon" "$INSTDIR\TVRename.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "Publisher" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "NoRepair" 1

    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename" "EstimatedSize" "$0"

SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\TVRename.exe"
    Delete "$INSTDIR\TVRename.dll"
    Delete "$INSTDIR\*.dll"
    Delete "$INSTDIR\*.json"

    Delete "$INSTDIR\NLog.config"
    Delete "$INSTDIR\TVRename.dll.config"
    Delete "$INSTDIR\debug.log"

    Delete "$INSTDIR\Uninstall.exe"

    RmDir /r "$INSTDIR\x64"
    RmDir /r "$INSTDIR\runtimes"

    RmDir "$INSTDIR"

    !insertmacro MUI_STARTMENU_GETFOLDER Application $STARTMENU_FOLDER
    Delete "$SMPROGRAMS\$STARTMENU_FOLDER\${APPNAME}.lnk"
    Delete "$SMPROGRAMS\$STARTMENU_FOLDER\${APPNAME} (Recover).lnk"
    Delete "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk"
    RmDir "$SMPROGRAMS\$STARTMENU_FOLDER"

    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\TVRename"

    MessageBox MB_YESNO|MB_ICONEXCLAMATION "Do you wish to remove your ${APPNAME} settings as well?" IDNO done
    ReadRegStr $R0 HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" "AppData"
    RmDir /r "$R0\TVRename"

done:

SectionEnd
