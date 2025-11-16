vim9script

highlight SupraBlue guifg=#0825fc guibg=NONE ctermfg=Blue ctermbg=NONE
highlight SupraYellow guifg=#FFFF01
highlight link SupraWhite Normal
# use with all border characters
syn match SupraBlue /│/
syn match SupraBlue /─/
syn match SupraBlue /╭/
syn match SupraBlue /╮/
syn match SupraBlue /╰/
syn match SupraBlue /╯/


syn region firstThreeLines start="\%1l" end="\%5l" containedin=ALL
# the pacman is everywhere yellow
syn match SupraYellow /󰮯/ containedin=ALL


syn match SupraWhite /│/ contained containedin=firstThreeLines
syn match SupraWhite /─/ contained containedin=firstThreeLines
syn match SupraWhite /╭/ contained containedin=firstThreeLines 
syn match SupraWhite /╮/ contained containedin=firstThreeLines
syn match SupraWhite /╰/ contained containedin=firstThreeLines
syn match SupraWhite /╯/ contained containedin=firstThreeLines


