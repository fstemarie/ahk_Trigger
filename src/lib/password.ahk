#Requires AutoHotkey v2.0

#include <base64>

:*:###:: {
    static password := ''

    oldClip := ClipboardAll()
    if (!password) {
        cmd := A_ComSpec . ' /q /c D:\applications\KeePassCommander\'
            . 'KeePassCommand.exe getfield Citrix Password | clip'
        RunWait(cmd,, 'Hide')
        out := RegExReplace(A_Clipboard, '(\s+)|(\r\n)', ' ')
        password := Base64ToString(StrSplit(out, ' ')[8])
    }
    A_Clipboard := oldClip
    oldClip := ''
    Send('{Raw}' password)
}
