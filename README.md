# ucDriveCombo v1.5 (Updated 27 Apr 2024)
Modernized DriveList control replacement

![image](https://github.com/fafalone/ucDriveCombo/assets/7834493/ce6113be-5546-4afd-8956-dca8b049d1c7)

**Files**

* TestUCDC.twinproj - twinBASIC Test Form project
* ucDriveComboTest.vbp - VB6 Test Form project
* ucDriveComboPackage.twinpack - twinBASIC Package version of control
* ucDriveComboPackage.twinproj - Package build configuration project
* ucDriveComboControl.twinproj - twinBASIC Active-X Control  (OCX) build config
* ucDriveCombo.ctl/ucDriveCombo.ctx/mUCDCHelper.bas - VB6 UserControl files (add these three to your projects using it)
* ucDriveCombo.twin - Browsable source code export from twinBASIC

```
'********************************************************************
' ucDriveCombo v1.5
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
'  Version 1.5 (Released 27 Apr 2024)
'   -(Bug fix) NoFixedUSB option not working
'   -(Bug fix) Drive type always reported as 0
'
'  Version 1.4 (Released 25 Apr 2024)
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
```
