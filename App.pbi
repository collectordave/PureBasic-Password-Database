UsePNGImageDecoder() 

DeclareModule App
  
;All OS's
Macro FileExists(filename)
  Bool(FileSize(fileName) > -1)
EndMacro

;Application Variables For Preferences
Global Title.s = "Password Database"
Global Version.s = "1.0.0"
Global Author.s = "collectordave"
Global ProgramLanguage.s = "Pure Basic 5.51"
Global Language.s

Global PasswordDB.i

Global PPmm.i
    
  ;Constants for Flags
  #OkOnly = 1
  #OkCancel = 2
  #YesNo = 4
  #YesNoCancel = 8
  #InformationIcon = 16
  #WarningIcon = 32
  #StopIcon = 64
  
  ;Constants for return values
  #MsgOk = 1
  #MsgYes = 2
  #MsgNo = 3
  #MsgCancel = 4
  
  DataSection
  Info: 
  IncludeBinary "information.png"  ;Add your own image
  Warn:
  IncludeBinary "warning.png"      ;Add your own image
  Stop:
  IncludeBinary "stop.png"         ;Add your own image
  EndDataSection
  
  ;OS Specific details
  CompilerSelect #PB_Compiler_OS
    
    CompilerCase   #PB_OS_MacOS
        
      #DefaultFolder = "/Volumes" ;For explorertreegadget etc
      #Pathsep = "/"
      
    CompilerCase   #PB_OS_Linux 
      
       #DefaultFolder = "/"       ;For explorertreegadget etc    
       #Pathsep = "/"
       
    CompilerCase   #PB_OS_Windows

      #DefaultFolder = "C:\"      ;For explorertreegadget etc
      #Pathsep = "\"
      
  CompilerEndSelect
  
  ;App Global procedures
  Declare ReadPreferences(AppName.s)
  Declare Writepreferences(AppName.s)
  Declare.s Getlocale()
  Declare.i Message(Title.s,Msg.s,Flags.i)
  Declare.s NumberToMonth(SelMonth.i) 
  Declare CheckCreatePath(Directory.s)
  
EndDeclareModule

