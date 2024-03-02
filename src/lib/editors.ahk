#Requires AutoHotkey v2.0

#include <tools>

Class Editors {
    Start() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        pid := ''
        Run('notepad.exe',,, &pid)
        WinWait('ahk_pid ' pid)
        GroupAdd('editors', 'ahk_pid ' pid)
        This.Tile()
    }

    Tile() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        mon := Get_CurrentMonitor()
        left := top := right := bottom := 0
        MonitorGet(mon, &left, &top, &right, &bottom)
        w := (right - left) * 0.25
        h := (bottom - top) * 0.75
        y := top + h * 0.25
        SetTitleMatchMode 2
        notepads := WinGetList('ahk_group editors')
        for i, id in notepads {
            x := left + w * (i - 1)
            WinActivate('ahk_id' id)
            WinMove(x, y, w, h, 'ahk_id ' id)
        }
    }
}