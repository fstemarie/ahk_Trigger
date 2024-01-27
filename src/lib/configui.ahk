#Requires Autohotkey v2

#include <tools>

; TODO ajouter un tag aux shortcuts pour utiliser le clipboard au lieu d'un send

class ConfigUI extends Gui {
	__New(cfg) {
        options := '+OwnDialogs +MinSize628x150 -Resize -SysMenu' 
        super.__New(options, 'Configuration', this)
		this.cfg := cfg
		this.Build()
	}

	static Show_ConfigUI(cfg, parent) {
        OutputDebug('-- ' A_ThisFunc '()`n')
		cfgui := ConfigUI(cfg)
		cfgui.parent := parent
		cfgui.Opt('+Owner' parent.Hwnd)
		x := y := w := h:= 0, mon := Get_CurrentMonitor()
		cfgui.GetPos(&x, &y, &w, &h)
		Find_Center(&x, &y, w, h, mon)
		parent.Disabled := true
		cfgui.Show(Format('x{} y{}', x, y))
	}

	Build() {
        OutputDebug('-- ' A_ThisFunc '()`n')
		this.MarginX := mx := 15, this.MarginY := my := 15
		this.Show('hide')
		this.SetFont("s16 w600", "Calibri")
		w := 100, h := 32
		options := Format('xm ym w{} h{} +0x200 +Right Section', w, h)
		this.AddText(options, "HotKey")
		options := Format('xp wp hp +0x200 +Right', w, h)
		this.AddText(options, 'Icon')
		this.AddText(options, 'CSV')
		this.AddText(options, 'Notes')
		this.AddText(options, 'Document')

		w := 200
		options := Format('ys w{} h{} Limit128', w, h)
		this.hk := this.AddHotkey(options)
		this.hk.Value := this.cfg.hotkey

		w := 600
		options := Format('xp w{} h{} +0x200 +Border +BackgroundWhite Section', w, h)
		this.txtIcon := this.AddText(options)
		this.txtIcon.Text := this.cfg.icon
		options := Format('xp w{} h{} +0x200 +Border +BackgroundWhite', w, h)
		this.txtCSV := this.AddText(options)
		this.txtCSV.Text := this.cfg.csvFile
		this.txtNotes := this.AddText(options)
		this.txtNotes.Text := this.cfg.notesDir
		this.txtDoc := this.AddText(options)
		this.txtDoc.Text := this.cfg.document

		w := 50
		this.MarginX := 0
		options := Format('ys w{} h{} Section', w, h)
		btnBrowseIcon := this.AddButton(options, '...')
		btnBrowseIcon.OnEvent('Click', (*)=>this.Select_Icon())
		options := Format('xs w{} h{}', w, h)
		btnBrowseCSV := this.AddButton(options, '...')
		btnBrowseCSV.OnEvent('Click', (*)=>this.Select_CSV())
		btnBrowseNotes := this.AddButton(options, '...')
		btnBrowseNotes.OnEvent('Click', (*)=>this.Select_Notes())
		btnBrowseDoc := this.AddButton(options, '...')
		btnBrowseDoc.OnEvent('Click', (*)=>this.Select_Doc())
		this.MarginX := mx

		this.Show('autosize hide')
		winw := '', this.GetPos(,,&winw)
		w := 100, x := (winw - 2*w - mx) / 2
		options := Format('x{} w{} h{}', x, w, h)
		btnOk := this.AddButton(options, "&OK")
		btnOk.OnEvent('Click', (*)=>this.Submit())
		options := Format('yp w{} h{}', w, h)
		btnCancel := this.AddButton(options, "&Cancel")
		btnCancel.OnEvent('Click', (*)=>this.Leave())
		this.Show('autosize hide')
	}

	Select_Icon(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')
		icon := FileSelect((1 + 2), A_ScriptDir, 'Choose your icon', 'ICO File (*.ico)',)
		if (icon and icon != this.cfg.icon)
			this.txtIcon.Text := icon
	}

	Select_CSV(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')
		csv := FileSelect((1 + 2), A_MyDocuments, 'Choose your HotStrings CSV file', 'CSV File (*.csv)')
        if (csv and csv != this.cfg.csvFile)
            this.txtCSV.Text := csv
	}

	Select_Notes(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')
		notes := FileSelect('D1', A_MyDocuments, 'Choose a folder for notes')
        if (notes and notes != this.cfg.notesDir)
            this.txtDoc.Text := notes
	}

	Select_Doc(*) {
        OutputDebug('-- ' A_ThisFunc '()`n')
		doc := FileSelect((1 + 2), A_MyDocuments, 'Choose the document to edit')
		if (doc and doc != this.cfg.document)
			this.txtDoc.Text := doc
	}

	Submit() {
        OutputDebug('-- ' A_ThisFunc '()`n')
		cfg := this.cfg
		dirty := false
		if (this.hk.Value != cfg.hotkey) {
			dirty := true
			cfg.hotkey := this.hk.Value
		}
		if (this.txtIcon != cfg.icon) {
			dirty := true
			cfg.icon := this.txtIcon.Text
		}
		if (this.txtCSV != cfg.csvFile) {
			dirty := true
			cfg.csvFile := this.txtCSV.Text
		}
		if (this.txtNotes != cfg.notesDir) {
			dirty := true
			cfg.notesDir := this.txtNotes.Text
		}
		if (this.txtDoc != cfg.document) {
			cfg.document := this.txtDoc.Text
		}
		if (dirty)
			answer := MsgBox('Do you wish to reload the application?', 'Reload', '0x4 0x20 Owner' . this.Hwnd)
			if (answer = 'yes')
				Reload()
			else
				this.Leave()
	}

	Leave() {
        OutputDebug('-- ' A_ThisFunc '()`n')
		this.parent.Disabled := false
		this.Destroy()
	}
}
