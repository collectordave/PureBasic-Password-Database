DeclareModule Password
  
  Declare.s Open()
  
EndDeclareModule

Module Password

Global MainPassword.s = "g9HpCKA1PwiJjihC6Zzz4Q==" ;Paste Result From PasswordEncryptor Here

Enumeration FormWindow
  #winPassword
EndEnumeration

Enumeration FormGadget
  #strPassword
  #txtPassword
  #btnOk
EndEnumeration

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

Procedure.s Open()
  
  Define Retval.s = ""
  Define CheckPassword.s
  
  OpenWindow(#winPassword, 0, 0, 310, 80, Locale::TranslatedString(97), #PB_Window_SystemMenu|#PB_Window_ScreenCentered)
  StringGadget(#strPassword, 170, 10, 130, 20, "", #PB_String_Password)
  TextGadget(#txtPassword, 10, 10, 150, 20, Locale::TranslatedString(98), #PB_Text_Right)
  ButtonGadget(#btnOk, 220, 40, 80, 30, Locale::TranslatedString(0))

  Repeat
  
    Event = WaitWindowEvent()
  
    Select Event
      
      Case #PB_Event_CloseWindow
        
        Quit = #True
        CloseWindow(#winPassword)

      Case #PB_Event_Gadget
        
        Select EventGadget()
          
          Case #btnOk
         
            CheckPassword = Encrypt(GetGadgetText(#strPassword), GetGadgetText(#strPassword))
            If CheckPassword = MainPassword 
              Quit = #True
              retVal = GetGadgetText(#strPassword)
              CloseWindow(#winPassword)
              
            Else
              Quit = #True
              MessageRequester(Locale::TranslatedString(97),"Incorrect Password",#PB_MessageRequester_Ok|#PB_MessageRequester_Error)
              retval = ""
              CloseWindow(#winPassword)            
            EndIf

        EndSelect
        
    EndSelect
   
  Until  Quit = #True
  
  ProcedureReturn Retval
  
EndProcedure

DataSection
  InitializationVector:
  Data.a $3d, $af, $ba, $42, $9d, $9e, $b4, $30, $b4, $22, $da, $80, $2c, $9f, $ac, $41
EndDataSection  
EndModule


; IDE Options = PureBasic 5.51 (Windows - x64)
; CursorPosition = 75
; FirstLine = 12
; Folding = 8
; EnableXP