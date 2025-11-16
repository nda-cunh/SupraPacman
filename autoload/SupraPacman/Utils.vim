vim9script

var t_ve: string
var hlcursor: dict<any>

# Use to hide the cursor while popups active
export def HideCursor()
	# terminal cursor
	t_ve = &t_ve
	setlocal t_ve=
	# gui cursor
	if len(hlget('Cursor')) > 0
		hlcursor = hlget('Cursor')[0]
		hlset([{name: 'Cursor', cleared: true}])
	endif
enddef

# Use to restore cursor when closing popups
export def ShowCursor()
	# terminal cursor
	if &t_ve != t_ve
		&t_ve = t_ve
	endif
	# gui cursor
	if len(hlget('Cursor')) > 0 && get(hlget('Cursor')[0], 'cleared', false)
		hlset([hlcursor])
	endif
enddef

export def HandleClickPopup(wid: number, chooses: list<string>): number 
	var bufnr = winbufnr(wid)
	var pos = getmousepos()
	if pos.winid != wid
		return -1
	endif
	try
	var line = getbufline(bufnr, pos.winrow - 2, pos.winrow + 1)
	for i in line
		var nb = 0
		for value in chooses
			if stridx(i, value) != -1
				return nb
			endif
			nb += 1
		endfor
	endfor
	catch
	endtry
	return -1
enddef

export def LoadMapFromFile(file_path: string): list<list<number>>
	const lines = readfile(file_path)

	var map: list<list<number>> = []
	for line in lines
		var row: list<number> = []
		const nums = split(line, ' ')
		for num in nums
			add(row, str2nr(num))
		endfor
		add(map, row)
	endfor
	return map
enddef
