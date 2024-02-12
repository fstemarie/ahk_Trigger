
#include <shortcut>

class Shortcuts extends Map {
    __New() {
        super.__New()
    }

    categories {
        get {
            if (!HasProp(this, '_cats')) {
                catsStr := ''
                for ,sc in this {
                    catsStr .= sc.category . '|'
                }
                catsStr := Sort(catsStr, 'D| C0 U')
                this._cats := StrSplit(catsStr, '|')
                this._cats.Pop()
            }
            return this._cats
        }
    }

    Setup_HotStrings() {
        For ,sc in this {
            sc.New_HotString()
            OutputDebug(A_Tab 'Added HotString: ' sc.trigger '`n')
        }
    }

    static Load_CSV(csvFile) { 
        shorts := Shortcuts()
        try {
            csv := StrSplit(FileRead(csvFile), '`r`n')
        } catch OSError as e {
            MsgBox(e.Message, 'Error', '0x10')
            ExitApp(1)
        }
        for line in csv {
            trigger := replacement := category := tags := ''
            loop parse line, 'CSV' {
                switch A_Index {
                    case 1: ; Trigger
                        trigger := A_LoopField
                    case 2: ; Replacement
                        replacement := A_LoopField
                    case 3: ; Category
                        category := A_LoopField
                    case 4: ; tags
                        tags := A_LoopField
                        if (tags = 1)
                            tags := 'cooked'
                    default:
                        continue
                }
            }
            ; Remove rows that don't have all fields filled
            if (!trigger or !replacement or !category)
                continue
            if (shorts.Has(trigger))
                shorts[trigger].Add_Replacement(replacement, category, tags)
            else
                shorts[trigger] := Shortcut(trigger, replacement, category, tags)
        }
        return shorts
    }
}
