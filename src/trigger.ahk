#Requires AutoHotkey v2.0

#include <config>
#include <shortcuts>
#include <picker>
#include <editors>
#include <password>
#include <corrections>

cfgFile := SubStr(A_ScriptFullPath, 1, -4) . '.ini'
cfg := Config.Load_Config(cfgFile)
shorts := Shortcuts.Load_CSV(cfg.csvFile) ; Loads the data from the CSV file
shorts.Setup_HotStrings()
edts := Editors()
view := Picker(shorts, cfg)
return

#HotIf A_IsCompiled
F1::
F1 UP::
#HotIf !A_IsCompiled
F2::
F2 UP::
Showup_HotKey(hk) {
    static skipUP := false
    ui := view
    FK := A_IsCompiled?'F1':'F2'
    FK_UP := A_IsCompiled?'F1 UP':'F2 UP'
    if (hk == FK) {
        skipUP := false
        SetTimer(longpress, -500)
        KeyWait(FK)
    }
    if (hk == FK_UP and !skipUP) {
        SetTimer(longpress, 0)
        OutputDebug('#### HotKey Pressed `n')
        if (WinExist('ahk_id' view.Hwnd)) 
            view.FollowMouse()
        else
            view.MakeItAppear()
    }

    longpress() {
        OutputDebug('#### HotKey Long Pressed `n')
        skipUP := true
        edts.Tile()
    }
}
