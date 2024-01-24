;@Ahk2Exe-SetName Trigger
;@Ahk2Exe-SetVersion 2.5
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
    static NEW := 'trigger-new.exe'
    static UPD := 'trigger-update.exe'
    if (!A_IsCompiled)
        return
    if (FileExist(NEW) and !FileExist(UPD)) {
        FileInstall('../dist/trigger-update.exe', UPD)
        Run(UPD)
        ExitApp()
    }
    if (!FileExist(NEW) and FileExist(UPD)) {
        WinWaitClose('ahk_exe ' UPD)
        FileDelete(UPD)
    }
    SetTimer(Self_Update, 10000)
}

Setup_Config() {
    global cfg
    try FileInstall('assets/trigger.ini', 'trigger.ini')
    cfgFile := SubStr(A_ScriptName, 1, -4) . '.ini'
    cfg := Config.Load_Config(cfgFile)
    if (!cfg.csvFile or cfg.csvFile = 'trigger.csv') {
        try FileInstall('assets/trigger.csv', 'trigger.csv')
        cfg.csvFile := 'trigger.csv'
    }
    if (!cfg.notesDir or cfg.notesDir = 'notes') {
        try DirCreate('notes')
        cfg.notesDir := 'notes'
    }

    A_TrayMenu.Delete()
    A_TrayMenu.Add('Reload', (*) => Reload())
    A_TrayMenu.Add('Quit', (*) => ExitApp())
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