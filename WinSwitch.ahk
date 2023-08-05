Persistent
global AllWins
global LV
global FilterActivePrcs:=0
global APrcsName
global TCMatchPath
global CurrentHwnd
global IniConfigFile
global IsInPreviewStatus:=0
global ImageListID

TCMatchPath:=A_ScriptDir . "\tcmatch64.dll"
IniConfigFile:=A_ScriptDir . "\Config.ini"
TraySetIcon  "WinSwitch.png"  

AllWins:=WinGetListAlt()
; in case that some window is set topmost, do un-topmost first
UnTopMostAllWins(AllWins)
; +ToolWindow: no taskbar icon, so that when close one window use Ctrl+w, this window will not be listed
MyGui := Gui("+AlwaysOnTop +ToolWindow")
MyGui.SetFont("s14", "Verdana")
MyGui.Opt("-Caption")
CurrentHwnd := MyGui.Hwnd
CtlInput:=MyGui.AddEdit("w700")
CtlInput.OnEvent("Change",UserInput_Change)
LVS_SHOWSELALWAYS := 8 ; Seems to have the opposite effect with Explorer theme, at least on Windows 11.
LV_BGColor:=Format(' Background{:x}', DllCall("GetSysColor", "int", 15, "int"))  ; background color of listview item when get selected by up & down arrow
LV := MyGui.Add("ListView", "r20 w700 -Multi -Hdr " LVS_SHOWSELALWAYS LV_BGColor, ["Process","WinTitle","HWND"])
LV.OnEvent("ItemFocus", Preview)
LV.OnEvent("Click", Preview)
OnMessage(WM_ACTIVATE := 0x0006, LoseFocus2Close)

OnMessage(WM_KEYDOWN := 0x100, KeyDown)


F1::
{
    AllWins:=WinGetListAlt()
    CtlInput.Value:=""
    ListWins(AllWins)
    LV.ModifyCol ; Auto-size each column to fit its contents.
    MyGui.Show("Center")
    IME_To_EN(CurrentHwnd)
}
F3::
{
    global FilterActivePrcs 
    global  APrcsName
    FilterActivePrcs:=1
    APrcsName:= WinGetProcessName("A")
    CurWinID:=WinGetID("A")
    CtlInput.Value:=""
    WinList:=FilteredWins("",APrcsName)
    if(WinList.Length=1) 
        return
    else if(WinList.Length=2)  ;directly switch to the only other window with the same process as current one
        ActivateTheOtherWin(WinList,CurWinID)
    else
    {
        ListWins(WinList)
        LV.ModifyCol ; Auto-size each column to fit its contents.
        MyGui.Show("Center")
        IME_To_EN(CurrentHwnd)
    }
}

Return
F11::reload

ActivateTheOtherWin(WinList,ThisWinID)
{
    if(WinList[1]=ThisWinID)
        WinActivate("ahk_id " . WinList[2])
    else
        WinActivate("ahk_id " . WinList[1])
}
UnTopMostAllWins(AllWinIDs)
{
loop AllWinIDs.Length
    {
        win_id:= "ahk_id " . AllWinIDs[A_Index]
        WinSetAlwaysOnTop 0, win_id
        ; if WinActive(win_id)
        ;     msgbox WinGetProcessName(win_id)
    }
}
IME_To_EN(hwnd)
{    
    ; https://github.com/hui-Zz/RunAny/blob/master/RunPlugins/huiZz_InputEnCn.ahk
    dd:=DllCall("imm32\ImmGetDefaultIMEWnd","Uint",hwnd)
    DllCall("SendMessage","UInt",dd,"UInt",0x0283,"Int",0x002,"Int",0x00)
}
UserInput_Change(*)
{
    global CtlInput
    global FilterActivePrcs
    global APrcsName
    InputStr:=CtlInput.Value

    if(FilterActivePrcs)
    {
        WinList:=FilteredWins(InputStr,APrcsName)
    }
    else
        WinList:=FilteredWins(InputStr)
    ListWins(WinList)
    ; Preview(LV, "1")

}
ListWins(ListW)
{
    global LV
    global ImageListID
    CountNumber := LV.GetCount()
    if (CountNumber>=1)
    {
        LV.Delete
        Success := IL_Destroy(ImageListID)
    }
    WinNum:=ListW.Length
    ImageListID := IL_Create(WinNum) 
    LV.SetImageList(ImageListID)
    loop WinNum
    {
        WinHwnd:=ListW[A_Index]
        try
        {
            PrcsPath := WinGetProcessPath("ahk_id " . WinHwnd)
            PrcsName:=WinGetProcessName("ahk_id " . WinHwnd)
            WinTitle:=WinGetTitle("ahk_id " . WinHwnd)
            
            IL_Add(ImageListID, PrcsPath, 1) 
            LV.Add("Icon" . A_Index, PrcsName, WinTitle,WinHwnd)
        }

    }
    LV.Modify("1", "Select Focus")
}

