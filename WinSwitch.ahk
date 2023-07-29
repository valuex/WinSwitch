global AllWins
global LV
global InputStr
global TCMatchPath
global CurrentHwnd
TCMatchPath:=A_ScriptDir . "\tcmatch64.dll"


AllWins:=WinGetListAlt()
MyGui := Gui("+AlwaysOnTop")
MyGui.SetFont("s14", "Verdana")
MyGui.Opt("-Caption")
CurrentHwnd := MyGui.Hwnd
UserInput:=MyGui.AddEdit("w700")
UserInput.onevent("Change",UserInput_Change)
LV := MyGui.Add("ListView", "r20 w700 -Multi -Hdr", ["Process","WinTitle","HWND"])
LV.OnEvent("ItemFocus", Preview)
LV.OnEvent("Click", Preview)
; if(MyGui.hwnd)
; OnMessage(WM_ACTIVATE := 0x6, (wp, lp, msg, hwnd) => hwnd = MyGui.hwnd && !wp && MyGui.Hide())
OnMessage(WM_ACTIVATE := 0x0006, LoseFocus2Close)

OnMessage(WM_KEYDOWN := 0x100, KeyDown)

LoseFocus2Close(wParam, lParam, nmsg, CurrentHwnd)
{
; (wp, lp, msg, hwnd) => hwnd = MyGui.hwnd && !wp && MyGui.Hide()
; msgbox wParam
    if( CurrentHwnd && !wParam)
    {
        msgbox CurrentHwnd  " d " wParam
        WinClose("ahk_id " . CurrentHwnd)
    }
    return true

}

F1::
{
    UserInput.Value:=""
    ListWins(AllWins)
    LV.ModifyCol ; Auto-size each column to fit its contents.
    MyGui.Show("Center")
    ret := IME_CHECK("A")
    if (ret !=0)                  ; 0 :English
    {
        Send "{Shift}" 
    }
}


Return
F11::reload

IME_CHECK(WinTitle)
{
    hWnd := WinGetID(WinTitle)
    Return Send_ImeControl(ImmGetDefaultIMEWnd(hWnd),0x005,"")
}
Send_ImeControl(DefaultIMEWnd, wParam, lParam)
{
    DetectSave := A_DetectHiddenWindows       
    DetectHiddenWindows 1                            
    Result :=SendMessage( 0x283, wParam,lParam,,"ahk_id " . DefaultIMEWnd)
    if (DetectSave != A_DetectHiddenWindows)
        DetectHiddenWindows DetectSave
    return Result
}
 
ImmGetDefaultIMEWnd(hWnd)
{
    return DllCall("imm32\ImmGetDefaultIMEWnd", "Uint",hWnd, "Uint")
}

ListWins(ListW)
{
    global LV
    CountNumber := LV.GetCount()
    if (CountNumber>=1)
        LV.Delete
    WinNum:=ListW.Length
    ImageListID := IL_Create(WinNum) 
    LV.SetImageList(ImageListID)
    loop WinNum
    {
        WinHwnd:=ListW[A_Index]
        PrcsPath := WinGetProcessPath("ahk_id " . WinHwnd)
        PrcsName:=WinGetProcessName("ahk_id " . WinHwnd)
        WinTitle:=WinGetTitle("ahk_id " . WinHwnd)

        IL_Add(ImageListID, PrcsPath, 1) 
        LV.Add("Icon" . A_Index, PrcsName, WinTitle,WinHwnd)

    }
    ; loop WinNum
    ; {

    ;     WinHwnd:=ListW[A_Index]
    ;     PrcsName:=WinGetProcessName("ahk_id " . WinHwnd)
    ;     PrcsPath := WinGetProcessPath("ahk_id " . WinHwnd)
    ;     WinTitle:=WinGetTitle("ahk_id " . WinHwnd)

    ;     LV.Add("Icon" . A_Index, PrcsName, WinTitle,WinHwnd)
    ; }
    LV.Modify("1", "Select Focus")
}

FilteredWins()
{
    global AllWins
    global LV
    global InputStr
    global UserInput
    InputStr:=UserInput.Value
    if (InputStr="")
    {
        ListWins(AllWins) 
    }
    else if (instr(InputStr,"p ")=1)
    {
        prcs:="powerpnt.exe"
        TitleKw:=SubStr(InputStr, 3)
        FilteredWins:=FilterByPrcsAndTitle(prcs,TitleKw)
        ListWins(FilteredWins)
    }
    else if (instr(InputStr,"e ")=1)
    {
        prcs:="excel.exe"
        TitleKw:=SubStr(InputStr, 3)
        FilteredWins:=FilterByPrcsAndTitle(prcs,TitleKw)
        ListWins(FilteredWins)
    }
    else if (instr(InputStr,"f ")=1)
    {
        prcs:="explorer.exe"
        TitleKw:=SubStr(InputStr, 3)
        FilteredWins:=FilterByPrcsAndTitle(prcs,TitleKw)
        ListWins(FilteredWins)
    }
    Else
    {
        FilteredWins:=FilterHwndListByWinTitle(AllWins,InputStr)
        ListWins(FilteredWins)
    }
}

FilterByPrcsAndTitle(InPrcsName,InWinTitle)
{
FilteredPrcsWins:=FilterHwndListByPrcsName(InPrcsName)
FilteredTitleWins:=FilterHwndListByWinTitle(FilteredPrcsWins,InWinTitle)
Return FilteredTitleWins


}

