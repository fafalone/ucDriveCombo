VERSION 5.00
Begin VB.UserControl ucDriveCombo 
   ClientHeight    =   1050
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   1860
   ScaleHeight     =   70
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   124
   ToolboxBitmap   =   "ucDriveCombo.ctx":0000
End
Attribute VB_Name = "ucDriveCombo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'********************************************************************
' ucDriveCombo v1.4
' A Modern DriveList Replacement
' by Jon Johnson
'
' Provides a modernized option for a Drive Combo without the extra
' complexity of a full blown ucShellBrowse control.
'
' Requirements: VB6 or twinBASIC Beta 515
'    Note: This file combines the mUCDCHelper module; in VB6 that
'          must be in its own .bas.
'
' Features:
'   -Same codebase for VB6 and twinBASIC
'   -64bit compatible
'   -Filter drives shown by type
'   -Uses same friendly name and icon as Explorer
'   -Monitors for drive add/remove (optional)
'   -Supports both dropdown list and standard dropdown styles
'   -Drive selection can be get/set by path, letter, or name.
'   -SelectionChanged event
'   -Can provide list of drives
'   -Can optionally classify USB hard drives as removable.
'
' Changelog:
'  Version 1.4
'   -The .Drive legacy method now returns the same path for
'    mapped network drives.
'   -There's now a drive icon and control name/version in the
'    combobox during design mode instead of a generic combo.
'
'  Version 1.3 (Released 23 Apr 2024)
'   -The .Drive property now returns names identical to the legacy
'     DriveList control, and when set, behaves identical to that
'     as well, only comparing the first letter.
'   -(Bug fix) ShowRemovableDrives toggled network drives instead.
'
'  Version 1.2 (Released 22 Apr 2024)
'   -Add Drive property get/let for compatibility with DriveList;
'     it behaves identically to .SelectDriveName.
'   -DriveCount is now ListCount, for DriveList compat. Also added
'     .ListIndex for selected index, and .List, same as GetDriveName.
'   -Add Enabled property get/let.
'   -(Bug fix) FocusDriveList VB6 syntax error
'   -(Bug fix) VB6 control bottom cut off
'
'  Version 1.1 (Released 22 Apr 2024)
'   -Autosize UC height to combo height
'   -Custom drop width now DPI aware
'   -FocusDriveList method to hopefully partially defray the lack of
'      a massive and usually typelib dependent in-place activation
'      hook to handle tab properly. Recommend ucShellBrowse if you
'      need proper tab key support.
'   -(Bug fix) DPI variable overridden by old test line.
'
'  Version 1.0 (Released 22 Apr 2024)
'   -Add Property Lets for SelectedDrive_____
'   -Add device add/remove monitoring via RegisterDeviceNotification
'   -Add DPI aware support
'   -Add DropdownWidth option
'
'********************************************************************

Private Enum BOOL
    CFALSE
    CTRUE
End Enum
Private Const WC_COMBOBOXEX = "ComboBoxEx32"

#If TWINBASIC Then
    Private Declare PtrSafe Function SendMessage Lib "user32" Alias "SendMessageW" (ByVal hWnd As LongPtr, ByVal wMsg As Long, ByVal wParam As LongPtr, lParam As Any) As LongPtr
    Private Declare PtrSafe Function CreateFileW Lib "kernel32" (ByVal lpFileName As LongPtr, ByVal dwDesiredAccess As Long, ByVal dwShareMode As FileShareMode, lpSecurityAttributes As SECURITY_ATTRIBUTES, ByVal dwCreationDisposition As CreateFileDisposition, ByVal dwFlagsAndAttributes As Long, ByVal hTemplateFile As LongPtr) As LongPtr
    Private Declare PtrSafe Function DeviceIoControl Lib "kernel32" (ByVal hDevice As LongPtr, ByVal dwIoControlCode As Long, lpInBuffer As Any, ByVal nInBufferSize As Long, lpOutBuffer As Any, ByVal nOutBufferSize As Long, lpBytesReturned As Long, lpOverlapped As OVERLAPPED) As BOOL
    Private Declare PtrSafe Function SHGetFileInfoW Lib "shell32" (ByVal pszPath As Any, ByVal dwFileAttributes As Long, psfi As SHFILEINFOW, ByVal cbFileInfo As Long, ByVal uFlags As SHGFI_flags) As LongPtr
    Private Declare PtrSafe Function GetClientRect Lib "user32" (ByVal hWnd As LongPtr, lpRect As RECT) As BOOL
    Private Declare PtrSafe Function GetLogicalDriveStringsW Lib "kernel32" (ByVal nBufferLength As Long, ByVal lpBuffer As LongPtr) As Long
    Private Declare PtrSafe Function GetDriveTypeW Lib "kernel32" (Optional ByVal lpRootPathName As LongPtr) As DriveTypes
    Private Declare PtrSafe Function SHParseDisplayName Lib "shell32" (ByVal pszName As LongPtr, ByVal pbc As LongPtr, ByRef ppidl As LongPtr, ByVal sfgaoIn As Long, ByRef psfgaoOut As Long) As Long
    Private Declare PtrSafe Function SHGetNameFromIDList Lib "shell32" (ByVal pidl As LongPtr, ByVal sigdnName As SIGDN, ByRef ppszName As LongPtr) As Long
    Private Declare PtrSafe Function SetWindowPos Lib "user32" (ByVal hWnd As LongPtr, ByVal hWndInsertAfter As LongPtr, ByVal X As Long, ByVal Y As Long, ByVal CX As Long, ByVal CY As Long, ByVal wFlags As SWP_Flags) As Long
    Private Declare PtrSafe Function CloseHandle Lib "kernel32" (ByVal hObject As LongPtr) As BOOL
    Private Declare PtrSafe Function GetWindowsDirectoryW Lib "kernel32" (ByVal lpBuffer As LongPtr, ByVal nSize As Long) As Long
    Private Declare PtrSafe Function CreateWindowExW Lib "user32" (ByVal dwExStyle As Long, ByVal lpClassName As LongPtr, ByVal lpWindowName As LongPtr, ByVal dwStyle As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hWndParent As LongPtr, ByVal hMenu As LongPtr, ByVal hInstance As LongPtr, lpParam As Any) As LongPtr
    Private Declare PtrSafe Function SysReAllocStringW Lib "oleaut32" Alias "SysReAllocString" (ByVal pBSTR As LongPtr, Optional ByVal pszStrPtr As LongPtr) As Long
    Private Declare PtrSafe Sub CoTaskMemFree Lib "ole32" (ByVal pv As LongPtr)
    Private Declare PtrSafe Function DefSubclassProc Lib "comctl32.dll" Alias "#413" (ByVal hWnd As LongPtr, ByVal uMsg As Long, ByVal wParam As LongPtr, ByVal lParam As LongPtr) As LongPtr
    Private Declare PtrSafe Function SetWindowSubclass Lib "comctl32.dll" Alias "#410" (ByVal hWnd As LongPtr, ByVal pfnSubclass As LongPtr, ByVal uIdSubclass As LongPtr, Optional ByVal dwRefData As LongPtr) As Long
    Private Declare PtrSafe Function RemoveWindowSubclass Lib "comctl32.dll" Alias "#412" (ByVal hWnd As LongPtr, ByVal pfnSubclass As LongPtr, ByVal uIdSubclass As LongPtr) As Long
    Private Declare PtrSafe Function GetDC Lib "user32" (ByVal hWnd As LongPtr) As LongPtr
    Private Declare PtrSafe Function ReleaseDC Lib "user32" (ByVal hWnd As LongPtr, ByVal hDC As LongPtr) As Long
    Private Declare PtrSafe Function GetDeviceCaps Lib "gdi32" (ByVal hDC As LongPtr, ByVal nIndex As Long) As Long
    Private Declare PtrSafe Function RegisterDeviceNotification Lib "user32" Alias "RegisterDeviceNotificationW" (ByVal hRecipient As LongPtr, NotificationFilter As Any, ByVal Flags As DEVICE_NOTIFY_FLAGS) As LongPtr
    Private Declare PtrSafe Function UnregisterDeviceNotification Lib "user32" (ByVal Handle As LongPtr) As BOOL
    Private Declare PtrSafe Function DestroyWindow Lib "user32" (ByVal hWnd As LongPtr) As Long
    Private Declare PtrSafe Function MoveWindow Lib "user32" (ByVal hWnd As LongPtr, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal bRepaint As Long) As Long
    Private Declare PtrSafe Function EnableWindow Lib "user32" (ByVal hWnd As LongPtr, ByVal fEnable As BOOL) As BOOL
    Private Declare PtrSafe Function RedrawWindow Lib "user32" (ByVal hWnd As LongPtr, ByVal lprcUpdate As LongPtr, ByVal hrgnUpdate As LongPtr, ByVal fuRedraw As Long) As Long
    Private Declare PtrSafe Function GetWindowRect Lib "user32" (ByVal hWnd As LongPtr, ByRef lpRect As RECT) As Long
    Private Declare PtrSafe Function SetFocusAPI Lib "user32" Alias "SetFocus" (ByVal hWnd As LongPtr) As LongPtr
    Private Declare PtrSafe Function GetVolumeInformationW Lib "kernel32" (ByVal lpRootPathName As LongPtr, ByVal lpVolumeNameBuffer As LongPtr, ByVal nVolumeNameSize As Long, lpVolumeSerialNumber As Long, lpMaximumComponentLength As Long, lpFileSystemFlags As Long, ByVal lpFileSystemNameBuffer As LongPtr, ByVal nFileSystemNameSize As Long) As BOOL
    Private Declare PtrSafe Function PathIsNetworkPathW Lib "shlwapi.dll" (ByVal lpszPath As LongPtr) As BOOL
    Private Declare PtrSafe Function PathIsUNCW Lib "shlwapi.dll" (ByVal lpszPath As LongPtr) As BOOL
    Private Declare PtrSafe Function WNetGetUniversalNameW Lib "mpr.dll" (ByVal lpLocalPath As LongPtr, ByVal dwInfoLevel As NETWK_NAME_INFOLEVEL, lpBuffer As Any, lpBufferSize As Long) As Long
    Private Declare PtrSafe Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As LongPtr)
    Private Declare PtrSafe Function lstrlenW Lib "kernel32" (lpString As Any) As Long
