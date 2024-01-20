#Requires AutoHotkey v2.0

SCR := 'trigger.exe'
SCRFULL := A_ScriptDir . SCR
NEW := 'trigger-new.exe'

WinWaitClose('ahk_exe ' SCR)
if (FileExist(NEW)) {
    FileDelete(SCR)
    FileMove(NEW, SCR)
    Run(SCR)
}
ExitApp()
