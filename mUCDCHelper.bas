Attribute VB_Name = "mUCDCHelper"
    Option Explicit
    #If TWINBASIC Then
    Public Function ucDriveComboWndProc(ByVal hWnd As LongPtr, ByVal uMsg As Long, ByVal wParam As LongPtr, ByVal lParam As LongPtr, ByVal uIdSubclass As LongPtr, ByVal dwRefData As ucDriveCombo) As LongPtr
        ucDriveComboWndProc = dwRefData.zzCBWndProc(hWnd, uMsg, wParam, lParam, uIdSubclass)
    End Function
    #Else
    Public Function ucDriveComboWndProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long, ByVal uIdSubclass As Long, ByVal dwRefData As ucDriveCombo) As Long
        ucDriveComboWndProc = dwRefData.zzCBWndProc(hWnd, uMsg, wParam, lParam, uIdSubclass)
    End Function
    #End If