#Else
    Private Enum LongPtr
        vbNullPtr
    End Enum
    Private Declare Function SendMessage Lib "user32" Alias "SendMessageW" (ByVal hWnd As LongPtr, ByVal wMsg As Long, ByVal wParam As LongPtr, lParam As Any) As LongPtr
    Private Declare Function CreateFileW Lib "kernel32" (ByVal lpFileName As LongPtr, ByVal dwDesiredAccess As Long, ByVal dwShareMode As FileShareMode, ByVal lpSecurityAttributes As LongPtr, ByVal dwCreationDisposition As CreateFileDisposition, ByVal dwFlagsAndAttributes As Long, ByVal hTemplateFile As LongPtr) As LongPtr
    Private Declare Function DeviceIoControl Lib "kernel32" (ByVal hDevice As LongPtr, ByVal dwIoControlCode As Long, lpInBuffer As Any, ByVal nInBufferSize As Long, lpOutBuffer As Any, ByVal nOutBufferSize As Long, lpBytesReturned As Long, ByVal lpOverlapped As LongPtr) As BOOL
    Private Declare Function GetClientRect Lib "user32" (ByVal hWnd As LongPtr, lpRect As RECT) As BOOL
    Private Declare Function SHGetFileInfoW Lib "shell32" (ByVal pszPath As Any, ByVal dwFileAttributes As Long, psfi As SHFILEINFOW, ByVal cbFileInfo As Long, ByVal uFlags As SHGFI_flags) As LongPtr
    Private Declare Function GetLogicalDriveStringsW Lib "kernel32" (ByVal nBufferLength As Long, ByVal lpBuffer As LongPtr) As Long
    Private Declare Function GetDriveTypeW Lib "kernel32" (Optional ByVal lpRootPathName As LongPtr) As DriveTypes
    Private Declare Function SHParseDisplayName Lib "shell32" (ByVal pszName As LongPtr, ByVal pbc As LongPtr, ByRef ppidl As LongPtr, ByVal sfgaoIn As Long, ByRef psfgaoOut As Long) As Long
    Private Declare Function SHGetNameFromIDList Lib "shell32" (ByVal pidl As LongPtr, ByVal sigdnName As SIGDN, ByRef ppszName As LongPtr) As Long
    Private Declare Function SetWindowPos Lib "user32" (ByVal hWnd As LongPtr, ByVal hWndInsertAfter As LongPtr, ByVal X As Long, ByVal Y As Long, ByVal CX As Long, ByVal CY As Long, ByVal wFlags As SWP_Flags) As Long
    Private Declare Function CloseHandle Lib "kernel32" (ByVal hObject As LongPtr) As BOOL
    Private Declare Function GetWindowsDirectoryW Lib "kernel32" (ByVal lpBuffer As LongPtr, ByVal nSize As Long) As Long
    Private Declare Function CreateWindowExW Lib "user32" (ByVal dwExStyle As Long, ByVal lpClassName As LongPtr, ByVal lpWindowName As LongPtr, ByVal dwStyle As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hWndParent As LongPtr, ByVal hMenu As LongPtr, ByVal hInstance As LongPtr, lpParam As Any) As LongPtr
    Private Declare Function SysReAllocStringW Lib "oleaut32" Alias "SysReAllocString" (ByVal pBSTR As LongPtr, Optional ByVal pszStrPtr As LongPtr) As Long
    Private Declare Sub CoTaskMemFree Lib "ole32" (ByVal pv As LongPtr)
    Private Declare Function DefSubclassProc Lib "comctl32.dll" Alias "#413" (ByVal hWnd As LongPtr, ByVal uMsg As Long, ByVal wParam As LongPtr, ByVal lParam As LongPtr) As LongPtr
    Private Declare Function SetWindowSubclass Lib "comctl32.dll" Alias "#410" (ByVal hWnd As LongPtr, ByVal pfnSubclass As LongPtr, ByVal uIdSubclass As LongPtr, Optional ByVal dwRefData As LongPtr) As Long
    Private Declare Function RemoveWindowSubclass Lib "comctl32.dll" Alias "#412" (ByVal hWnd As LongPtr, ByVal pfnSubclass As LongPtr, ByVal uIdSubclass As LongPtr) As Long
    Private Declare Function GetDC Lib "user32" (ByVal hWnd As LongPtr) As LongPtr
    Private Declare Function ReleaseDC Lib "user32" (ByVal hWnd As LongPtr, ByVal hDC As LongPtr) As Long
    Private Declare Function GetDeviceCaps Lib "gdi32" (ByVal hDC As LongPtr, ByVal nIndex As Long) As Long
    Private Declare Function RegisterDeviceNotification Lib "user32" Alias "RegisterDeviceNotificationW" (ByVal hRecipient As LongPtr, NotificationFilter As Any, ByVal Flags As DEVICE_NOTIFY_FLAGS) As LongPtr
    Private Declare Function UnregisterDeviceNotification Lib "user32" (ByVal Handle As LongPtr) As BOOL
    Private Declare Function DestroyWindow Lib "user32" (ByVal hWnd As LongPtr) As Long
    Private Declare Function MoveWindow Lib "user32" (ByVal hWnd As LongPtr, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal bRepaint As Long) As Long
    Private Declare Function EnableWindow Lib "user32" (ByVal hWnd As LongPtr, ByVal fEnable As BOOL) As BOOL
    Private Declare Function RedrawWindow Lib "user32" (ByVal hWnd As LongPtr, ByVal lprcUpdate As LongPtr, ByVal hrgnUpdate As LongPtr, ByVal fuRedraw As Long) As Long
    Private Declare Function GetWindowRect Lib "user32" (ByVal hWnd As LongPtr, ByRef lpRect As RECT) As Long
    Private Declare Function SetFocusAPI Lib "user32" Alias "SetFocus" (ByVal hWnd As LongPtr) As LongPtr
    Private Declare Function GetVolumeInformationW Lib "kernel32" (ByVal lpRootPathName As LongPtr, ByVal lpVolumeNameBuffer As LongPtr, ByVal nVolumeNameSize As Long, lpVolumeSerialNumber As Long, lpMaximumComponentLength As Long, lpFileSystemFlags As Long, ByVal lpFileSystemNameBuffer As LongPtr, ByVal nFileSystemNameSize As Long) As BOOL
    Private Declare Function PathIsNetworkPathW Lib "shlwapi.dll" (ByVal lpszPath As LongPtr) As BOOL
    Private Declare Function PathIsUNCW Lib "shlwapi.dll" (ByVal lpszPath As LongPtr) As BOOL
    Private Declare Function WNetGetUniversalNameW Lib "mpr.dll" (ByVal lpLocalPath As LongPtr, ByVal dwInfoLevel As NETWK_NAME_INFOLEVEL, lpBuffer As Any, lpBufferSize As Long) As Long
    Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal Length As LongPtr)
    Private Declare Function lstrlenW Lib "kernel32" (lpString As Any) As Long
    #End If

Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Private Const WS_CHILD = &H40000000
Private Const WS_VISIBLE = &H10000000
Private Const WS_TABSTOP = &H10000
Private Const INVALID_HANDLE_VALUE = -1&
Private Const S_OK = 0
Private Const MAX_PATH                  As Long = 260
Private Const EM_SETREADONLY = &HCF
Private Const WM_DESTROY = &H2
Private Const WM_NOTIFYFORMAT = &H55
Private Const WM_COMMAND = &H111
Private Const WM_DEVICECHANGE = &H219
Private Const NFR_UNICODE = 2
Private Const LOGPIXELSY = 90

Private Enum NETWK_NAME_INFOLEVEL
    UNIVERSAL_NAME_INFO_LEVEL = &H1
    REMOTE_NAME_INFO_LEVEL = &H2
