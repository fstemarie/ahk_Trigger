#Requires AutoHotkey v2.0

Find_Center(&x, &y, w, h, monitor) {
    OutputDebug('-- ' A_ThisFunc '()`n')
    left := top := right := bottom := 0
    MonitorGet(monitor, &left, &top, &right, &bottom)
    x := Ceil(left + (right - left - w) / 2),
    y := Ceil(top + (bottom - top - h) / 2)
    return {x: x, y: y}
}

Get_CurrentMonitor() {
    OutputDebug('-- ' A_ThisFunc '()`n')
    left := top := right := bottom := mouseX := mouseY := 0
    CoordMode('Mouse', 'Screen')
    MouseGetPos(&mouseX, &mouseY)
    monCount := MonitorGetCount()
    mon := 1
    loop monCount
    {
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if ((left < mouseX) and (mouseX < right)
            and (top < mouseY) and (mouseY < bottom))
            mon := A_Index
    }
    return mon
}
