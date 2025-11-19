vim9script noclear

if exists('g:loaded_supra_pacman')
	finish
endif

g:loaded_supra_pacman = 1

import autoload 'SupraPacman/Application.vim' as application

if !exists('g:SUPRA_PACMAN_HIGHSCORE')
	g:SUPRA_PACMAN_HIGHSCORE = 0
endif

command -nargs=? Pacman call g:Run_Pacman('', <args>)

def g:Run_Pacman(level_path: string = '', nb_level: number = 1)
	var path: string
	if level_path == ''
		path = expand("<script>:p")
		path = fnamemodify(path, ':h:h') .. '/levels/'
	else
		path = level_path
	endif
	application.RunPacmanLevel(path, nb_level)
enddef
