vim9script noclear

if exists('g:loaded_supra_pacman')
	finish
endif

g:loaded_supra_pacman = 1

import autoload '../autoload/SupraPacman/Application.vim' as App

if !exists('g:SUPRA_PACMAN_HIGHSCORE')
	g:SUPRA_PACMAN_HIGHSCORE = 0
endif

command Pacman call g:Run_Pacman()

def g:Run_Pacman(level_path: string = '', nb_level: number = 1)
	var path: string

	if level_path == ''
		path = expand("<script>:p")
		path = fnamemodify(path, ':h:h') .. '/levels/'
	else
		path = level_path
	endif

	var myapp = App.Application.new(path, nb_level)

	myapp.Run()
enddef
