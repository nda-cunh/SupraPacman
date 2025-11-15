vim9script

import '../autoload/SupraPacman/Application.vim' as App

if !exists('g:SUPRA_PACMAN_HIGHSCORE')
	g:SUPRA_PACMAN_HIGHSCORE = 0
endif

def g:Run_Pacman(level_path: string = '')
	var path: string

	if level_path == ''
		path = expand("<script>:p")
		path = fnamemodify(path, ':h:h') .. '/levels/'
	else
		path = level_path
	endif

	var myapp = App.Application.new(path)

	myapp.Run()
enddef