End Enum
Private Type UNIVERSAL_NAME_INFOW
    lpUniversalName As LongPtr
End Type

Private Enum FileShareMode
    FILE_SHARE_READ = &H1
    FILE_SHARE_WRITE = &H2
    FILE_SHARE_DELETE = &H4
End Enum
Private Enum CreateFileDisposition
    CREATE_NEW = 1
    CREATE_ALWAYS = 2
    OPEN_EXISTING = 3
    OPEN_ALWAYS = 4
    TRUNCATE_EXISTING = 5
End Enum

Private Type SECURITY_ATTRIBUTES
    nLength As Long
    lpSecurityDescriptor As LongPtr
    bInheritHandle As Long
End Type

Private Type OVERLAPPED
    Internal As LongPtr
    InternalHigh As LongPtr
    #If Win64 Then
    OffsetsOrPtr As LongLong
    #Else
    OffsetOrPtr As Long
    OffsetHigh As Long
    #End If
    hEvent As LongPtr
End Type

Private Enum SIGDN
    SIGDN_NORMALDISPLAY = &H0
    SIGDN_PARENTRELATIVEPARSING = &H80018001
    SIGDN_DESKTOPABSOLUTEPARSING = &H80028000
    SIGDN_PARENTRELATIVEEDITING = &H80031001
    SIGDN_DESKTOPABSOLUTEEDITING = &H8004C000
    SIGDN_FILESYSPATH = &H80058000
    SIGDN_URL = &H80068000
    SIGDN_PARENTRELATIVEFORADDRESSBAR = &H8007C001
    SIGDN_PARENTRELATIVE = &H80080001
    SIGDN_PARENTRELATIVEFORUI = &H80094001
End Enum

Private Enum DriveTypes
    DRIVE_UNKNOWN
    DRIVE_NO_ROOT_DIR
    DRIVE_REMOVABLE
    DRIVE_FIXED
    DRIVE_REMOTE
    DRIVE_CDROM
    DRIVE_RAMDISK
End Enum

Private Const IOCTL_STORAGE_GET_HOTPLUG_INFO As Long = &H2D0C14
Private Type STORAGE_HOTPLUG_INFO
    Size As Long ' version
    MediaRemovable As Byte ' ie. zip, jaz, cdrom, mo, etc. vs hdd
    MediaHotplug As Byte ' ie. does the device succeed a lock even though its not lockable media?
    DeviceHotplug As Byte ' ie. 1394, USB, etc.
    WriteCacheEnableOverride As Byte ' This field should not be relied upon because it is no longer used
End Type

Private Type SHFILEINFOW   ' shfi
  hIcon As LongPtr
  iIcon As Long
  dwAttributes As Long
  szDisplayName(MAX_PATH - 1) As Integer
  szTypeName(79) As Integer
End Type
Private Enum SHGFI_flags
  SHGFI_LARGEICON = &H0            ' sfi.hIcon is large icon
  SHGFI_SMALLICON = &H1            ' sfi.hIcon is small icon
  SHGFI_OPENICON = &H2              ' sfi.hIcon is open icon
  SHGFI_SHELLICONSIZE = &H4      ' sfi.hIcon is shell size (not system size), rtns BOOL
  SHGFI_PIDL = &H8                        ' pszPath is pidl, rtns BOOL
  ' Indicates that the function should not attempt to access the file specified by pszPath.
  ' Rather, it should act as if the file specified by pszPath exists with the file attributes
  ' passed in dwFileAttributes. This flag cannot be combined with the SHGFI_ATTRIBUTES,
  ' SHGFI_EXETYPE, or SHGFI_PIDL flags <---- !!!
  SHGFI_USEFILEATTRIBUTES = &H10   ' pretend pszPath exists, rtns BOOL
  SHGFI_ADDOVERLAYS = &H20
  SHGFI_OVERLAYINDEX = &H40 'Return overlay index in upper 8 bits of iIcon.
  SHGFI_ICON = &H100                    ' fills sfi.hIcon, rtns BOOL, use DestroyIcon
  SHGFI_DISPLAYNAME = &H200    ' isf.szDisplayName is filled (SHGDN_NORMAL), rtns BOOL
  SHGFI_TYPENAME = &H400          ' isf.szTypeName is filled, rtns BOOL
  SHGFI_ATTRIBUTES = &H800         ' rtns IShellFolder::GetAttributesOf  SFGAO_* flags
  SHGFI_ICONLOCATION = &H1000   ' fills sfi.szDisplayName with filename
                                                        ' containing the icon, rtns BOOL
  SHGFI_EXETYPE = &H2000            ' rtns two ASCII chars of exe type
  SHGFI_SYSICONINDEX = &H4000   ' sfi.iIcon is sys il icon index, rtns hImagelist
  SHGFI_LINKOVERLAY = &H8000&    ' add shortcut overlay to sfi.hIcon
  SHGFI_SELECTED = &H10000        ' sfi.hIcon is selected icon
  SHGFI_ATTR_SPECIFIED = &H20000    ' get only attributes specified in sfi.dwAttributes
End Enum

Private Enum DEVICE_NOTIFY_FLAGS
    DEVICE_NOTIFY_WINDOW_HANDLE = &H0
    DEVICE_NOTIFY_SERVICE_HANDLE = &H1
    DEVICE_NOTIFY_CALLBACK = &H2
    DEVICE_NOTIFY_ALL_INTERFACE_CLASSES = &H4
End Enum
Private Enum WMDEVICECHANGE_wParam
    DBT_APPYBEGIN = &H0
    DBT_APPYEND = &H1
    DBT_DEVNODES_CHANGED = &H7
    DBT_QUERYCHANGECONFIG = &H17
    DBT_CONFIGCHANGED = &H18
    DBT_CONFIGCHANGECANCELED = &H19
    DBT_MONITORCHANGE = &H1B
    DBT_SHELLLOGGEDON = &H20
    DBT_CONFIGMGAPI32 = &H22
    DBT_VXDINITCOMPLETE = &H23
    DBT_VOLLOCKQUERYLOCK = &H8041&
    DBT_VOLLOCKLOCKTAKEN = &H8042&
    DBT_VOLLOCKLOCKFAILED = &H8043&
    DBT_VOLLOCKQUERYUNLOCK = &H8044&
    DBT_VOLLOCKLOCKRELEASED = &H8045&
    DBT_VOLLOCKUNLOCKFAILED = &H8046&
    DBT_NO_DISK_SPACE = &H47
    DBT_LOW_DISK_SPACE = &H48
    DBT_CONFIGMGPRIVATE = &H7FFF
    DBT_DEVICEARRIVAL = &H8000&  ' system detected a new device
    DBT_DEVICEQUERYREMOVE = &H8001&  ' wants to remove, may fail
    DBT_DEVICEQUERYREMOVEFAILED = &H8002&  ' removal aborted
    DBT_DEVICEREMOVEPENDING = &H8003&  ' about to remove, still avail.
    DBT_DEVICEREMOVECOMPLETE = &H8004&  ' device is gone
    DBT_DEVICETYPESPECIFIC = &H8005&  ' type specific event
    DBT_CUSTOMEVENT = &H8006&  ' user-defined event
    DBT_VPOWERDAPI = &H8100&  ' VPOWERD API for Win95
    DBT_USERDEFINED = &HFFFF&
End Enum
Private Enum DBT_Flags
    DBTF_RESOURCE = &H1         ' network resource
    DBTF_XPORT = &H2         ' new transport coming or going
    DBTF_SLOWNET = &H4         ' new incoming transport is slow
'  (dbcn_resource undefined for now)
End Enum
Private Enum DBT_DEVTYPE
    DBT_DEVTYP_OEM = &H0         ' oem-defined device type
    DBT_DEVTYP_DEVNODE = &H1         ' devnode number
    DBT_DEVTYP_VOLUME = &H2         ' logical volume
    DBT_DEVTYP_PORT = &H3         ' serial, parallel
    DBT_DEVTYP_NET = &H4         ' network resource
    DBT_DEVTYP_DEVICEINTERFACE = &H5         ' device interface class
    DBT_DEVTYP_HANDLE = &H6         ' file system handle
End Enum
Private Type UUID
    Data1 As Long
    Data2 As Integer
    Data3 As Integer
    Data4(0 To 7) As Byte
End Type
Private Type DEV_BROADCAST_DEVICEINTERFACE
    dbcc_size As Long
    dbcc_devicetype As DBT_DEVTYPE
    dbcc_reserved As Long
    dbcc_classguid As UUID
    dbcc_name(0 To (MAX_PATH - 1)) As Integer  'NOTE: Buffer ubound is a guess. You may need more. It's a variable C-style array.
End Type

Private Enum SWP_Flags
    SWP_NOSIZE = &H1
    SWP_NOMOVE = &H2
    SWP_NOZORDER = &H4
    SWP_NOREDRAW = &H8
    SWP_NOACTIVATE = &H10
    SWP_FRAMECHANGED = &H20
    SWP_DRAWFRAME = SWP_FRAMECHANGED
    SWP_SHOWWINDOW = &H40
    SWP_HIDEWINDOW = &H80
    SWP_NOCOPYBITS = &H100
    SWP_NOOWNERZORDER = &H200
    SWP_NOREPOSITION = SWP_NOOWNERZORDER
    SWP_NOSENDCHANGING = &H400
    
    SWP_DEFERERASE = &H2000
    SWP_ASYNCWINDOWPOS = &H4000
