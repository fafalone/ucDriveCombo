VERSION 5.00
Begin VB.Form Form1 
   BorderStyle     =   1  'Fixed Single
   Caption         =   "ucDriveCombo Test Form"
   ClientHeight    =   3915
   ClientLeft      =   45
   ClientTop       =   390
   ClientWidth     =   4350
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   3915
   ScaleWidth      =   4350
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton Command3 
      Caption         =   "Refresh List"
      Height          =   615
      Left            =   1200
      TabIndex        =   4
      Top             =   3000
      Width           =   1935
   End
   Begin VB.CommandButton Command2 
      Caption         =   "Set Selection"
      Height          =   615
      Left            =   1200
      TabIndex        =   3
      Top             =   2280
      Width           =   1935
   End
   Begin VB.TextBox Text1 
      Height          =   285
      Left            =   1920
      MaxLength       =   1
      TabIndex        =   2
      Text            =   "D"
      Top             =   1920
      Width           =   375
   End
   Begin ucDriveComboTest.ucDriveCombo ucDriveCombo1 
      Height          =   315
      Left            =   360
      TabIndex        =   1
      Top             =   240
      Width           =   3735
      _ExtentX        =   6588
      _ExtentY        =   556
      ComboStyle      =   1
   End
   Begin VB.CommandButton Command1 
      Caption         =   "Show Path"
      Height          =   615
      Left            =   1200
      TabIndex        =   0
      Top             =   840
      Width           =   1935
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Sub Command1_Click()
    MsgBox "Current selection: " & ucDriveCombo1.SelectedDriveName
End Sub

Private Sub Command2_Click()
    ucDriveCombo1.SelectedDriveLetter = Text1.Text
End Sub

Private Sub Command3_Click()
    ucDriveCombo1.RefreshDriveList
End Sub
 

Private Sub ucDriveCombo1_SelectionChanged(ByVal NewPath As String, ByVal NewLetter As String, ByVal NewName As String, ByVal NewDriveType As Long)
    Debug.Print "Selected drive changed to " & NewPath
End Sub