FilteredWins(InputStr,FilterPrcs:="")
{
    global AllWins
    global LV

    if (InputStr="" and FilterPrcs="")
    {
        return AllWins
    }
    else if (FilterPrcs!="")
    {
        TitleKw:=InputStr
        FilteredWins:=FilterByTileAndPrcs(TitleKw,FilterPrcs)
        return FilteredWins
    }
    Else
    {
        ; check whether pre-defined key words exist
        FilteredWins:=FilterByPrcsShortName(InputStr)
        if(FilteredWins.Length<1)
        {
            ; if pre-defined key words do NOT exist, search in Title
            FilteredWins:=FilterHwndListByWinTitle(AllWins,InputStr)
        }
        return FilteredWins
    }
}
FilterByPrcsShortName(InputStr)
{
    global IniConfigFile
    ; check whether pre-defined key words exist
    Spliter := IniRead(IniConfigFile, "config","Spliter"," ")
    KeyList := IniRead(IniConfigFile, "ProcessShortName")
    KeyListArr := StrSplit(KeyList,"`n","`r")
    loop KeyListArr.Length
    {
        ThisItem:= KeyListArr[A_Index]
        EqualPos:=InStr(ThisItem,"=")
        PrcsShortName:=Trim(SubStr(ThisItem,1,EqualPos-1))
        PrcsFullName:=Trim(SubStr(ThisItem,EqualPos+1))
        IndexKw:=PrcsShortName . Spliter
        if (instr(InputStr,IndexKw)=1)
        {
            TitleKw:=SubStr(InputStr, 3)
            FilteredWins:=FilterByTileAndPrcs(TitleKw,PrcsFullName)
            return FilteredWins
        }
    }
    return []
}

FilterByTileAndPrcs(InWinTitle,InPrcsName)
{
    FilteredPrcsWins:=FilterHwndListByPrcsName(InPrcsName)
    if(InWinTitle!="")
    {
        FilteredTitleWins:=FilterHwndListByWinTitle(FilteredPrcsWins,InWinTitle)
        Return FilteredTitleWins
    }
    Return FilteredPrcsWins
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
    ; filter title by Pinyin first letters
    global AllWins
    global TCMatchPath
    WinNum:=WinList.Length
    List := []
    g_TCMatchModule := DllCall("LoadLibrary", "Str", TCMatchPath, "Ptr")

    loop WinNum
    {
        try
        {
            WinHwnd:=WinList[A_Index]
            ThisWinTitle:=WinGetTitle("ahk_id " . WinHwnd)
            TCMatched:=TCMatch(ThisWinTitle,InWinTitle)
            if(TCMatched)
            {
                List.Push(WinHwnd)            
            }   
        }       
    }
    DllCall("FreeLibrary", "Ptr", g_TCMatchModule)  ; free memory
    g_TCMatchModule := ""
    Return List
}
TCMatch(aHaystack, aNeedle)
{
    if (A_PtrSize == 8)
    {
        return DllCall("TCMatch64\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
    }

    return DllCall("TCMatch\MatchFileW", "WStr", aNeedle, "WStr", aHaystack)
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
    global IsInPreviewStatus
    WinHwnd := LV.GetText(RowNumber,3)  ; Get the text from the row's first field.
    IsInPreviewStatus:=1
    WinActivate("ahk_id " . WinHwnd)
    WinActivate("ahk_id " . CurrentHwnd)
    IsInPreviewStatus:=0
    ; WinShowBelow(WinHwnd, CurrentHwnd)
}
LoseFocus2Close(wParam, lParam, nmsg, hwnd)
{
    if (IsInPreviewStatus=1)
        return false
    if( hwnd && !wParam)
    {
        try
        {
            WinHide ("ahk_id " . hwnd)
            ; FileAppend( .  hwnd . "`n", "log.txt")

        }
    }
    return true
}
WinShowBelow(hWnd, hWndInsertAfter)
{
    ; https://www.autohotkey.com/boards/viewtopic.php?f=82&t=119842
    ; cons: not good enough for minimized window
    Local  SWP_NOACTIVATE := 0x10
        ,  SWP_NOMOVE     := 0x2
        ,  SWP_NOSIZE     := 0x1
    DllCall( "User32\SetWindowPos"
           , "ptr",  hWnd
           , "ptr",  hWndInsertAfter
           , "int",  0
           , "int",  0
           , "int",  0
           , "int",  0
           , "uint", SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE
           )
}
KeyDown(wParam, lParam, nmsg, Hwnd) {
    global CurrentHwnd
    global LV
    static VK_UP := 0x26
    static VK_DOWN := 0x28
    static VK_Enter := 0x0D
    static VK_ESC:=0x1B
    static VK_Ctrl:=0x11
    static VK_W:=0x57
    static VK_CtrlW:=0x1157
    gc := GuiCtrlFromHwnd(Hwnd)
    if !(wParam = VK_UP || wParam = VK_DOWN || wParam=VK_Enter || wParam=VK_ESC || wParam=VK_W) ;|| wParam=VK_Ctrl|| wParam=VK_W
        return
    if  (gc is Gui.Edit and (wParam = VK_UP || wParam = VK_DOWN ))
    {
        ; press up & down in Eidt control to select item in listview
        CurRowNumber := LV.GetNext()  ;get current selected row number
        LastRowNumber := LV.GetCount()
        if(CurRowNumber=1 and wParam = VK_UP)
            LV.Modify(LastRowNumber, "Select Focus")
        else if (CurRowNumber=LastRowNumber and wParam = VK_DOWN)
            LV.Modify("1", "Select Focus")
        else
            PostMessage nmsg, wParam, lParam, LV
        return true
    }
    else if (wParam=VK_ESC)
    {
        WinClose("ahk_id " . CurrentHwnd)
    }
    else if (wParam=VK_W and GetKeyState("Ctrl"))
    {
            CurRowNumber := LV.GetNext()  ;get current selected row number
            WinHwnd := LV.GetText(CurRowNumber,3)
            WinClose("ahk_id " . WinHwnd) 
            AllWins:=WinGetListAlt()
            ListWins(AllWins)
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