End Enum


Private Const CCM_FIRST = &H2000
Private Const CCM_SETBKCOLOR = (CCM_FIRST + 1)   ' lParam is bkColor
Private Const CCM_SETCOLORSCHEME = (CCM_FIRST + 2)     ' lParam is color scheme
Private Const CCM_GETCOLORSCHEME = (CCM_FIRST + 3)     ' fills in COLORSCHEME pointed to by lParam
Private Const CCM_GETDROPTARGET = (CCM_FIRST + 4)
Private Const CCM_SETUNICODEFORMAT = (CCM_FIRST + 5)
Private Const CCM_GETUNICODEFORMAT = (CCM_FIRST + 6)
Private Const CCM_SETVERSION = (CCM_FIRST + 7)
Private Const CCM_GETVERSION = (CCM_FIRST + 8)
Private Const CCM_SETNOTIFYWINDOW = (CCM_FIRST + 9) '// wParam == hwndParent.
Private Const CCM_SETWINDOWTHEME = (CCM_FIRST + 11)
Private Const CCM_DPISCALE = (CCM_FIRST + 12)
Private Const CCM_TRANSLATEACCELERATOR = &H461 '(WM_USER + 97)

Private Const WM_USER = &H400
Private Const CB_ADDSTRING = &H143
Private Const CB_DELETESTRING = &H144
Private Const CB_DIR = &H145
Private Const CB_FINDSTRING = &H14C
Private Const CB_FINDSTRINGEXACT = &H158
Private Const CB_GETCOMBOBOXINFO = &H164
Private Const CB_GETCOUNT = &H146
Private Const CB_GETCURSEL = &H147
Private Const CB_GETDROPPEDCONTROLRECT = &H152
Private Const CB_GETDROPPEDSTATE = &H157
Private Const CB_GETDROPPEDWIDTH = &H15F
Private Const CB_GETEDITSEL = &H140
Private Const CB_GETEXTENDEDUI = &H156
Private Const CB_GETHORIZONTALEXTENT = &H15D
Private Const CB_GETITEMDATA = &H150
Private Const CB_GETITEMHEIGHT = &H154
Private Const CB_GETLBTEXT = &H148
Private Const CB_GETLBTEXTLEN = &H149
Private Const CB_GETLOCALE = &H15A
Private Const CB_GETTOPINDEX = &H15B
Private Const CB_INITSTORAGE = &H161
Private Const CB_INSERTSTRING = &H14A
Private Const CB_LIMITTEXT = &H141
Private Const CB_MSGMAX = &H15B
Private Const CB_MULTIPLEADDSTRING = &H163
Private Const CB_RESETCONTENT = &H14B
Private Const CB_SELECTSTRING = &H14D
Private Const CB_SETCURSEL = &H14E
Private Const CB_SETDROPPEDWIDTH = &H160
Private Const CB_SETEDITSEL = &H142
Private Const CB_SETEXTENDEDUI = &H155
Private Const CB_SETHORIZONTALEXTENT = &H15E
Private Const CB_SETITEMDATA = &H151
Private Const CB_SETITEMHEIGHT = &H153
Private Const CB_SETLOCALE = &H159
Private Const CB_SETTOPINDEX = &H15C
Private Const CB_SHOWDROPDOWN = &H14F
Private Const CBEC_SETCOMBOFOCUS = (&H165 + 1)   ' ;internal_nt
Private Const CBEC_KILLCOMBOFOCUS = (&H165 + 2) ';internal_nt
Private Const CBM_FIRST As Long = &H1700&
Private Const CB_SETMINVISIBLE = (CBM_FIRST + 1)
Private Const CB_GETMINVISIBLE = (CBM_FIRST + 2)
Private Const CB_SETCUEBANNER = (CBM_FIRST + 3)
Private Const CB_GETCUEBANNER = (CBM_FIRST + 4)
Private Const CBEM_INSERTITEMA = (WM_USER + 1)
Private Const CBEM_SETIMAGELIST = (WM_USER + 2)
Private Const CBEM_GETIMAGELIST = (WM_USER + 3)
Private Const CBEM_GETITEMA = (WM_USER + 4)
Private Const CBEM_SETITEMA = (WM_USER + 5)
Private Const CBEM_DELETEITEM = CB_DELETESTRING
Private Const CBEM_GETCOMBOCONTROL = (WM_USER + 6)
Private Const CBEM_GETEDITCONTROL = (WM_USER + 7)
Private Const CBEM_SETEXTENDEDSTYLE = (WM_USER + 8)
Private Const CBEM_GETEXTENDEDSTYLE = (WM_USER + 9)
Private Const CBEM_HASEDITCHANGED = (WM_USER + 10)
Private Const CBEM_INSERTITEMW = (WM_USER + 11)
Private Const CBEM_SETITEMW = (WM_USER + 12)
Private Const CBEM_GETITEMW = (WM_USER + 13)
Private Const CBEM_INSERTITEM = CBEM_INSERTITEMW
Private Const CBEM_SETITEM = CBEM_SETITEMW
Private Const CBEM_GETITEM = CBEM_GETITEMW
Private Const CBEM_SETUNICODEFORMAT = CCM_SETUNICODEFORMAT '8192 + 5
Private Const CBEM_GETUNICODEFORMAT = CCM_GETUNICODEFORMAT '8192 + 6
Private Const CBEM_SETWINDOWTHEME = CCM_SETWINDOWTHEME '8192 + 11
Private Enum ComboBox_Styles
    CBS_SIMPLE = &H1&
    CBS_DROPDOWN = &H2&
    CBS_DROPDOWNLIST = &H3&
    CBS_OWNERDRAWFIXED = &H10&
    CBS_OWNERDRAWVARIABLE = &H20&
    CBS_AUTOHSCROLL = &H40
    CBS_OEMCONVERT = &H80
    CBS_SORT = &H100&
    CBS_HASSTRINGS = &H200&
    CBS_NOINTEGRALHEIGHT = &H400&
    CBS_DISABLENOSCROLL = &H800&
    CBS_UPPERCASE = &H2000
    CBS_LOWERCASE = &H4000
End Enum

'// Notification messages
Private Const H_MAX As Long = (&HFFFF + 1)

Private Const CBN_ERRSPACE = (-1)
Private Const CBN_SELCHANGE = 1
Private Const CBN_DBLCLK = 2
Private Const CBN_SETFOCUS = 3
Private Const CBN_KILLFOCUS = 4
Private Const CBN_EDITCHANGE = 5
Private Const CBN_EDITUPDATE = 6
Private Const CBN_DROPDOWN = 7
Private Const CBN_CLOSEUP = 8
Private Const CBN_SELENDOK = 9
Private Const CBN_SELENDCANCEL = 10
Private Const CBEN_FIRST = (H_MAX - 800&)
Private Const CBEN_LAST = (H_MAX - 830&)
Private Const CBEN_GETDISPINFOA = (CBEN_FIRST - 0)
Private Const CBEN_GETDISPINFOW = (CBEN_FIRST - 7)
Private Const CBEN_GETDISPINFO = CBEN_GETDISPINFOW
Private Const CBEN_INSERTITEM = (CBEN_FIRST - 1)
Private Const CBEN_DELETEITEM = (CBEN_FIRST - 2)
Private Const CBEN_BEGINEDIT = (CBEN_FIRST - 4)
Private Const CBEN_ENDEDITA = (CBEN_FIRST - 5)
Private Const CBEN_ENDEDITW = (CBEN_FIRST - 6)
Private Const CBEN_ENDEDIT = CBEN_ENDEDITW
Private Const CBEN_DRAGBEGINA = (CBEN_FIRST - 8)
Private Const CBEN_DRAGBEGINW = (CBEN_FIRST - 9)
Private Const CBEN_DRAGBEGIN = CBEN_DRAGBEGINW
'// lParam specifies why the endedit is happening
Private Const CBENF_KILLFOCUS = 1
Private Const CBENF_RETURN = 2
Private Const CBENF_ESCAPE = 3
Private Const CBENF_DROPDOWN = 4

Private Enum CBEX_ExStyles
    CBES_EX_NOEDITIMAGE = &H1
    CBES_EX_NOEDITIMAGEINDENT = &H2
    CBES_EX_PATHWORDBREAKPROC = &H4
    CBES_EX_NOSIZELIMIT = &H8
    CBES_EX_CASESENSITIVE = &H10
    '6.0
    CBES_EX_TEXTENDELLIPSIS = &H20
End Enum
Private Enum COMBOBOXEXITEM_Mask
    CBEIF_TEXT = &H1
    CBEIF_IMAGE = &H2
    CBEIF_SELECTEDIMAGE = &H4
    CBEIF_OVERLAY = &H8
    CBEIF_INDENT = &H10
    CBEIF_LPARAM = &H20
    CBEIF_DI_SETITEM = &H10000000
