#Requires AutoHotkey v2.0

Class Shortcut {
    __New(trigger, replacement, category, tags) {
        this._trigger := trigger
        this._replacements := [{
            replacement: replacement,
            category: category,
            tags: tags
        }]
        this._current := this._replacements[1]
    }

    Trigger {
        get => this._trigger
    }

    Replacement {
        get => this._current.replacement
    }

    Category {
        get => this._current.category
    }

    Tags {
        get => this._current.tags
    }

    Replacements {
        get => this._replacements
    }

    Add_Replacement(replacement, category, tags) {
        this._replacements.Push({
            replacement: replacement,
            category: category,
            tags: tags
        })
    }

    Next() {
        this._current := this._replacements.Pop()
        this._replacements.InsertAt(1, this._current)
    }

    Send_Replacement() {
        if (InStr(this.Tags, 'clip')) {
            oldclip := ClipboardAll()
            A_Clipboard := this.Replacement
            Send('^v')
            Sleep(50)
            A_Clipboard := oldclip
        } else if (InStr(this.Tags, 'cooked'))
            Send(this.Replacement)
        else
            Send('{raw}' this.Replacement)
        this.Next()
    }

    New_HotString() {
        Hotstring(':X:' this.Trigger, (*)=>this.Send_Replacement())
    }
}