Module App
  
  Procedure CheckCreatePath(Directory.s)

    BackSlashs = CountString(Directory, "\")
 
    Path$ = ""
    For i = 1 To BackSlashs + 1
      Temp$ = StringField(Directory.s, i, "\")
      If StringField(Directory.s, i+1, "\") > ""
        Path$ + Temp$ + "\"
      Else
        path$ + temp$
      EndIf
      CreateDirectory(Path$)
    Next i
  
  EndProcedure 
  
Procedure.i AutoSize(gadgetNo)
  Shared alignFlag
  gadgetWt = GadgetWidth(gadgetNo)
  gadgetHt = GadgetHeight(gadgetNo, #PB_Gadget_RequiredSize)
  gadgetText.s = (ReplaceString(Trim(GetGadgetText(gadgetNo)), "  ", " ")) + " "
  tempGadget = TextGadget(#PB_Any, -1000, -1000, gadgetWt, gadgetHt, "", alignFlag)
  SetGadgetFont(tempGadget, GetGadgetFont(gadgetNo))
  HideGadget(tempGadget, 1)
  For textIndex = 1 To CountString(gadgetText, " ")
    If alignFlag = #PB_Text_Right
      SetGadgetText(tempGadget, " " + StringField(gadgetText, textIndex, " "))
    Else
      SetGadgetText(tempGadget, StringField(gadgetText, textIndex, " "))
    EndIf
    textIndexWidth = GadgetWidth(tempGadget, #PB_Gadget_RequiredSize)
    If textIndexWidth > gadgetWt
      gadgetWt = textIndexWidth
      expanded = 1
    EndIf
  Next textIndex
 
  If Not expanded
    textIndexWidth = 0
    For textIndex = 1 To CountString(gadgetText, " ")
      SetGadgetText(tempGadget, spacer$ + StringField(gadgetText, textIndex, " "))
      currentStringWidth = GadgetWidth(tempGadget, #PB_Gadget_RequiredSize) - 2
      textIndexWidth + currentStringWidth
      If textIndexWidth => gadgetWt
        If textIndexWidth - currentStringWidth > maxWidth
          maxWidth = textIndexWidth - currentStringWidth
        EndIf
        If textIndexWidth > gadgetWt
          spacer$ = " "
        Else
          spacer$ = ""
        EndIf       
        If alignFlag = #PB_Text_Right
          SetGadgetText(tempGadget, " " + StringField(gadgetText, textIndex, " "))
        Else
          SetGadgetText(tempGadget, StringField(gadgetText, textIndex, " "))
        EndIf     
        textIndexWidth = GadgetWidth(tempGadget, #PB_Gadget_RequiredSize) - 2
      Else
        spacer$ = " "
      EndIf 
    Next textIndex
   
    If textIndexWidth > maxWidth
      maxWidth = textIndexWidth
    EndIf   
   
    If maxWidth
      gadgetWt = maxWidth + 2
    EndIf
  EndIf
 
  spacer$ = ""
  textIndexWidth = 0
 
  For textIndex = 1 To CountString(gadgetText, " ")
    SetGadgetText(tempGadget, spacer$ + StringField(gadgetText, textIndex, " "))
    textIndexWidth + GadgetWidth(tempGadget, #PB_Gadget_RequiredSize) - 2
    If textIndexWidth => gadgetWt
      If textIndexWidth > gadgetWt
        spacer$ = " "
      Else
        spacer$ = ""
      EndIf
      If textIndex = CountString(gadgetText, " ")
        lines + 2
      Else
        lines + 1
      EndIf
      If alignFlag = #PB_Text_Right
        spacer$ = " "
        SetGadgetText(tempGadget, " " + StringField(gadgetText, textIndex, " "))
      Else
        SetGadgetText(tempGadget, StringField(gadgetText, textIndex, " "))
      EndIf
      If textIndexWidth > gadgetWt
        textIndexWidth = GadgetWidth(tempGadget, #PB_Gadget_RequiredSize) - 2
      Else
        textIndexWidth = 0
      EndIf
    Else
      spacer$ = " "
      If textIndex = CountString(gadgetText, " ")
        lines + 1
      EndIf
    EndIf
  Next textIndex

  ResizeGadget(gadgetNo, #PB_Ignore, #PB_Ignore, gadgetWt, gadgetHt)
  SetGadgetText(gadgetNo, Trim(gadgetText))
  FreeGadget(tempGadget)
  ProcedureReturn gadgetHt
  
EndProcedure

Procedure.s Getlocale()
  
  Define Lang.s
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  Define Buffer$, buflen, bytesread, LC
  LC = #LOCALE_SLANGUAGE
  buflen = GetLocaleInfo_(#LOCALE_USER_DEFAULT, LC, @Buffer$, 0)    ;MS recommends using GetLocaleInfoEx_() if only supporting Vista and later
  Buffer$ = Space(buflen)
  bytesread = GetLocaleInfo_(#LOCALE_USER_DEFAULT, LC, @Buffer$, buflen)
  If bytesread = 0
    Lang = "English"
  Else
    Lang = Trim(Left(Buffer$,FindString(Buffer$,"(") - 1 ))
  EndIf
  
CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux  ;(on #PB_OS_MacOS it also works but tends to only return default of "C")
  
  #LC_CTYPE = 0
  #LC_NUMERIC = 1
  #LC_TIME = 2
  #LC_COLLATE = 3
  #LC_MONETARY = 4
  #LC_MESSAGES = 5
  #LC_ALL = 6
  #LC_PAPER = 7
  #LC_NAME = 8
  #LC_ADDRESS = 9
  #LC_TELEPHONE = 10
  #LC_MEASUREMENT = 11
  #LC_IDENTIFICATION = 12
 
  lcaddr.i = setlocale_(#LC_CTYPE, #Null)  ;If the last paramter is Null the function works as GETlocale
  If lcaddr
    Lang = Trim(Left(Buffer$,FindString(Buffer$,"(") - 1 ))
  Else
    Lang = Locale::TranslatedString(91)
  EndIf 
  
CompilerElseIf #PB_Compiler_OS = #PB_OS_MacOS   ;thanks to mk-soft. Tends to return the full locale, as opposed to just default of "C"
  CurrentLocale = CocoaMessage(0, 0, "NSLocale currentLocale")
  LocaleIdentifer = CocoaMessage(0, CurrentLocale, "localeIdentifier")
  CocoaMessage(@Language, LocaleIdentifer, "UTF8String")
  Lang = PeekS(Language, -1, #PB_UTF8)
  
CompilerEndIf

ProcedureReturn Lang

EndProcedure

  Procedure.i Message(Title.s,Msg.s,Flags.i)
  
    Define This_Window.i,btn1,btn2,btn3,txtMsg,RetVal,IconImage,Testimg
    
    Define gHeight.i
    
    LoadFont(0, "Arial", 12)
    
    This_Window = OpenWindow(#PB_Any, 0, 0, 400, 400, Title,  #PB_Window_Tool | #PB_Window_ScreenCentered)
    
    ;Add the main message text
    txtMsg = TextGadget(#PB_Any, 5, 10, 390, 20, Msg)
    SetGadgetFont(txtMsg, FontID(0))
    gHeight = AutoSize(txtMsg) + 10
    
    ;Add the message image
    IconImage = ImageGadget(#PB_Any, 10, gHeight + 10, 50, 50, 0)
    If Flags & #InformationIcon > 0
      CatchImage(0, ?Info)
      If IsImage(0)
        SetGadgetState(IconImage,ImageID(0)) 
      EndIf
    EndIf
    If Flags & #WarningIcon > 0
      CatchImage(Testimg, ?Warn)
      SetGadgetState(IconImage,ImageID(0))    
    EndIf  
    If Flags & #StopIcon > 0
      CatchImage(0, ?Stop)
      SetGadgetState(IconImage,ImageID(0))   
    EndIf    
    
    ;Add the buttons
    If Flags & #YesNoCancel > 0
      btn1 = ButtonGadget(#PB_Any, 130, gHeight + 10, 80, 30, Locale::TranslatedString(1))
      btn2 = ButtonGadget(#PB_Any, 220, gHeight + 10, 80, 30, Locale::TranslatedString(2))
      btn3 = ButtonGadget(#PB_Any, 310, gHeight + 10, 80, 30, Locale::TranslatedString(3))
    ElseIf   Flags & #OkCancel > 0
      btn2 = ButtonGadget(#PB_Any, 220, gHeight + 10, 80, 30, Locale::TranslatedString(0))
      btn3 = ButtonGadget(#PB_Any, 310, gHeight + 10, 80, 30, Locale::TranslatedString(3))
    ElseIf   Flags & #YesNo > 0
      btn2 = ButtonGadget(#PB_Any, 220, gHeight + 10, 80, 30, Locale::TranslatedString(1))
      btn3 = ButtonGadget(#PB_Any, 310, gHeight + 10, 80, 30, Locale::TranslatedString(2))
    Else
      btn3 = ButtonGadget(#PB_Any, 310, gHeight + 10, 80, 30, Locale::TranslatedString(0))
    EndIf
    
   ResizeWindow(This_Window, #PB_Ignore, #PB_Ignore,  #PB_Ignore,gHeight + 50)

    ;Make sure it stays on top
    StickyWindow(This_Window,#True)
    
    ;Start of message handling loop
    ;Not to be mixed up with the main application loop
    ;Allways include code to close this window!
    Repeat
      Event = WaitWindowEvent()
      
      Select EventWindow()
        
        Case This_Window ;Messages for this window only all others discarded

          Select Event
           
            Case #PB_Event_Gadget
            
              Select EventGadget()
                  
                ;Each button has a different meaning depending on
                ;the type of message box
                  
                Case btn1
                  If Flags&#YesNoCancel > 0
                    RetVal = #MsgYes
                  EndIf 
                  CloseWindow(This_Window)
                  
                Case btn2
                  If Flags&#YesNoCancel > 0 
                    RetVal = #MsgNo
                  ElseIf Flags&#YesNo > 0
                    RetVal = #MsgYes  
                  ElseIf Flags&#OkCancel > 0
                    RetVal = #MsgOk                   
                  EndIf
                  CloseWindow(This_Window)
                  
                Case btn3
                  If Flags&#YesNoCancel > 0 Or Flags&#OkCancel > 0
                    RetVal = #MsgCancel
                  ElseIf Flags&#YesNo > 0
                    RetVal = #MsgNo 
                  Else
                    RetVal = #MsgOk
                  EndIf
                  CloseWindow(This_Window)
                
              EndSelect ;Eventgadget
            
          EndSelect ;Event
  
    EndSelect ;Eventwindow
    
  Until Not IsWindow(This_Window)
  
  ProcedureReturn RetVal
  
EndProcedure

  Procedure ReadPreferences(AppName.s)
  
    OpenPreferences(GetCurrentDirectory() + AppName + ".INI")

    PreferenceGroup("Global")
  
    App::Language =  ReadPreferenceString("Language", "English")
    App::Title =  ReadPreferenceString("Title","Password database")   
    App::Version =  ReadPreferenceString("Version","1.0.0")
    App::Author =  ReadPreferenceString("Author","collectordave")   
    App::ProgramLanguage =  ReadPreferenceString("ProgramLanguage","Pure Basic 5.5")     
    ClosePreferences()

  EndProcedure

  Procedure Writepreferences(AppName.s)
  
    If CreatePreferences(GetCurrentDirectory() + AppName + ".INI")
  
      PreferenceGroup("Global")
  
      WritePreferenceString("Language", App::Language)
      WritePreferenceString("Title", App::Title)   
      WritePreferenceString("Version", App::Version)
      WritePreferenceString("Author", App::Author)   
      WritePreferenceString("ProgramLanguage", App::ProgramLanguage)   
      ClosePreferences()
  
    EndIf

  EndProcedure

  Procedure.s NumberToMonth(SelMonth.i)
   
    Define RetVal.s
  
    Select SelMonth

      Case 1
        RetVal = Locale::TranslatedString(85)
      Case 2
        RetVal = Locale::TranslatedString(86)
      Case 3
        RetVal = Locale::TranslatedString(87)
      Case 4
        RetVal = Locale::TranslatedString(88)
      Case 5
        RetVal = Locale::TranslatedString(89)
      Case 6
        RetVal = Locale::TranslatedString(90)
      Case 7
        RetVal = Locale::TranslatedString(91)
      Case 8
        RetVal = Locale::TranslatedString(92)
      Case 9
        RetVal = Locale::TranslatedString(93)
      Case 10
        RetVal = Locale::TranslatedString(94)
      Case 11
        RetVal = Locale::TranslatedString(95)
      Case 12
        RetVal = Locale::TranslatedString(96)
        
    EndSelect
    
   ProcedureReturn RetVal
      
  EndProcedure
    
EndModule

; IDE Options = PureBasic 5.51 (Windows - x64)
; CursorPosition = 372
; FirstLine = 198
; Folding = Fu
; EnableXP
; EnableUnicode