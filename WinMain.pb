EnableExplicit

;Using Statements
UsePNGImageDecoder()
UseJPEGImageDecoder()
UseSQLiteDatabase()

;Include Files
IncludeFile "Locale.pbi"
IncludeFile "App.pbi"
IncludeFile "DCTool.pbi"
IncludeFile "dlgPassword.pbi"

;Get Applcation variables
App::ReadPreferences("PasswordDB")

If Not App::FileExists(GetCurrentDirectory() + "PasswordDB")
  App::Writepreferences("PasswordDB") 
EndIf
APP::ReadPreferences("PasswordDB")

;Select Language For This Programme If Not set
If App::Language = ""
  Locale::AppLanguage = "English" ;Default
  Locale::Initialise()
  Locale::SelectLanguage()
  App::Language = Locale::AppLanguage
  App::Writepreferences("PasswordDB")  
Else
  Locale::AppLanguage = App::Language
EndIf
Locale::Initialise()

;Main Menu Enumeration
Enumeration MainForm
  #WinMain
  #txtService
  #txtPassword
  #txtUserName
  #strService
  #strPassword
  #strUserName
  #btnFirst
  #imgFirst
  #btnPrevious
  #imgPrevious
  #btnNext
  #imgNext
  #txtStatus
  #btnLast
  #imgLast
  #imgAdd
  #imgDelete
  #imgExit
  #imgHelp
  #imgOk
  #Idle
  #Add
EndEnumeration

;Global Variables
Global IconBar.i,LangImage.i

;Database Variables
Global CurrentRow.i,TotalRows.i,CurrentID.i

Global MainPassword.s = ""


;local variables
Define Event.i,TempCriteria.s

CurrentRow = 1

LangImage = Locale::GetImageFromDB(App::Language)

MainPassword = Password::Open()
If Len(MainPassword) = 0
  End
EndIf