FilterHwndListByPrcsName(InPrcsName)
{
    WinNum:=AllWins.Length
    List := []
    loop WinNum
    {
        WinHwnd:=AllWins[A_Index]
        ThisPrcsName:=WinGetProcessName("ahk_id " . WinHwnd)
        if(InStr(ThisPrcsName, InPrcsName))
        {
            List.Push(WinHwnd)            
        }          
    }
    Return List
}
FilterHwndListByWinTitle(WinList,InWinTitle)
{
    global AllWins
    global TCMatchPath
    WinNum:=WinList.Length
    List := []
    g_TCMatchModule := DllCall("LoadLibrary", "Str", TCMatchPath, "Ptr")

    loop WinNum
    {
        WinHwnd:=WinList[A_Index]
        ThisWinTitle:=WinGetTitle("ahk_id " . WinHwnd)
        TCMatched:=TCMatch(ThisWinTitle,InWinTitle)
        if(TCMatched)
        {
            List.Push(WinHwnd)            
        }          
    }
    DllCall("FreeLibrary", "Ptr", g_TCMatchModule)  ; free memory
    g_TCMatchModule := ""
    Return List
}


LV_Click(LV, RowNumber)
{
    Preview(LV, RowNumber)
}

LV_ItemFocus(LV, RowNumber)
{
    Preview(LV, RowNumber)
}
Preview(LV, RowNumber)
{
    global CurrentHwnd
    WinHwnd := LV.GetText(RowNumber,3)  ; Get the text from the row's first field.
    WinActivate("ahk_id " . WinHwnd)
    WinActivate("ahk_id " . CurrentHwnd)
}
UserInput_Change(*)
{
    FilteredWins()
}

TCMatch(aHaystack, aNeedle)
{
    if (A_PtrSize == 8)
    {
        return DllCall("TCMatch64\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
    }

    return DllCall("TCMatch\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
}
KeyDown(wParam, lParam, nmsg, CurrentHwnd) {
    global LV
    static VK_UP := 0x26
    static VK_DOWN := 0x28
    static VK_Enter := 0x0D
    static VK_ESC:=0x1B
    ; msgbox wParam
    gc := GuiCtrlFromHwnd(CurrentHwnd)
    if !(wParam = VK_UP || wParam = VK_DOWN || wParam=VK_Enter || wParam=VK_ESC)
        return
    if  gc is Gui.Edit 
    {
        ; press up & down in Eidt control to select item in listview
        PostMessage nmsg, wParam, lParam, LV
        return true
    }
    else if (wParam=VK_ESC)
    {
        WinClose()
    }
    else if ( gc is Gui.ListView and  wParam=VK_Enter )
    {
        ; press Enter in the ListView to activate corresponding window 
        RowNumber := 0  ; This causes the first loop iteration to start the search at the top of the list.
        Loop
        {
            RowNumber := LV.GetNext(RowNumber)  ; Resume the search at the row after that found by the previous iteration.
            if not RowNumber  ; The above returned zero, so there are no more selected rows.
                break
            WinHwnd := LV.GetText(RowNumber,3)
        }
        WinClose()
        WinActivate("ahk_id " . WinHwnd)
        return true
    }    
}
WinGetListAlt(params*) ;                       v0.21 by SKAN for ah2 on D51K/D51O @ autohotkey.com/r?t=99157
{
    Static S_OK := 0

    Local hModule := DllCall("Kernel32\LoadLibrary", "str","dwmapi", "ptr")
    , List := []
    , ExMin := 0
    , Style := 0
    , ExStyle := 0
    , hwnd := 0

    While params.Length > 4
        ExMin := params.pop()

    For , hwnd in WinGetList(params*)
        If IsVisible(hwnd)
        and StyledRight(hwnd)
    and NotMinimized(hwnd)
    and IsAltTabWindow(hwnd)
    List.Push(hwnd)

    DllCall("Kernel32\FreeLibrary", "ptr",hModule)
    Return List

    ;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    IsVisible(hwnd, Cloaked:=0)
    {
        If S_OK = 0
            S_OK := DllCall( "dwmapi\DwmGetWindowAttribute", "ptr",hwnd
        , "int", 14 ; DWMWA_CLOAKED
        , "uintp", &Cloaked
        , "int", 4 ; sizeof uint
        )

        Style := WinGetStyle(hwnd)
        Return (Style & 0x10000000) and not Cloaked ; WS_VISIBLE
    }

    StyledRight(hwnd) 
    {
        ExStyle := WinGetExStyle(hwnd)

        Return (ExStyle & 0x8000000) ? False ; WS_EX_NOACTIVATE
        : (ExStyle & 0x40000) ? True ; WS_EX_APPWINDOW
        : (ExStyle & 0x80) ? False ; WS_EX_TOOLWINDOW
        : True
    }

    NotMinimized(hwnd)
    {
        Return ExMin ? WinGetMinMax(hwnd) != -1 : True
    }

    IsAltTabWindow(Hwnd)
    {

        ExStyle := WinGetExStyle(hwnd)
        If ( ExStyle & 0x40000 ) ; WS_EX_APPWINDOW
            Return True

        While hwnd := DllCall("GetParent", "ptr",hwnd, "ptr")
        {
            If IsVisible(Hwnd)
                Return False

            ExStyle := WinGetExStyle(hwnd)

            If ( ExStyle & 0x80 ) ; WS_EX_TOOLWINDOW
                and not ( ExStyle & 0x40000 ) ; WS_EX_APPWINDOW
            Return False
        }

        Return !Hwnd
    }
} ; ________________________________________________________________________________________________________