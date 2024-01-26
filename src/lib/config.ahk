#Requires AutoHotkey v2.0

Class Config {
    __New(cfgFile) {
        if (!FileExist(cfgFile)) {
            throw 'INI File not found'
        }
        this.cfgFile := cfgFile
    }

    hotkey {
        get => IniRead(this.cfgFile, 'Configuration', 'hotkey', 'F1')
        set => IniWrite(value, this.cfgFile, 'Configuration', 'hotkey')
    }

    icon {
        get => IniRead(this.cfgFile, 'Configuration', 'icon', '')
        set {
            if (value)
                if (FileExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'icon')
                else
                    throw 'File must exist'
        }
    }

    csvFile {
        get => IniRead(this.cfgFile, 'Configuration', 'csvFile', '')
        set {
            if (value)
                if (FileExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'csvFile')
                else
                    throw 'File must exist'
        }
    }

    notesDir {
        get => IniRead(this.cfgFile, 'Configuration', 'notesDir', '')
        set {
            if (value)
                if (DirExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'notesDir')
                else
                    throw 'Notes folder must exist'
        }
    }

    document {
        get => IniRead(this.cfgFile, 'Configuration', 'document', '')
        set {
            if (value)
                if (FileExist(value))
                    IniWrite(value, this.cfgFile, 'Configuration', 'document')
                else
                    throw 'Document must exist'
        }
    }

    showCategoryAll {
        get => IniRead(this.cfgFile, 'Configuration', 'showCategoryAll', false)
        set => IniWrite(value ? true : false, this.cfgFile, 'Configuration', 'showCategoryAll')
    }

    defaultCategory {
        get => IniRead(this.cfgFile, 'Configuration', 'defaultCategory', '')
        set => IniWrite(value, this.cfgFile, 'Configuration', 'defaultCategory')
    }

    static Load_Config(cfgFile) {
        OutputDebug('-- ' A_ThisFunc '()`n')
        return Config(cfgFile)
    }
}