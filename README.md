# ucDriveCombo
Modernized DriveList control replacement

![image](https://github.com/fafalone/ucDriveCombo/assets/7834493/ce6113be-5546-4afd-8956-dca8b049d1c7)

```
'********************************************************************
' ucDriveCombo v1.0
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
'  Version 1.0 (Released 22 Apr 2024)
'   -Add Property Lets for SelectedDrive_____
'   -Add device add/remove monitoring via RegisterDeviceNotification
'   -Add DPI aware support
'   -Add DropdownWidth option
'
'********************************************************************
```
