#Requires AutoHotkey v2.0

Class Shortcut {
    __New(trigger, replacement, category) {
        this._trigger := trigger
        this._replacements := [replacement]
        this._category := category
    }

    Trigger {
        get => this._trigger
    }

    Replacement {
        get {
            rep := this._replacements.Pop()
            this._replacements.InsertAt(1, rep)
            return rep
        }
    }

    Replacements {
        get {
            return this._replacements
        }
    }

    Category {
        get => this._category
    }

    Add_Replacement(replacement) {
        this._replacements.Push(replacement)
    }

    Send_Replacement(*) {
        Send(this.Replacement)
    }

    New_HotString() {
        sender := ObjBindMethod(this, 'Send_Replacement')
        Hotstring(':X:' this.Trigger, sender)
    }
}