End Enum
Private Type COMBOBOXEXITEMW
    Mask As COMBOBOXEXITEM_Mask
    iItem As LongPtr
    pszText As LongPtr      '// LPCSTR
    cchTextMax As Long
    iImage As Long
    iSelectedImage As Long
    iOverlay As Long
    iIndent As Long
    lParam As LongPtr
End Type

Private hMain As LongPtr
Private hCB As LongPtr
Private hEdit As LongPtr

Private himl As LongPtr

Private hNotify As LongPtr

Private mDPI As Single

Private mStd As Boolean
Private Const mDefStd As Boolean = True

Private mOpt As Boolean
Private Const mDefOpt As Boolean = True

Private mNet As Boolean
Private Const mDefNet As Boolean = True

Private mUSB As Boolean
Private Const mDefUSB As Boolean = True

Private mHP As Boolean
Private Const mDefHP As Boolean = False

Private cyList As Long
Private Const mDefCY As Long = 400

Private cxList As Long
Private Const mDefCX As Long = 0

Private mDD As Boolean
Private Const mDefDD As Boolean = True

Private mBk As OLE_COLOR
Private Const mDefBk As Long = &H8000000F

Private mNotify As Boolean
Private Const mDefNotify As Boolean = True

Private mEnabled As Boolean
Private Const mDefEnabled As Boolean = True

#If TWINBASIC Then
[EnumId("55209AC8-57EA-4644-AA85-4974AA31E100")]
#End If
Public Enum UCDCType
    UCDC_DropdownList
    UCDC_Combo
End Enum
Private mStyle As UCDCType
Private Const mDefStyle As Long = 0

'bControlInit = The DriveAdded event is being raised as the control starts up and adds all drives,
'               it's not representing a new drive added to the system.
'Add/Remove events are only raised if MonitorChanges = True (including on startup).
Public Event DriveAdded(ByVal Path As String, ByVal Letter As String, ByVal Name As String, ByVal nType As Long, ByVal bControlInit As Boolean)
Public Event DriveRemoved(ByVal Path As String, ByVal Letter As String, ByVal Name As String, ByVal nType As Long)
Public Event SelectionChanged(ByVal NewPath As String, ByVal NewLetter As String, ByVal NewName As String, ByVal NewDriveType As Long)
Attribute SelectionChanged.VB_MemberFlags = "200"
Public Event DriveListDropdown()
Public Event DriveListCloseup()

Private Type DriveEntry
    Name As String 'i.e. Local disk (C:)
    Letter As String 'i.e. C
    Path As String 'i.e. C:\
    NameOld As String 'Name formatted like old drive control, i.e. c: [Local disk]
    Type As DriveTypes
    Removed As Boolean
    nIcon As Long
    Index As Long
End Type
Private mDrives() As DriveEntry
Private mDrivesPrv() As DriveEntry
Private mCt As Long, mCtPrv As Long
Private mWindows As String
Private mPrev As String

Private Sub UserControl_Initialize() 'Handles UserControl.Initialize
    Dim hDC As LongPtr
    hDC = GetDC(0&)
    mDPI = GetDeviceCaps(hDC, LOGPIXELSY) / 96
    ReleaseDC 0&, hDC
    mWindows = String$(MAX_PATH, 0)
    Dim lRet As Long
    lRet = GetWindowsDirectoryW(StrPtr(mWindows), MAX_PATH) 'for picking default drive
    If lRet > 3 Then
        mWindows = Left$(mWindows, 3)
    End If
End Sub

Private Sub UserControl_ReadProperties(PropBag As PropertyBag) 'Handles UserControl.ReadProperties
    mStd = PropBag.ReadProperty("ShowStandardDrives", mDefStd)
    mOpt = PropBag.ReadProperty("ShowOpticalDrives", mDefOpt)
    mNet = PropBag.ReadProperty("ShowNetworkDrives", mDefNet)
    mUSB = PropBag.ReadProperty("ShowRemovableDrives", mDefUSB)
    cxList = PropBag.ReadProperty("DropdownWidth", mDefCX)
    cyList = PropBag.ReadProperty("DropdownHeight", mDefCY)
    mStyle = PropBag.ReadProperty("ComboStyle", mDefStyle)
    mHP = PropBag.ReadProperty("NoFixedUSB", mDefHP)
    mBk = PropBag.ReadProperty("BackColor", mDefBk)
    mNotify = PropBag.ReadProperty("MonitorChanges", mDefNotify)
    mEnabled = PropBag.ReadProperty("Enabled", mDefEnabled)
    InitControl
End Sub

Private Sub UserControl_WriteProperties(PropBag As PropertyBag) 'Handles UserControl.WriteProperties
    PropBag.WriteProperty "ShowStandardDrives", mStd, mDefStd
    PropBag.WriteProperty "ShowOpticalDrives", mOpt, mDefOpt
    PropBag.WriteProperty "ShowNetworkDrives", mNet, mDefNet
    PropBag.WriteProperty "ShowRemovableDrives", mUSB, mDefUSB
    PropBag.WriteProperty "DropdownWidth", cxList, mDefCX
    PropBag.WriteProperty "DropdownHeight", cyList, mDefCY
    PropBag.WriteProperty "ComboStyle", mStyle, mDefStyle
    PropBag.WriteProperty "NoFixedUSB", mHP, mDefHP
    PropBag.WriteProperty "BackColor", mBk, mDefBk
    PropBag.WriteProperty "MonitorChanges", mNotify, mDefNotify
    PropBag.WriteProperty "Enabled", mEnabled, mDefEnabled
End Sub

Private Sub UserControl_InitProperties() 'Handles UserControl.InitProperties
    mNet = mDefNet
    mOpt = mDefOpt
    mStd = mDefStd
    mUSB = mDefUSB
    cxList = mDefCX
    cyList = mDefCY
    mStyle = mDefStyle
    mHP = mDefHP
    mBk = mDefBk
    mNotify = mDefNotify
End Sub

Private Sub UserControl_Resize() 'Handles UserControl.Resize
If hMain Then
    Dim rc As RECT
    Dim rcWnd As RECT
    GetClientRect UserControl.hWnd, rc
    SetWindowPos hMain, 0, 0, 0, rc.Right, cyList * mDPI, SWP_NOMOVE Or SWP_NOZORDER
    With UserControl
    MoveWindow hMain, 0, 0, .ScaleWidth, .ScaleHeight, 1
    GetWindowRect hMain, rcWnd
    If (rcWnd.Bottom - rcWnd.Top) <> .ScaleHeight Or (rcWnd.Right - rcWnd.Left) <> .ScaleWidth Then
        .Extender.Height = .ScaleY((rcWnd.Bottom - rcWnd.Top), vbPixels, vbContainerSize)
    End If
    End With
End If
End Sub

Public Property Get BackColor() As OLE_COLOR: BackColor = mBk: End Property
Public Property Let BackColor(ByVal cr As OLE_COLOR)
    mBk = cr
    UserControl.BackColor = cr
End Property
Public Property Get ComboStyle() As UCDCType: ComboStyle = mStyle: End Property
Attribute ComboStyle.VB_Description = "Sets the type of combobox used. Cannnot be changed during runtime."
Public Property Let ComboStyle(ByVal Value As UCDCType): mStyle = Value: End Property
    
Public Property Get Enabled() As Boolean: Enabled = mEnabled: End Property
Attribute Enabled.VB_Description = "Sets whether the control is enabled."
Public Property Let Enabled(ByVal fEnable As Boolean)
    If fEnable <> mEnabled Then
        mEnabled = fEnable
        If hMain Then
            If mEnabled Then
                EnableWindow hMain, CTRUE
            Else
                EnableWindow hMain, CFALSE
            End If
        End If
    End If
End Property

#If TWINBASIC Then
Public Property Get DriveComboHwnd() As LongPtr: DriveComboHwnd = hMain: End Property
#Else
Public Property Get DriveComboHwnd() As Long: DriveComboHwnd = hMain: End Property
#End If

Public Property Get MonitorChanges() As Boolean: MonitorChanges = mStd: End Property
Attribute MonitorChanges.VB_Description = "Monitor for drives being added and removed and update list accordingly."
Public Property Let MonitorChanges(ByVal Value As Boolean)
    If Value <> mNotify Then
        mNotify = Value
        If Ambient.UserMode Then
            If mNotify Then
                If hNotify = 0 Then
                    Dim tFilter As DEV_BROADCAST_DEVICEINTERFACE
                    tFilter.dbcc_size = LenB(tFilter)
                    tFilter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE
                    tFilter.dbcc_classguid = GUID_DEVINTERFACE_VOLUME
                    hNotify = RegisterDeviceNotification(hMain, tFilter, DEVICE_NOTIFY_WINDOW_HANDLE)
                End If
            Else
                If hNotify Then
                    UnregisterDeviceNotification hNotify
                    hNotify = 0
                End If
            End If
        End If
    End If
