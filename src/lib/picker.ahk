#Requires AutoHotkey v2.0

#include <AnimateWindow>
#include <tools>
#include <editors>
#include <notes>
#include <configui>


class Picker extends Gui {
    __New(shortcuts, cfg) {
        options := '+OwnDialogs +MinSize700x500 +Resize -MinimizeBox -MaximizeBox' 
        super.__New(options, 'Trigger', this)
        this._disabled := false
        this.shortcuts := shortcuts
        this.cfg := cfg
        this.edts := Editors()
        this.ns := Notes(cfg.notesDir)
        this.currentNote := ''
        this.notetimer := ''
        this.Build()
        this.Refresh_Categories()
        this.Refresh_Notes()
        try ControlChooseIndex(1, this.lbNote.Hwnd)
        OnMessage(WM_ACTIVATEAPP := 0x001C, ObjBindMethod(this, 'OnActivate'))
        this.OnEvent('Escape', (*)=>this.MakeItDisappear())
        this.OnEvent('Close', (*)=>this.Close())
        this.OnEvent('Size', 'OnSize')
        Hotkey(cfg.hotkey, Showup_HotKey)
        Hotkey(cfg.hotkey . ' UP', Showup_HotKey)
    }

    Disabled {
        get => this._disabled
        set {
            if (value) {
                this._disabled := true
                this.Opt('+Disabled')
            } else {
                this._disabled := false
                this.Opt('-Disabled')
            }
        }
    }

