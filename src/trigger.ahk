;@Ahk2Exe-SetName Trigger
;@Ahk2Exe-SetVersion 2.8
;@Ahk2Exe-SetMainIcon assets/trigger.ico

#Requires AutoHotkey v2.0
#SingleInstance Off

#include <config>
#include <shortcuts>
#include <picker>
#include <editors>
#include <password>
#include <corrections>

Self_Update()
Setup_Config()
Setup_Icon(cfg.icon)
Setup_CSV(cfg.csvFile)
edts := Editors()
view := Picker(shorts, cfg)
return

Self_Update() {
    static NEW := A_ScriptDir '\trigger-new.exe'
    static PS := Format('
    (
        $NEW = \"{}\"
        $SCR = \"{}\"

        Wait-Process -Id {} -TimeOut 5 -ErrorAction SilentlyContinue
        If (Test-Path -Path \"$NEW\") {
            Remove-Item \"$SCR\"
            Rename-Item \"$NEW\" \"$SCR\"
            & \"$SCR\"
        }
    )', NEW, A_ScriptFullPath, ProcessExist())
    if (!A_IsCompiled)
        return
    if (FileExist(NEW)) {
        Run('powershell.exe -Command &{' PS ' }',, 'hide')
        Sleep(1000)
        ExitApp()
    }
    SetTimer(Self_Update, 10000)
}

Setup_Config() {
    global cfg
    try FileInstall('assets/trigger.ini', 'trigger.ini')
    cfgFile := SubStr(A_ScriptName, 1, -4) . '.ini'
    cfg := Config.Load_Config(cfgFile)
    if (!FileExist(cfg.csvFile)) {
        if (cfg.csvFile)
            MsgBox('CSV File not found', 'Error', '0x0 0x10')
        try FileInstall('assets/trigger.csv', 'trigger.csv')
        cfg.csvFile := 'trigger.csv'
    }
    if (!DirExist(cfg.notesDir)) {
        if (cfg.notesDir)
            MsgBox('Notes directory not found', 'Error', '0x0 0x10')
        try DirCreate('notes')
        cfg.notesDir := 'notes'
    }

    A_TrayMenu.Delete()
    A_TrayMenu.Add('Reload', (*)=>Reload())
    A_TrayMenu.Add('Quit', (*)=>ExitApp())
}

Setup_Icon(icon) {
    if (icon = 'trigger.ico')
        try FileInstall('assets/trigger.ico', 'trigger.ico')
    try TraySetIcon(icon, 1, true)
}

Setup_CSV(csv) {
    global shorts
    shorts := Shortcuts.Load_CSV(csv) ; Loads the data from the CSV file
    shorts.Setup_HotStrings()
}