End Property

Public Property Get ShowStandardDrives() As Boolean: ShowStandardDrives = mStd: End Property
Attribute ShowStandardDrives.VB_Description = "Include standard internal hard drives in the list."
Public Property Let ShowStandardDrives(ByVal Value As Boolean)
    If Value <> mStd Then
        mStd = Value
        If Ambient.UserMode Then RefreshDriveList
    End If
End Property

Public Property Get ShowOpticalDrives() As Boolean: ShowOpticalDrives = mOpt: End Property
Attribute ShowOpticalDrives.VB_Description = "Include optical drives like DVD and BluRay drives in the list."
Public Property Let ShowOpticalDrives(ByVal Value As Boolean)
    If Value <> mOpt Then
        mOpt = Value
        If Ambient.UserMode Then RefreshDriveList
    End If
End Property

Public Property Get ShowNetworkDrives() As Boolean: ShowNetworkDrives = mNet: End Property
Attribute ShowNetworkDrives.VB_Description = "Include mapped network drives in the list."
Public Property Let ShowNetworkDrives(ByVal Value As Boolean)
    If Value <> mNet Then
        mNet = Value
        If Ambient.UserMode Then RefreshDriveList
    End If
End Property

Public Property Get NoFixedUSB() As Boolean: NoFixedUSB = mHP: End Property
Attribute NoFixedUSB.VB_Description = "Never count USB mass storage as fixed (standard) drive."
Public Property Let NoFixedUSB(ByVal Value As Boolean)
    If Value <> mHP Then
        mHP = Value
        If Ambient.UserMode Then RefreshDriveList
    End If
End Property

Public Property Get DropdownWidth() As Long: DropdownWidth = cxList: End Property
Attribute DropdownWidth.VB_Description = "Sets the width of the dropdown. Set to 0 to use default."
Public Property Let DropdownWidth(ByVal Value As Long)
    If Value <> cxList Then
        cxList = Value
        If Ambient.UserMode Then
            If cxList = 0 Then
                Dim rc As RECT
                GetClientRect hMain, rc
                SendMessage hMain, CB_SETDROPPEDWIDTH, rc.Right, ByVal 0
            Else
                SendMessage hMain, CB_SETDROPPEDWIDTH, cxList * mDPI, ByVal 0
            End If
        End If
    End If
End Property

Public Property Get DropdownHeight() As Long: DropdownHeight = cyList: End Property
Attribute DropdownHeight.VB_Description = "Sets the maximum height of the dropdown list of all drives."
Public Property Let DropdownHeight(ByVal Value As Long)
    If Value <> cyList Then
        cyList = Value
        If Ambient.UserMode Then
            UserControl_Resize
        End If
    End If
End Property

Public Property Get ShowRemovableDrives() As Boolean: ShowRemovableDrives = mNet: End Property
Attribute ShowRemovableDrives.VB_Description = "Include removable drives like USB flash drives in the list."
Public Property Let ShowRemovableDrives(ByVal Value As Boolean)
    If Value <> mUSB Then
        mUSB = Value
        If Ambient.UserMode Then RefreshDriveList
    End If
End Property

Public Property Get SelectedDriveLetter() As String
    If Ambient.UserMode Then
        Dim nIdx As Long
        Dim nSel As Long
        nSel = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
        nIdx = -1
        nIdx = CLng(GetCBXItemlParam(hMain, nSel))
        SelectedDriveLetter = mDrives(nIdx).Letter
    End If
End Property
Public Property Let SelectedDriveLetter(ByVal sLetter As String)
    If Ambient.UserMode Then
        If mCt Then
            Dim i As Long
            For i = 0 To UBound(mDrives)
                If LCase$(mDrives(i).Letter) = LCase$(sLetter) Then
                    SendMessage hMain, CB_SETCURSEL, mDrives(i).Index, ByVal 0
                    RaiseEvent SelectionChanged(mDrives(i).Path, mDrives(i).Letter, mDrives(i).Name, mDrives(i).Type)
                End If
            Next
        End If
    End If
End Property

Public Property Get SelectedDriveName() As String
    If Ambient.UserMode Then
        Dim nIdx As Long
        Dim nSel As Long
        nSel = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
        nIdx = -1
        nIdx = CLng(GetCBXItemlParam(hMain, nSel))
        SelectedDriveName = mDrives(nIdx).Name
    End If
End Property
Public Property Let SelectedDriveName(ByVal sName As String)
    If Ambient.UserMode Then
        If mCt Then
            Dim i As Long
            For i = 0 To UBound(mDrives)
                If LCase$(mDrives(i).Name) = LCase$(sName) Then
                    SendMessage hMain, CB_SETCURSEL, mDrives(i).Index, ByVal 0
                    RaiseEvent SelectionChanged(mDrives(i).Path, mDrives(i).Letter, mDrives(i).Name, mDrives(i).Type)
                End If
            Next
        End If
    End If
End Property

Public Property Get Drive() As String
    If Ambient.UserMode Then
        Dim nIdx As Long
        Dim nSel As Long
        nSel = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
        nIdx = -1
        nIdx = CLng(GetCBXItemlParam(hMain, nSel))
        Drive = mDrives(nIdx).NameOld
    End If
End Property
Public Property Let Drive(ByVal sName As String)
    If Ambient.UserMode Then
        If mCt Then
            Dim i As Long
            For i = 0 To UBound(mDrives)
                If LCase$(mDrives(i).Letter) = LCase$(Left$(sName, 1)) Then
                    SendMessage hMain, CB_SETCURSEL, mDrives(i).Index, ByVal 0
                    RaiseEvent SelectionChanged(mDrives(i).Path, mDrives(i).Letter, mDrives(i).Name, mDrives(i).Type)
                    Exit Property
                End If
            Next
            Err.Raise 68
        End If
    End If
End Property

Public Property Get SelectedDrivePath() As String
    If Ambient.UserMode Then
        Dim nIdx As Long
        Dim nSel As Long
        nSel = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
        nIdx = -1
        nIdx = CLng(GetCBXItemlParam(hMain, nSel))
        SelectedDrivePath = mDrives(nIdx).Path
    End If
End Property
Public Property Let SelectedDrivePath(ByVal sPath As String)
    If Ambient.UserMode Then
        If mCt Then
            Dim i As Long
            For i = 0 To UBound(mDrives)
                If LCase$(mDrives(i).Path) = LCase$(sPath) Then
                    SendMessage hMain, CB_SETCURSEL, mDrives(i).Index, ByVal 0
                    RaiseEvent SelectionChanged(mDrives(i).Path, mDrives(i).Letter, mDrives(i).Name, mDrives(i).Type)
                End If
            Next
        End If
    End If
End Property

Public Property Get SelectedDriveType() As Long
    If Ambient.UserMode Then
        Dim nIdx As Long
        Dim nSel As Long
        nSel = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
        nIdx = -1
        nIdx = CLng(GetCBXItemlParam(hMain, nSel))
        SelectedDriveType = mDrives(nIdx).Type
    End If
End Property

Public Property Get ListCount() As Long
    ListCount = mCt
End Property
Public Property Get ListIndex() As Long
    ListIndex = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
End Property
Public Function List(ByVal nIndex As Long) As String
    List = GetDriveName(nIndex)
End Function

Public Function GetDriveName(ByVal nItem As Long) As String
    If Ambient.UserMode Then
        Dim nIdx As Long
        nIdx = CLng(GetCBXItemlParam(hMain, nItem))
        If nIdx <> -1 Then
            GetDriveName = mDrives(nIdx).Name
        End If
    End If
End Function
Public Function GetDriveLetter(ByVal nItem As Long) As String
    If Ambient.UserMode Then
        Dim nIdx As Long
        nIdx = CLng(GetCBXItemlParam(hMain, nItem))
        If nIdx <> -1 Then
            GetDriveLetter = mDrives(nIdx).Letter
        End If
    End If
End Function
Public Function GetDrivePath(ByVal nItem As Long) As String
    If Ambient.UserMode Then
        Dim nIdx As Long
        nIdx = CLng(GetCBXItemlParam(hMain, nItem))
        If nIdx <> -1 Then
            GetDrivePath = mDrives(nIdx).Path
        End If
    End If
End Function
Public Function GetDriveType(ByVal nItem As Long) As Long
    If Ambient.UserMode Then
        Dim nIdx As Long
        nIdx = CLng(GetCBXItemlParam(hMain, nItem))
        If nIdx <> -1 Then
            GetDriveType = mDrives(nIdx).Type
        End If
    End If
End Function