    Build() {
        LVM_SETHOVERTIME := 0x1047
        LVS_EX_HEADERDRAGDROP := 0x10
        LVS_EX_TRACKSELECT := 0x8
        LBS_NOINTEGRALHEIGHT := 0x100
        HDS_NOSIZING  := 0x0800
        BUTTONHEIGHT := 50
        TABSHEIGHT := 35
        MX := 5, MY := 5
        TOTALWIDTH := 1000, TOTALHEIGHT := 600
        x := y := w := h := 0
        
        OutputDebug('-- ' A_ThisFunc '()`n')
        this.Show(Format('w{} h{} hide', TOTALWIDTH, TOTALHEIGHT))
        this.SetFont('s16 bold', 'Calibri')
        this.BackColor := 'BDC3CB'
        this.MarginX := MX, this.MarginY := MY

        ; Tabs
        options := Format('x0 y0 w{} h{}', TOTALWIDTH, TOTALHEIGHT)
        this.tabs := this.AddTab3(options, ['Picker', 'Notes'])
        this.tabs.anchor := 'wh'

; #region TabPicker
        this.tabs.UseTab('Picker')
        w := 0.80 * (TOTALWIDTH - 3*MX)
        h := TOTALHEIGHT - TABSHEIGHT - 2*MY - 3*BUTTONHEIGHT - 3*MY
        alth := TOTALHEIGHT - TABSHEIGHT - 2*MY
        options := Format('x{} y{} w{} h{} ', MX, MY + TABSHEIGHT, w, h)
        options .= Format('+LV{} -LV{} ', LVS_EX_TRACKSELECT, LVS_EX_HEADERDRAGDROP)
        options .= '+Grid -Multi Section'
        this.lvPicker := this.AddListView(options)
        this.lvPicker.anchor := 'wh'
        this.lvPicker.h := h
        this.lvPicker.alth := alth
        this.lvPicker.InsertCol(1, 150, 'Trigger')
        this.lvPicker.InsertCol(2,, 'Replacement')
        this.lvPicker.OnEvent('Click', 'lvPicker_OnClick')
        this.lvPicker.OnEvent('ItemSelect', 'lvPicker_OnItemSelect')
        this.lvPicker.OnEvent('ContextMenu', 'lvPicker_OnContextMenu')
        PostMessage(LVM_SETHOVERTIME, 0, 1,, 'ahk_id ' this.lvPicker.Hwnd)
        hdrHwnd := SendMessage(LVM_GETHEADER := 0x101F, 0, 0, this.lvPicker)
        ControlSetStyle("+" . HDS_NOSIZING := 0x800, hdrHwnd)

        h := 3*BUTTONHEIGHT + 2*MY
        options := Format('xs w{} h{} +BackgroundWhite', w, h)
        this.txtPreview := this.AddText(options)
        this.txtPreview.anchor := 'yw'

        w := 0.20 * (TOTALWIDTH - 3*MX)
        h := TOTALHEIGHT - TABSHEIGHT - 3*BUTTONHEIGHT - 5*MY
        options := Format('ys w{} h{} {} Sort', w, h, LBS_NOINTEGRALHEIGHT)
        this.lbCategories := this.AddListBox(options)
        this.lbCategories.anchor := 'xh'
        this.lbCategories.OnEvent('Change', 'lbCategories_OnChange')
        this.lbCategories.OnEvent('DoubleClick', 'lbCategories_OnDoubleClick')

        h := BUTTONHEIGHT
        options := Format('xp wp h{}', h, LBS_NOINTEGRALHEIGHT)
        this.btnDoc := this.AddButton(options, 'Edit &Doc')
        this.btnDoc.anchor := 'xy'
        this.btnDoc.OnEvent('Click', (*)=>Run(this.cfg.document))
        options := 'xp wp hp'
        this.btnEdit := this.AddButton(options, '&Text Editor')
        this.btnEdit.anchor := 'xy'
        this.btnEdit.OnEvent('Click', (*)=>this.edts.Start())
        this.btnReload := this.AddButton(options, '&Reload')
        this.btnReload.anchor := 'xy'
        this.btnReload.OnEvent('Click', (*)=>Reload())

; #endregion TabPicker
; #region TabNotes
        this.tabs.UseTab('Notes')
        w := 0.80 * (TOTALWIDTH - 3*MX)
        h := TOTALHEIGHT - TABSHEIGHT - 2*MY
        options := Format('x{} y{} w{} h{} +WantTab', MX, MY + TABSHEIGHT, w, h)
        this.edtNote := this.AddEdit(options)
        this.edtNote.anchor := 'wh'
        this.edtNote.Enabled := false
        this.edtNote.OnEvent('Change', 'edtNote_OnChange')

        w := 0.20 * (TOTALWIDTH - 3*MX)
        h := TOTALHEIGHT - TABSHEIGHT - 2*MY - 3*BUTTONHEIGHT - 3*MY
        options := Format('yp w{} h{} {} +Sort Section', w, h, LBS_NOINTEGRALHEIGHT)
        this.lbNote := this.AddListBox(options)
        this.lbNote.anchor := 'xh'
        this.lbNote.OnEvent('Change', 'lbNote_OnChange')

        h := BUTTONHEIGHT
        options := Format('xs wp h{} Section', h)
        this.btnRefreshNote := this.AddButton(options, '&Refresh')
        this.btnRefreshNote.anchor := 'xy'
        this.btnRefreshNote.OnEvent('Click', 'btnRefreshNote_OnClick')
        options := 'xp wp hp'
        this.btnNewNote := this.AddButton(options, '&New')
        this.btnNewNote.anchor := 'xy'
        this.btnNewNote.OnEvent('Click', 'btnNewNote_OnClick')
        this.btnDelNote := this.AddButton(options, '&Delete')
        this.btnDelNote.anchor := 'xy'
        this.btnDelNote.OnEvent('Click', 'btnDelNote_OnClick')
; #endregion TabNotes
; #region Menu
        menuHandler := ObjBindMethod(this, 'mnuCommands_OnEvent')
        mnuCommands := Menu()
        mnuCommands.Add('Edit Document', menuHandler)
        mnuCommands.Add('Open Editor', menuHandler)
        mnuCommands.Add('Reload', menuHandler)
        mnuCommands.Add('Quit', menuHandler)
        menuHandler := ObjBindMethod(this, 'mnuOptions_OnEvent')
        mnuOptions := Menu()
        mnuOptions.Add('Config...', menuHandler)
        mnuOptions.Add()
        mnuOptions.Add('Remember size', menuHandler)
        if (this.cfg.rememberSize)
            mnuOptions.Check('Remember size')
        mnuOptions.Add('Show preview', menuHandler)
        if (this.cfg.showPreview)
            mnuOptions.Check('Show preview')
        mnuOptions.Add('Show "*" category', menuHandler)
        if (this.cfg.showCategoryAll)
            mnuOptions.Check('Show "*" category')
        this.MenuBar := MenuBar()
        this.MenuBar.Add('Commands', mnuCommands)
        this.MenuBar.Add('Options', mnuOptions)
; #endregion Menu

        ; this.Show('hide')
        this.ShowPreview(this.cfg.ShowPreview)
        w := TOTALWIDTH, h := TOTALHEIGHT
        if (this.cfg.rememberSize) {
            w := this.cfg.guiWidth || TOTALWIDTH
            h := this.cfg.guiHeigth || TOTALHEIGHT
        }
        this.Show(Format('w{} h{} hide', w, h))
    }

; #region Events
    OnActivate(activated, thread, msg, hwnd) {
        if (!activated and hwnd = this.Hwnd)
            if (!WinWaitActive('ahk_id ' this.Hwnd,, 1)) {
                this.MakeItDisappear()
            }
        if (activated and hwnd = this.Hwnd)
            WinWaitActive('ahk_id ' this.Hwnd)
    }

