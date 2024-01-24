#Requires Autohotkey v2
;AutoGUI 2.5.8 creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;Easy_AutoGUI_for_AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

; TODO ajouter un tag aux shortcuts pour utiliser le clipboard au lieu d'un send

class ConfigUI extends Gui {
	__New(cfg) {
        options := '+OwnDialogs +MinSize628x150 -Resize -MinimizeBox -MaximizeBox' 
        super.__New(options, 'Configuration', this)
		this.cfg := cfg
		this.Build()
	}

	Build() {
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
		btnBrowseIcon.OnEvent('Click', 'btnBrowseIcon_OnClick')
		options := Format('xs w{} h{}', w, h)
		btnBrowseCSV := this.AddButton(options, '...')
		btnBrowseCSV.OnEvent('Click', 'btnBrowseCSV_OnClick')
		btnBrowseNotes := this.AddButton(options, '...')
		btnBrowseNotes.OnEvent('Click', 'btnBrowseNotes_OnClick')
		btnBrowseDoc := this.AddButton(options, '...')
		btnBrowseDoc.OnEvent('Click', 'btnBrowseDoc_OnClick')
		this.MarginX := mx

		this.Show('autosize hide')
		winw := ''
		this.GetPos(,,&winw)
		w := 100, x := (winw - 2*w - mx) / 2
		options := Format('x{} w{} h{}', x, w, h)
		btnOk := this.AddButton(options, "&OK")
		btnOk.OnEvent('Click', 'btnOk_OnClick')
		options := Format('yp w{} h{}', w, h)
		btnCancel := this.AddButton(options, "&Cancel")
		btnCancel.OnEvent('Click', 'btnCancel_OnClick')
		this.OnEvent('Close', (*) => ExitApp())
		this.Show('autosize hide center')
	}

	btnBrowseIcon_OnClick(*) {
		icon := this.cfg.Pick_icon()
		if (icon and icon != cfg.icon)
			this.txtIcon.Text := icon
	}

	btnBrowseCSV_OnClick(*) {
		csv := this.cfg.Pick_csvFile()
        if (csv and csv != cfg.csvFile)
            this.txtCSV.Text := csv
	}

	btnBrowseNotes_OnClick(*) {
		notes := this.cfg.Pick_notesDir()
        if (notes and notes != cfg.notesDir)
            this.txtDoc.Text := notes
	}

	btnBrowseDoc_OnClick(*) {
		doc := this.cfg.Pick_document()
		if (doc and doc != cfg.document)
			this.txtDoc.Text := doc
	}

	btnOk_OnClick(*) {
		cfg := this.cfg
		dirty := false
		if (this.hk.Text != cfg.hotkey) {
			dirty := true
			cfg.hotkey := this.hk.Text
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
			dirty := true
			cfg.document := this.txtDoc.Text
		}
		if (dirty)
			answer := MsgBox('Do you wish to reload the application?', 'Reload', '0x4 0x20 Owner' . this.Hwnd)
			if (answer = 'yes')
				Reload()
			else
				this.Destroy()
	}

	btnCancel_OnClick(*) {
		this.Destroy()
	}
}