Private Function GetSysImageList(uFlags As SHGFI_flags) As LongPtr
    Dim sfi As SHFILEINFOW
    Dim sSys As String
    Dim L As Long
    sSys = String$(MAX_PATH, 0)
    L = GetWindowsDirectoryW(StrPtr(sSys), MAX_PATH)
    If L Then
        sSys = Left$(sSys, L)
    Else
        sSys = Left$(Environ("WINDIR"), 3)
    End If
    ' Any valid file system path can be used to retrieve system image list handles.
    GetSysImageList = SHGetFileInfoW(ByVal StrPtr(sSys), 0, sfi, LenB(sfi), SHGFI_SYSICONINDEX Or uFlags)
    End Function
    Private Function GetIconIndex(ByVal sPath As String, uType As Long) As Long
    Dim sfi As SHFILEINFOW
    If SHGetFileInfoW(ByVal StrPtr(sPath), 0, sfi, LenB(sfi), SHGFI_SYSICONINDEX Or uType) Then
        GetIconIndex = sfi.iIcon
    End If
    End Function

    ' Private Sub UserControl_Show() Handles UserControl.Show
    Private Sub InitControl()
    Debug.Print "UserControl_Show"
    Me.BackColor = mBk
    himl = GetSysImageList(SHGFI_SMALLICON)
    Dim dwStyle As ComboBox_Styles
    dwStyle = WS_CHILD Or WS_VISIBLE Or CBS_AUTOHSCROLL Or WS_TABSTOP
    If mStyle = UCDC_DropdownList Then
        dwStyle = dwStyle Or CBS_DROPDOWNLIST
    Else
        dwStyle = dwStyle Or CBS_DROPDOWN
    End If
    Dim rc As RECT
    GetClientRect UserControl.hWnd, rc
    hMain = CreateWindowExW(0, StrPtr(WC_COMBOBOXEX), 0, dwStyle, _
                            0, 0, rc.Right, cyList * mDPI, UserControl.hWnd, 0, App.hInstance, ByVal 0)

    hCB = SendMessage(hMain, CBEM_GETCOMBOCONTROL, 0, ByVal 0&)
    hEdit = SendMessage(hMain, CBEM_GETEDITCONTROL, 0, ByVal 0&)

    SendMessage hEdit, EM_SETREADONLY, 1&, ByVal 0&
    
    Call SendMessage(hMain, CBEM_SETIMAGELIST, 0, ByVal himl)

    If Ambient.UserMode Then
        Subclass2 hMain, AddressOf ucDriveComboWndProc, hMain, ObjPtr(Me)
        RefreshDriveList
        Dim tFilter As DEV_BROADCAST_DEVICEINTERFACE
        tFilter.dbcc_size = 32 'We can't use LenB because it uses the size above 28 to calculate
                                'the length of the string in the C-style variable array on the end.
                                'It's declared with a buffer since VB/tB don't support those, but if
                                'the buffer isn't in use, use what we'd get for sizeof() if it wasn't
                                'used in C++.
        tFilter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE
        tFilter.dbcc_classguid = GUID_DEVINTERFACE_VOLUME
        hNotify = RegisterDeviceNotification(hMain, tFilter, DEVICE_NOTIFY_WINDOW_HANDLE)
    Else
        Dim sSys As String
        Dim L As Long
        sSys = String$(MAX_PATH, 0)
        L = GetWindowsDirectoryW(StrPtr(sSys), MAX_PATH)
        If L Then
            sSys = Left$(sSys, IIf(L < 3, L, 3))
        Else
            sSys = Left$(Environ("WINDIR"), 3)
        End If
        Dim nIcon As Long
        nIcon = GetIconIndex(sSys, SHGFI_SMALLICON)
        CBX_InsertItem hMain, Ambient.DisplayName, nIcon
        SendMessage hMain, CB_SETCURSEL, 0, ByVal 0
    End If

    If mEnabled = False Then
        EnableWindow hMain, CFALSE
    End If
    
    UserControl_Resize
End Sub

Private Sub UserControl_Terminate() 'Handles UserControl.Terminate
    If hNotify Then
        UnregisterDeviceNotification hNotify
        hNotify = 0
    End If
    DestroyWindow hMain
End Sub

Private Sub AnalyzeAddRemove()
    Dim i As Long, j As Long
    Dim bFound As Boolean
    'First handle special cases
    If mCtPrv = 0 Then 'Initial run
        For i = 0 To UBound(mDrives)
            RaiseEvent DriveAdded(mDrives(i).Path, mDrives(i).Letter, mDrives(i).Name, mDrives(i).Type, True)
        Next
        Exit Sub
    End If
    If mCt = 0 Then
        For i = 0 To UBound(mDrivesPrv)
            RaiseEvent DriveRemoved(mDrivesPrv(i).Path, mDrivesPrv(i).Letter, mDrivesPrv(i).Name, mDrivesPrv(i).Type)
        Next
        Exit Sub
    End If
    'Handle drives added (drives in the new set not in the old set)
    For i = 0 To UBound(mDrives)
        bFound = False
        For j = 0 To UBound(mDrivesPrv)
            If LCase$(mDrives(i).Path) = LCase$(mDrivesPrv(j).Path) Then
                bFound = True
                Exit For
            End If
        Next
        If bFound = False Then
            RaiseEvent DriveAdded(mDrives(i).Path, mDrives(i).Letter, mDrives(i).Name, mDrives(i).Type, False)
        End If
    Next
    'Handle drives removed. Drives in the old set not in the new set.
    'Yes, there's probably a better way to do this
    For i = 0 To UBound(mDrivesPrv)
        bFound = False
        For j = 0 To UBound(mDrives)
            If LCase$(mDrivesPrv(i).Path) = LCase$(mDrives(j).Path) Then
                bFound = True
                Exit For
            End If
        Next
        If bFound = False Then
            RaiseEvent DriveRemoved(mDrivesPrv(i).Path, mDrivesPrv(i).Letter, mDrivesPrv(i).Name, mDrivesPrv(i).Type)
        End If
    Next
End Sub
Public Sub RefreshDriveList()
    If mCt Then 'Restore previous and cache old to analyze add/remove
        Dim nIdx As Long
        Dim nSel As Long
        nSel = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
        nIdx = -1
        nIdx = CLng(GetCBXItemlParam(hMain, nSel))
        mPrev = mDrives(nIdx).Path
        mCtPrv = mCt
        mDrivesPrv = mDrives
    End If
    SendMessage hMain, CB_RESETCONTENT, 0, ByVal 0
    ReDim mDrives(0)
    mCt = 0
    Dim sDriveLst As String
    Dim sDrives() As String
    Dim sVolName As String
    Dim sName As String
    sDriveLst = String$(256, 0)
    Dim cch As Long
    Dim i As Long
    Dim lRet As Long
    Dim nDef As Long
    Dim nType As DriveTypes
    Dim pidl As LongPtr
    Dim lpName As LongPtr
    Dim dwAtr As Long

    cch = GetLogicalDriveStringsW(Len(sDriveLst), StrPtr(sDriveLst))
    Debug.Print "cch=" & cch & ", str=" & sDriveLst
    If cch > 0 Then
        sDriveLst = Left$(sDriveLst, cch)
        sDrives = Split(sDriveLst, vbNullChar)
        For i = 0 To UBound(sDrives)
            'Debug.Print "Drive(" & i ")={" & sDrives(i) & "}"
            If Len(sDrives(i)) Then
                sName = ""
                If SHParseDisplayName(StrPtr(sDrives(i)), 0, pidl, 0, dwAtr) = S_OK Then
                    If SHGetNameFromIDList(pidl, SIGDN_NORMALDISPLAY, lpName) = S_OK Then
                        If lpName Then sName = LPWSTRtoStr(lpName)
                    End If
                End If
                If sName = "" Then sName = sDrives(i)
                nType = GetDriveTypeW(StrPtr(sDrives(i)))
                If (nType = DRIVE_FIXED) And (mHP = True) Then
                    If IsTrueRemovable(sDrives(i)) Then
                        nType = DRIVE_REMOVABLE
                    End If
                End If
                If (mStd = False) And (nType = DRIVE_FIXED) Then GoTo nxt
                If (mOpt = False) And (nType = DRIVE_CDROM) Then GoTo nxt
                If (mNet = False) And (nType = DRIVE_REMOTE) Then GoTo nxt
                If (mUSB = False) And (nType = DRIVE_REMOVABLE) Then GoTo nxt
                ReDim Preserve mDrives(mCt)
                mDrives(mCt).Letter = Left$(sDrives(i), 1)
                mDrives(mCt).Path = sDrives(i)
                mDrives(mCt).Name = sName
                mDrives(mCt).nIcon = GetIconIndex(sDrives(i), SHGFI_SMALLICON)
                mDrives(mCt).Index = CBX_InsertItem(hMain, mDrives(mCt).Name, mDrives(mCt).nIcon, , mCt)
                SetOldName sDrives(i), mDrives(mCt).Letter, mCt
                If mPrev <> "" Then
                    If sDrives(i) = mPrev Then
                        nDef = mDrives(mCt).Index
                    End If
                Else
                    If sDrives(i) = mWindows Then
                        nDef = mDrives(mCt).Index
                    End If
                End If
                mCt = mCt + 1
            End If
nxt:
        Next
    End If
    SendMessage hMain, CB_SETCURSEL, nDef, ByVal 0
    If mNotify Then AnalyzeAddRemove