Procedure ShowFormTexts()
  
  ;Window Title
  SetWindowTitle(#WinMain,Locale::TranslatedString(97))
  
  ;Iconbar
  SetIconBarGadgetItemText(IconBar,Locale::TranslatedString(101),0,#IconBarText_ToolTip)
  SetIconBarGadgetItemText(IconBar,Locale::TranslatedString(102),1,#IconBarText_ToolTip)
  SetIconBarGadgetItemText(IconBar,Locale::TranslatedString(21),2,#IconBarText_ToolTip)
  SetIconBarGadgetItemText(IconBar,Locale::TranslatedString(16),3,#IconBarText_ToolTip) 
  SetIconBarGadgetItemText(IconBar,Locale::TranslatedString(107),4,#IconBarText_ToolTip)
  SetIconBarGadgetItemText(IconBar,Locale::TranslatedString(58),5,#IconBarText_ToolTip) 
  
  ;Gadgets
  SetGadgetText(#txtService,Locale::TranslatedString(103))
  SetGadgetText(#txtUserName,Locale::TranslatedString(106))
  SetGadgetText(#txtPassword,Locale::TranslatedString(104))

EndProcedure

Procedure ClearGadgets()
  
  SetGadgetText(#strService,"")
  SetGadgetText(#strPassword,"") 
  
EndProcedure

Procedure.s Encrypt(text$, password$)
 
  Protected.i Length, Size64
  Protected *KeyAES, *InAES, *outAES, *out64
  Protected e$
  
  *KeyAES = AllocateMemory(32)
  If *KeyAES
    If StringByteLength(password$, #PB_UTF8) <= 32
      PokeS(*KeyAES, password$, -1, #PB_UTF8|#PB_String_NoZero)
     
      Length = StringByteLength(text$, #PB_UTF8) + 1
      If Length < 16
        Length = 16
      EndIf
     
      *InAES = AllocateMemory(Length)
      If *InAES
        PokeS(*InAES, text$, -1, #PB_UTF8)
     
        *outAES = AllocateMemory(Length)
        If *outAES
          If AESEncoder(*inAES, *outAES, Length, *KeyAES, 256, ?InitializationVector)
           
            Size64 = Length * 1.35
            If Size64 < 64
              Size64 = 64
            EndIf
            *out64 = AllocateMemory(Size64)
            If *out64
              Size64 = Base64Encoder(*outAES, Length, *out64, Size64)
              If Size64
                e$ = PeekS(*out64, Size64, #PB_Ascii)
              EndIf
              FreeMemory(*out64)
            EndIf
           
          EndIf
          FreeMemory(*outAES)
        EndIf
        FreeMemory(*InAES)
      EndIf
    EndIf
    FreeMemory(*KeyAES)
  EndIf
 
  ProcedureReturn e$
  
EndProcedure

Procedure.s Decrypt(text$, password$)
 
  Protected.i Length
  Protected *KeyAES, *in64, *out64, *outAES
  Protected d$
 
 
  *KeyAES = AllocateMemory(32)
  If *KeyAES
    If StringByteLength(password$, #PB_UTF8) <= 32
      PokeS(*KeyAES, password$, -1, #PB_UTF8|#PB_String_NoZero)
      *in64 = AllocateMemory(StringByteLength(text$, #PB_Ascii))
      If *in64
       
        PokeS(*in64, text$, -1, #PB_Ascii|#PB_String_NoZero)
       
        *out64 = AllocateMemory(MemorySize(*in64))
        If *out64
          Length = Base64Decoder(*in64, MemorySize(*in64), *out64, MemorySize(*out64))

          *outAES = AllocateMemory(Length)
          If *outAES
            If AESDecoder(*out64, *outAES, Length, *KeyAES, 256, ?InitializationVector)
              d$ = PeekS(*outAES, Length, #PB_UTF8)
            EndIf
            FreeMemory(*outAES)
          EndIf
          FreeMemory(*out64)
        EndIf
        FreeMemory(*in64)
      EndIf
    EndIf
    FreeMemory(*KeyAES)
  EndIf
 
  ProcedureReturn d$
 
EndProcedure

Procedure CheckRecords()
  
  ;Sort out the navigation buttons
  If TotalRows < 2
    
    ;Only one record so it is the first and the last
    DisableGadget(#btnLast, #True)     ;No move last as allready there
    DisableGadget(#btnNext, #True)     ;No next record as this is the last record
    DisableGadget(#btnFirst, #True)    ;No first record as this is the first record
    DisableGadget(#btnPrevious, #True) ;No previous record as this is the first record
    
  ElseIf CurrentRow = 1
    ;On the first row with more than one selected
    DisableGadget(#btnLast, 0)     ;Can move to last record
    DisableGadget(#btnNext, 0)     ;Can move to next record
    DisableGadget(#btnFirst, #True)    ;No first record as this is the first record
    DisableGadget(#btnPrevious, #True) ;No previous record as this is the first record
    
  ElseIf  CurrentRow = TotalRows
    
    ;If on the last record
    DisableGadget(#btnLast, #True)     ;No move last as allready there
    DisableGadget(#btnNext, #True)     ;No next record as this is the last record
    DisableGadget(#btnFirst, 0)    ;Can still move to first record
    DisableGadget(#btnPrevious, 0) ;Can still move to previous record
    
  Else
    
    ;Somewhere in the middle of the selected records
    DisableGadget(#btnLast, 0)     ;Can move to last record
    DisableGadget(#btnNext, 0)     ;Can move to next record
    DisableGadget(#btnFirst, 0)    ;Can move to first record
    DisableGadget(#btnPrevious, 0) ;Can move to previous record
    
  EndIf

EndProcedure

Procedure GetTotalRecords()

  Define SearchString.s
  
  ;Find out how many records will be returned
  TotalRows = 0
  SearchString = "SELECT * FROM Service;"
  
  If DatabaseQuery(App::PasswordDB, SearchString)
    
    While NextDatabaseRow(App::PasswordDB)

      TotalRows = TotalRows + 1
      
    Wend
    
    FinishDatabaseQuery(App::PasswordDB)  
    
  EndIf
  
EndProcedure

Procedure AddPassword()
  
  Define NewService.s,NewUserName.s,NewPassword.s,Criteria.s
  
  NewService = GetGadgetText(#strService)
  NewUserName = GetGadgetText(#strUserName) 
  NewPassword = Encrypt(GetGadgetText(#strPassword),MainPassword)
    
  Criteria = "INSERT INTO Service (PDBService,PDBUserName,PDBPassword) VALUES ('" + NewService + "','" + NewPassword + "');"
  DatabaseUpdate(App::PasswordDB, Criteria) 
  
EndProcedure

Procedure SavePassword()
  
  Define NewService.s,NewUserName.s,NewPassword.s,Criteria.s
  
  NewService = GetGadgetText(#strService)
  NewUserName = GetGadgetText(#strUserName) 
  NewPassword = Encrypt(GetGadgetText(#strPassword),MainPassword)
    
  Criteria = "UPDATE Service SET PDBService = '" + NewService + "',PDBPassword ='" + NewPassword + "' WHERE PDBID = " + Str(CurrentID) + ";"
  DatabaseUpdate(App::PasswordDB, Criteria) 
  
EndProcedure

Procedure DeletePassword()
       
  Define Criteria.s
    
  Criteria = "DELETE FROM Service WHERE PDBID = " + Str(CurrentID) + ";"
  DatabaseUpdate(App::PasswordDB, Criteria) 
    
EndProcedure

Procedure DisplayRecord()
  
  Define SearchString.s,Password.s
  
  SearchString = "SELECT * FROM Service ORDER BY PDBService ASC LIMIT 1 OFFSET " + Str(CurrentRow -1)

  DatabaseQuery(App::PasswordDB, SearchString)

  If FirstDatabaseRow(App::PasswordDB)
    CurrentID = GetDatabaseLong(App::PasswordDB, DatabaseColumnIndex(App::PasswordDB, "PDBID"))
    SetGadgetText(#strService,GetDatabaseString(App::PasswordDB, DatabaseColumnIndex(App::PasswordDB, "PDBService")))
    SetGadgetText(#strUserName,GetDatabaseString(App::PasswordDB, DatabaseColumnIndex(App::PasswordDB, "PDBUserName")))
    Password = GetDatabaseString(App::PasswordDB, DatabaseColumnIndex(App::PasswordDB, "PDBPassword"))
    Password = decrypt(Password,MainPassword)
    SetGadgetText(#strPassword,Password)
    FinishDatabaseQuery(App::PasswordDB)
  EndIf 
  
EndProcedure

CatchImage(#imgFirst,?First)
CatchImage(#imgPrevious,?Previous)
CatchImage(#imgNext,?Next)
CatchImage(#imgLast,?Last)
CatchImage(#imgAdd,?ToolBarAdd)
CatchImage(#imgDelete,?ToolBarDelete)
CatchImage(#imgExit,?ToolBarExit)
CatchImage(#imgHelp,?ToolBarHelp)
CatchImage(#imgOk,?ToolBarOk)

;Main Window
OpenWindow(#WinMain, 0, 0, 490, 145, "", #PB_Window_SystemMenu|#PB_Window_ScreenCentered)

IconBar = IconBarGadget(0, 0, WindowWidth(#WinMain),20,#IconBar_Default,#WinMain) 
AddIconBarGadgetItem(IconBar, "", #imgAdd)
AddIconBarGadgetItem(IconBar, "", #imgOk)
AddIconBarGadgetItem(IconBar, "", #imgDelete)
AddIconBarGadgetItem(IconBar, "", #imgExit)
IconBarGadgetSpacer(IconBar)
AddIconBarGadgetItem(IconBar, "", LangImage)
AddIconBarGadgetItem(IconBar, "", #imgHelp)
ResizeIconBarGadget(IconBar, #PB_Ignore, #IconBar_Auto)  
SetIconBarGadgetColor(IconBar, 1, RGB(176,224,230))
TextGadget(#txtService, 10, 50, 150, 20, "", #PB_Text_Center)
StringGadget(#strService, 10, 80, 150, 20, "")
TextGadget(#txtUserName, 170, 50, 150, 20, "", #PB_Text_Center)
StringGadget(#strUserName, 170, 80, 150, 20, "")
TextGadget(#txtPassword, 330, 50, 150, 20, "", #PB_Text_Center)
StringGadget(#strPassword, 330, 80, 150, 20, "")

;Navigation Buttons
ButtonImageGadget(#btnFirst, 0, 110, 32, 32, ImageID(#imgFirst))
ButtonImageGadget(#btnPrevious, 31, 110, 32, 32, ImageID(#imgPrevious))
ButtonImageGadget(#btnNext, 426, 110, 32, 32, ImageID(#imgNext))
ButtonImageGadget(#btnLast, 458, 110, 32, 32, ImageID(#imgLast))

;Move window to centre screen at the top
ResizeWindow(#WinMain,#PB_Ignore,5,#PB_Ignore,#PB_Ignore)

ShowFormTexts()

;Open The Password Database
App::PasswordDB = OpenDatabase(#PB_Any,"Passwords.db","","")
GetTotalrecords()
CheckRecords()
ClearGadgets()
DisplayRecord()

Repeat
  
  Event = WaitWindowEvent() 
  Select Event
      
    Case   #PB_Event_CloseWindow
      
      End
      
    Case #PB_Event_Gadget
        
      Select EventGadget()
            
        Case #btnFirst
          
          CurrentRow = 1
          CheckRecords()
          DisplayRecord()
            
        Case #btnPrevious
          
          If CurrentRow > 1
            CurrentRow = CurrentRow - 1
            CheckRecords()
            DisplayRecord()
          EndIf          
          
        Case #btnNext

          If CurrentRow < TotalRows
            CurrentRow = CurrentRow + 1
            CheckRecords()
            DisplayRecord()
          EndIf
          
        Case #btnLast
                    
          CurrentRow = TotalRows
          CheckRecords()
          DisplayRecord()
          
        Case IconBar ;Toolbar event
             
          Select EventData() ;For each button on toolbar
              
            Case 0
              
              AddPassword()
              ClearGadgets()
              GetTotalRecords()
              CheckRecords()
              DisplayRecord()
              
           Case 1
              
              SavePassword()
              ClearGadgets()
              GetTotalRecords()
              CheckRecords()
              DisplayRecord()
              
            Case 2
              
              DeletePassword()
              ClearGadgets()
              GetTotalRecords() 
              If CurrentRow > TotalRows
                CurrentRow = TotalRows
              EndIf
              CheckRecords()
              DisplayRecord()              
              
            Case 3

              End
              
            Case 4
              
              Locale::SelectLanguage()
              App::Language = Locale::AppLanguage
              App::Writepreferences("PasswordDB")         
              Locale::Initialise()
              ShowFormTexts()              
                
            Case 5
              
              ;Debug Locale::TranslatedString(58) Help
              
          EndSelect           
            
      EndSelect  
        
  EndSelect
  
ForEver  
  
DataSection
  First: 
    IncludeBinary "Resultset_first.png"
  Previous: 
    IncludeBinary "Resultset_previous.png"
  Next: 
    IncludeBinary "Resultset_next.png"
  Last: 
    IncludeBinary "Resultset_last.png"
  ToolBarAdd:
    IncludeBinary "Add.png" 
  ToolBarDelete:
    IncludeBinary "delete.png" 
  ToolBarExit:
    IncludeBinary "Exit.png"  
  ToolBarOk:
    IncludeBinary "Ok.png" 
  ToolBarCancel:
    IncludeBinary "Cancel.png"  
  ToolBarHelp:
    IncludeBinary "Help.png" 
  InitializationVector:
  Data.a $3d, $af, $ba, $42, $9d, $9e, $b4, $30, $b4, $22, $da, $80, $2c, $9f, $ac, $41
EndDataSection 
; IDE Options = PureBasic 5.51 (Windows - x64)
; CursorPosition = 8
; Folding = Bw
; EnableXP