    OnSize(minmax, width, height) {
        static ogw, ogh ; Original gui width and height
        x := y := w := h := 0

        ; If the original size of the gui and controls haven't been saved yet, save them
        if !IsSet(ogw) {
            ogw := width, ogh := height ; Save the original size of the gui
            ; Save the original size of each controls in the gui
            for ,ctrl in this {
                ctrl.GetPos(&x, &y, &w, &h)
                ctrl.origPos := {x: x, y: y, w: w, h: h}
            }
        }

        this.lvPicker.origPos.h := this.cfg.showPreview?this.lvPicker.h:this.lvPicker.alth
        this.txtPreview.Visible := this.cfg.showPreview

        dx := dw := width - ogw ; deltas of the original position/size of the gui vs the new ones
        dy := dh := height - ogh
        for ,ctrl in this {
            ctrl.GetPos(&x, &y, &w, &h)
            if (InStr(ctrl.anchor, 'x'))
                ox := ctrl.origPos.x, x := (dx * 1) + ox
            if (InStr(ctrl.anchor, 'y'))
                oy := ctrl.origPos.y, y := (dy * 1) + oy
            if (InStr(ctrl.anchor, 'w'))
                ow := ctrl.origPos.w, w := (dw * 1) + ow
            if (InStr(ctrl.anchor, 'h'))
                oh := ctrl.origPos.h, h := (dh * 1) + oh
            ctrl.Move(x, y, w, h)
        }
        this.lvPicker.ModifyCol(2, 'AutoHdr')
        this.lvPicker.Redraw()
    }

    mnuCommands_OnEvent(ItemName, *) {
        switch ItemName {
            Case 'Edit Document':
                if (!this.cfg.document)
                    this.cfg.document := this.cfg.csvFile
                Run(this.cfg.document)
            Case 'Open Editor':
                this.edts.Start()
            Case 'Reload':
                Reload()
            Case 'Quit':
                this.Close()
            }
    }

    mnuOptions_OnEvent(ItemName, ItemPos, MyMenu) {
        switch ItemName {
            case 'Config...':
                ConfigUI.Show_ConfigUI(this.cfg, this)
            Case 'Remember size':
                this.cfg.rememberSize := !this.cfg.rememberSize
                if (this.cfg.rememberSize) {
                    MyMenu.Check('Remember size')
                } else {
                    MyMenu.Uncheck('Remember size')
                }
            Case 'Show preview':
                this.cfg.showPreview := !this.cfg.showPreview
                this.ShowPreview(this.cfg.showPreview)
                if (this.cfg.showPreview) {
                    MyMenu.Check('Show preview')
                } else {
                    MyMenu.Uncheck('Show preview')
                }
            Case 'Show "*" category':
                this.cfg.showCategoryAll := !this.cfg.showCategoryAll
                if (this.cfg.showCategoryAll)
                    MyMenu.Check('Show "*" category')
                else
                    MyMenu.Uncheck('Show "*" category')
                this.Refresh_Categories()
        }
    }

    lvPicker_OnClick(lv, row) {
        if (!row)
            return
        this.Hide()
        SetKeyDelay(0)
        sc := this.shortcuts[lv.GetText(row)]
        sc.Send_Replacement()
    }

    lvPicker_OnItemSelect(lv, row, selected) {
        if (selected)
            this.txtPreview.Value := lv.GetText(row, 2)
        else
            ToolTip(,,,1)
    }

    lvPicker_OnContextMenu(lv, row, isRightClick, x, y) {
        static tooltipshowing := false
        if (!row)
            return
        if (!tooltipshowing) {
            rep := lv.GetText(row, 2)
            ToolTip(rep, x, y, 1)
            tooltipshowing := true
            SetTimer(TurnOffToolTip, -2000)
        } else {
            TurnOffToolTip()
        }

        TurnOffToolTip() {
            ToolTip(,,,1)
            tooltipshowing := false
            SetTimer(TurnOffToolTip, 0)
        }
    }

    lbCategories_OnChange(lb, *) {
        this.Refresh_Picker(lb.Text)
    }

    lbCategories_OnDoubleClick(lb, *) {
        if (lb.Text) {
            if (this.cfg.defaultCategory != lb.Text)
                this.cfg.defaultCategory := lb.Text
            else
                this.cfg.defaultCategory := ''
        }
    }

