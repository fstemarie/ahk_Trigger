#Requires AutoHotkey v2.0

Class Config {
    __New(configFile) {
        if (!FileExist(configFile)) {
            throw 'INI File not found'
        }
        this.configFile := configFile
        this._csvFile := ''
        this._notesDir := ''
        this._document := ''
        this._defaultCategory := ''
    }

    csvFile {
        get {
            if (!this._csvFile) {
                this._csvFile := IniRead(this.configFile, 'Configuration', 'csvFile', '')
            }
            return this._csvFile
        }
        set {
            if (FileExist(value)) {
                IniWrite(value, this.configFile, 'Configuration', 'csvFile')
                this._csvFile := value
            } else {
                throw 'File must exist'
            }
        }
    }

    notesDir {
        get {
            if (!this._notesDir) {
                this._notesDir := IniRead(this.configFile, 'Configuration', 'notesDir', '')
            }
            return this._notesDir
        }
        set {
            if (InStr(FileExist(value), 'D')) {
                IniWrite(value, this.configFile, 'Configuration', 'notesDir')
                this._notesDir := value
            } else {
                throw 'Notes folder must exist'
            }
        }
    }

    document {
        get {
            if (!this._document) {
                this._document := IniRead(this.configFile, 'Configuration', 'document', '')
            }
            return this._document
        }
        set {
            if (InStr(FileExist(value), 'N')) {
                IniWrite(value, this.configFile, 'Configuration', 'document')
                this._document := value
            } else {
                throw 'Document must exist'
            }
        }
    }

    defaultCategory {
        get {
            if (!this._defaultCategory) {
                this._defaultCategory := IniRead(this.configFile, 'Configuration', 'defaultCategory', '')
            }
            return this._defaultCategory

        }
        set {
            IniWrite(value, this.configFile, 'Configuration', 'defaultCategory')
            this._defaultCategory := value
        }
    }

    static Load_Config(configFile) {
        OutputDebug('-- ' A_ThisFunc '()`n')
        emptyconfig := '
        (
            [Configuration]
            csvFile=
            notesDir=
            document=
            defaultCategory=
        )'
        if !FileExist(configFile) {
            FileAppend(emptyConfig, configFile)
        }
    
        cfg := Config(configFile)
        if (!cfg.csvFile) {
            filename := FileSelect((1 + 2), A_MyDocuments, 'Choose your HotStrings CSV file', 'CSV File (*.csv)')
            if (filename) {
                cfg.csvFile := filename
            } else {
                OutputDebug('No CSV File selected')
                MsgBox('HotStrings.ahk - No CSV File', 'You MUST select a CSV File', 16)
                ExitApp(1)
            }
        }
        if (!cfg.notesDir) {
            dirname := FileSelect('D1', A_MyDocuments, 'Choose a folder for notes')
            if (dirname) {
                cfg.notesDir := dirname
            } else {
                OutputDebug('No notes folder selected')
                MsgBox('HotStrings.ahk - No notes Folder', 'You MUST select a notes folder', 16)
                ExitApp(1)
            }
        }
        return cfg
    }
}