End Sub
Private Sub SetOldName(sPath As String, sLetter As String, nIdx As Long)
    Dim sTmp As String
    Dim sOld As String
    Dim dwFlag As Long
    sOld = LCase$(sLetter) & ":"
    If PathIsNetworkPathW(StrPtr(sPath)) Then
        sOld = GetOldNetName(sOld)
    Else
        sTmp = String$(34, 0)
        If GetVolumeInformationW(StrPtr(sPath), StrPtr(sTmp), 34, ByVal 0, 0, dwFlag, 0, 0) Then
            If InStr(sTmp, vbNullChar) > 1 Then
                sTmp = Left$(sTmp, InStr(sTmp, vbNullChar) - 1)
                sOld = sOld & " [" & sTmp & "]"
            End If
        End If
    End If
    mDrives(nIdx).NameOld = sOld
End Sub
Private Function GetOldNetName(ByVal sLetter As String) As String
    Dim tn As UNIVERSAL_NAME_INFOW
    Dim lRet As Long
    Dim bt() As Byte
    Dim cb As Long
    ReDim bt((MAX_PATH * 2 + 1) + LenB(tn))
    cb = UBound(bt) + 1
    lRet = WNetGetUniversalNameW(StrPtr(sLetter), UNIVERSAL_NAME_INFO_LEVEL, bt(0), cb)
    If lRet = S_OK Then
        CopyMemory tn, bt(0), LenB(tn)
        Dim sPath As String
        Dim cch As Long
        cch = lstrlenW(ByVal tn.lpUniversalName)
        If cch = 0 Then
            GetOldNetName = sLetter
            Exit Function
        End If
        sPath = String$(cch, 0)
        CopyMemory ByVal StrPtr(sPath), ByVal tn.lpUniversalName, cch * 2
        GetOldNetName = sLetter & " [" & sPath & "]"
        Exit Function
    Else
        Debug.Print "GetOldNetName->Error: " & lRet
    End If
    GetOldNetName = sLetter
End Function
Private Function CBX_InsertItem(ByVal hCBoxEx As LongPtr, sText As String, Optional iImage As Long = -1, Optional iOverlay As Long = -1, Optional lParam As Long = 0, Optional iItem As Long = -1, Optional iIndent As Long = 0, Optional iImageSel As Long = -1) As Long

    Dim cbxi As COMBOBOXEXITEMW

    With cbxi
    .Mask = CBEIF_TEXT
    .cchTextMax = Len(sText)
    .pszText = StrPtr(sText)
    If iImage <> -1 Then
        .Mask = .Mask Or CBEIF_IMAGE Or CBEIF_SELECTEDIMAGE
        .iImage = iImage
    End If
    If iOverlay <> -1 Then
        .iOverlay = iOverlay
    End If
    If lParam Then
        .Mask = .Mask Or CBEIF_LPARAM
        .lParam = lParam
    End If
    If iIndent Then
        .Mask = .Mask Or CBEIF_INDENT
        .iIndent = iIndent
    End If
    If iImageSel <> -1 Then
        .Mask = .Mask
        .iSelectedImage = iImageSel
    Else
        .iSelectedImage = iImage
    End If

    .iItem = iItem

    End With

    CBX_InsertItem = CLng(SendMessage(hCBoxEx, CBEM_INSERTITEMW, 0, cbxi))

End Function
Private Function GetCBXItemlParam(hWnd As LongPtr, i As Long) As LongPtr
    Dim cbxi As COMBOBOXEXITEMW
    With cbxi
    .Mask = CBEIF_LPARAM
    .iItem = i
    End With
    If SendMessage(hWnd, CBEM_GETITEMW, 0, cbxi) Then
    GetCBXItemlParam = cbxi.lParam
    Else
    GetCBXItemlParam = -1
    End If
End Function

Public Sub FocusDriveList()
    UserControl.SetFocus
    SetFocusAPI UserControl.ContainerHwnd
    SetFocusAPI hMain
End Sub
Private Function IsTrueRemovable(DrvLetter As String) As Boolean
    Dim hVol As LongPtr
    Dim r As Long
    Dim tSHI As STORAGE_HOTPLUG_INFO

    hVol = CreateFileW(StrPtr("\\.\" & DrvLetter & ":"), 0, FILE_SHARE_READ, vbNullPtr, OPEN_EXISTING, 0&, ByVal 0&)
    If hVol <> INVALID_HANDLE_VALUE Then
        Call DeviceIoControl(hVol, IOCTL_STORAGE_GET_HOTPLUG_INFO, ByVal 0&, 0&, tSHI, LenB(tSHI), r, vbNullPtr)
        IsTrueRemovable = (tSHI.MediaRemovable + tSHI.DeviceHotplug > 0)
        CloseHandle hVol
    Else
        Debug.Print "Couldn't open drive " & DrvLetter & " for hotplug info."
    End If
End Function

Private Function LPWSTRtoStr(lPtr As LongPtr, Optional ByVal fFree As Boolean = True) As String
    SysReAllocStringW VarPtr(LPWSTRtoStr), lPtr
    If fFree Then
    Call CoTaskMemFree(lPtr)
    End If
End Function
Private Sub DEFINE_UUID(Name As UUID, L As Long, w1 As Integer, w2 As Integer, B0 As Byte, b1 As Byte, b2 As Byte, B3 As Byte, b4 As Byte, b5 As Byte, b6 As Byte, b7 As Byte)
    With Name
    .Data1 = L: .Data2 = w1: .Data3 = w2: .Data4(0) = B0: .Data4(1) = b1: .Data4(2) = b2: .Data4(3) = B3: .Data4(4) = b4: .Data4(5) = b5: .Data4(6) = b6: .Data4(7) = b7
    End With
End Sub
Private Function GUID_DEVINTERFACE_VOLUME() As UUID
    Static iid As UUID
    If (iid.Data1 = 0) Then Call DEFINE_UUID(iid, &H53F5630D, &HB6BF, &H11D0, &H94, &HF2, &H0, &HA0, &HC9, &H1E, &HFB, &H8B)
    GUID_DEVINTERFACE_VOLUME = iid
End Function

Private Function Subclass2(hWnd As LongPtr, lpFN As LongPtr, Optional uId As LongPtr = 0&, Optional dwRefData As LongPtr = 0&) As Boolean
    If uId = 0 Then uId = hWnd
    Subclass2 = SetWindowSubclass(hWnd, lpFN, uId, dwRefData):      Debug.Assert Subclass2
End Function

Private Function UnSubclass2(hWnd As LongPtr, ByVal lpFN As LongPtr, pid As LongPtr) As Boolean
    UnSubclass2 = RemoveWindowSubclass(hWnd, lpFN, pid)
End Function
Private Function PtrCbWndProc() As LongPtr
    PtrCbWndProc = FARPROC(AddressOf ucDriveComboWndProc)
End Function
Private Function FARPROC(ByVal pfn As LongPtr) As LongPtr
    FARPROC = pfn
End Function
Private Function HiWord(ByVal DWord As Long) As Integer
    HiWord = (DWord And &HFFFF0000) \ &H10000
End Function
#If TWINBASIC Then
Public Function zzCBWndProc(ByVal hWnd As LongPtr, ByVal uMsg As Long, ByVal wParam As LongPtr, ByVal lParam As LongPtr, ByVal uIdSubclass As LongPtr) As LongPtr
#Else
Public Function zzCBWndProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long, ByVal uIdSubclass As Long) As Long
#End If
    Select Case uMsg
        Case WM_NOTIFYFORMAT
        '   DebugAppend "Got NFMT on CBWndProc"
            zzCBWndProc = NFR_UNICODE
            Exit Function
            
        Case WM_DEVICECHANGE
            If (wParam = DBT_DEVICEARRIVAL) Or (wParam = DBT_DEVICEREMOVECOMPLETE) Then
                'We only registered for GUID_DEVINTERFACE_VOLUME so if we're here,
                'it's a volume add/remove, not other hardware.
                RefreshDriveList
            End If
            
        Case WM_COMMAND
            Dim lCode As Long
            lCode = HiWord(CLng(wParam))
            Select Case lCode
                Case CBN_SELCHANGE
                    Dim nIdx As Long
                    Dim nSel As Long
                    nSel = CLng(SendMessage(hMain, CB_GETCURSEL, 0, ByVal 0))
                    nIdx = -1
                    nIdx = CLng(GetCBXItemlParam(hMain, nSel))
                    RaiseEvent SelectionChanged(mDrives(nIdx).Path, mDrives(nIdx).Letter, mDrives(nIdx).Name, mDrives(nIdx).Type)
                Case CBN_DROPDOWN

                    RaiseEvent DriveListDropdown
            
                Case CBN_CLOSEUP
                    RaiseEvent DriveListCloseup
            End Select
        Case WM_DESTROY
            Call UnSubclass2(hWnd, PtrCbWndProc, uIdSubclass)
    End Select
    zzCBWndProc = DefSubclassProc(hWnd, uMsg, wParam, lParam)
    Exit Function
e0:
    Debug.Print "CBWndProc->Error: " & Err.Description & ", 0x" & Hex$(Err.Number)

End Function