    edtNote_OnChange(edt, *) {
        if (this.currentNote)
            this.currentNote.Content := edt.Text
    }

    lbNote_OnChange(lb, *) {
        if (!lb.Text)
            return
        if (this.currentNote) {
            this.currentNote.Save()
            this.currentNote := ''
        }
        title := lb.Text
        this.currentNote := this.ns[lb.Text]
        this.edtNote.Value := this.currentNote.Content
        this.edtNote.Enabled := true
    }

    btnRefreshNote_OnClick(*) {
        this.Refresh_Notes()
    }

    btnNewNote_OnClick(*) {
        this.ns.New()
        this.Refresh_Notes()
    }

    btnDelNote_OnClick(*) {
        if (this.currentNote.Delete()) {
            this.edtNote.Enabled := false
            this.edtNote.Value := ''
            this.currentNote := ''
            this.Refresh_Notes()
        }
    }
; #endregion Events

; #region Methods
    Refresh_Notes() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        this.lbNote.Delete()
        this.lbNote.Add(this.ns.Titles)
    }

    Set_Category(category?) {
        OutputDebug('-- ' A_ThisFunc '()`n')
        if (IsSet(category) and category)
            try {
                this.lbCategories.Choose(category)
                return
            }
        category := this.cfg.defaultCategory || this.lbCategories.Text || 1
        this.lbCategories.Choose(category)
    }

    Refresh_Categories() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        lb := this.lbCategories
        cat := lb.Text
        cats := this.shortcuts.categories
        lb.Delete()
        if (cfg.showCategoryAll)
            lb.Add(['*'])
        lb.Add(cats)
        this.Set_Category(cat)
        this.Refresh_Picker()
    }

    Refresh_Picker(category?) {
        OutputDebug('-- ' A_ThisFunc '()`n')
        lv := this.lvPicker
        category := category ?? this.lbCategories.Text
        lv.Delete()
        for ,sc in this.shortcuts {
            for ,rep in sc.replacements
                if (category = "*" or rep.category = category) {
                    lv.Add(, sc.trigger, rep.replacement)
                }
        }
        this.lvPicker.ModifyCol(1, 'AutoHdr')
        this.lvPicker.ModifyCol(2, 'AutoHdr')
    }

    MakeItAppear() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        x := y := w := h:= 0
        mon := Get_CurrentMonitor()
        this.GetPos(,,&w, &h)
        Find_Center(&x, &y, w, h, mon)
        ; this.Show(Format('hide x{} y{}', x, y))
        ; AnimateWindow(this.Hwnd, 150, AW_ACTIVATE + RandFX())
        this.Show(Format('x{} y{}', x, y))
        WinWaitActive(this.Hwnd)
        ; this.Show()
    }
    
    MakeItDisappear() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        AnimateWindow(this.Hwnd, 150, AW_HIDE + RandFX())
        ; this.Hide()
    }
    
    FollowMouse() {
        OutputDebug('-- ' A_ThisFunc '()`n')
        x := y := w := h:= 0
        mon := Get_CurrentMonitor()
        this.GetPos(,,&w, &h)
        Find_Center(&x, &y, w, h, mon)
        this.Move(x, y)
        this.lvPicker.Focus()
        ; WinActivate(this.Hwnd)
    }

    ShowPreview(value) {
        x := y := w := h := 0
        this.txtPreview.Visible := value
        this.GetPos(&x,&y,&w,&h)
        this.Move(0,0,1000,600)
        this.Move(x,y,w,h)
    }

    Close() {
        w := h := 0
        this.GetClientPos(,,&w,&h)
        if (this.cfg.rememberSize) {
            this.cfg.guiWidth := w
            this.cfg.guiHeigth := h
        }
        ExitApp()
    }
; #endregion Methods
}

; #region Functions
Showup_HotKey(hk) {
    static skipUP := false
    ui := view
    isUP := RegExMatch(hk, ' UP$')
    if (!isUP) {
        skipUP := false
        SetTimer(longpress, -500)
        KeyWait(hk, 'D T1')
    }
    if (isUP and !skipUP) {
        SetTimer(longpress, 0)
        OutputDebug('#### HotKey Pressed `n')
        view.MakeItAppear()
        ; if (WinExist('ahk_id' view.Hwnd)) 
        ;     view.FollowMouse()
        ; else
        ;     view.MakeItAppear()
    }

    longpress() {
        OutputDebug('#### HotKey Long Pressed `n')
        skipUP := true
        edts.Tile()
    }
}
