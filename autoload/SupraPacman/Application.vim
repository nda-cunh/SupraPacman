vim9script

################################
## Const and Variables
################################

import autoload './Utils.vim' as Utils
import autoload './Direction.vim' as Dir
import autoload './Pacman.vim' as Pac
import autoload './Constants.vim' as Const
import autoload './Activity.vim' as Activity
import autoload './TileType.vim' as Tile
import autoload './Ghost.vim' as AGhost
import autoload './Pinky.vim' as Pinky
import autoload './Blinky.vim' as Blinky
import autoload './Inky.vim' as Inky
import autoload './Clyde.vim' as Clyde

type Direction = Dir.Direction
type Pacman = Pac.Pacman
type Ghost = AGhost.Ghost
type PinkyGhost = Pinky.PinkyGhost
type BlinkyGhost = Blinky.BlinkyGhost
type InkyGhost = Inky.InkyGhost
type ClydeGhost = Clyde.ClydeGhost

# All the sprites used in the game
export const SPRITE_LOOKUP = [
    '  ', '⬛️', '󰮯 ', '🟦', '🟥', '🟪', '🟩', '🟨', '🔸', '🔶', '🍒', '🍓', '🍊', '🍎', '🍉', '🛸', '🔔', '🔑', '👀', '  '
]

export class Application
	var timer: number
	var popup: number
	var player: Pacman
	var score: number
	var highscore: number
	var activity = Activity.MENU
	var map: list<list<number>> = []
	var map_opti: list<list<string>> = []
	var ghosts: list<Ghost>
	var timer_ghost: number
	var cage_pos: list<number>
	var lst_entity: list<list<number>>
	var remain_food: number
	var level_num: number = 1
	var directory_level: string
	var nb_levels: number
	var level_min: number = 1
	var len_map: number
	var len_map_x: number

	##############################
	## Constructor
	##############################
	def new(directories: string, level_chose: number)
		this.directory_level = directories
		this.level_min = level_chose
		Utils.HideCursor()
		this.InitializePopup()
		this.ChangeActivity(Activity.MENU)
		# count number of levels in directory
		var files = split(globpath(this.directory_level, '*.level'), '\n')
		this.nb_levels = len(files)
	enddef

	###############################
	## Close Application
	###############################
	def Close()
		if this.timer != 0
			timer_stop(this.timer)
			this.timer = 0
		endif
		if this.timer_ghost != 0
			timer_stop(this.timer_ghost)
			this.timer_ghost = 0
		endif
		Utils.ShowCursor()
		popup_close(this.popup)
	enddef

	##############################
	## Initialize Popup Window
	## Sets up the popup window with desired settings
	##############################
	def InitializePopup()
		this.popup = popup_create([], {
			borderhighlight: ['Normal', 'Normal', 'Normal', 'Normal'],
			borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
			highlight: 'Normal',
			border: [1],
			minwidth: Const.width,
			minheight: Const.height,
			time: -1,
			drag: 1,
			dragall: 1,
			tabpage: -1,
			filter: this.KeyFilter,
			mapping: 0,
			callback: (wid, _) => {
				if this.timer != 0
					timer_stop(this.timer)
					this.timer = 0
				endif
			}
		})
		const bufnr = winbufnr(this.popup)

		setwinvar(this.popup, '&nu', 0)
		setwinvar(this.popup, '&rnu', 0)
		setwinvar(this.popup, '&buflisted', 0)
		setwinvar(this.popup, '&modeline', 0)
		setwinvar(this.popup, '&swapfile', 0)
		setwinvar(this.popup, '&undolevels', -1)
		setwinvar(this.popup, '&modifiable', 1)
		setwinvar(this.popup, '&nu', 0)
		setwinvar(this.popup, '&relativenumber', 0)
		setwinvar(this.popup, "&updatetime", 2500)
		setwinvar(this.popup, '&signcolumn', 'yes')
		setwinvar(this.popup, '&wrap', 0)
		setwinvar(this.popup, '&syntax', 'on')
		setwinvar(this.popup, '&signcolumn', 'no')
		setbufvar(bufnr, '&cursorline', 1)
	enddef


	###############################
	## Run Game Loop
	###############################
	def Run()
		if this.timer != 0
			timer_stop(this.timer)
		endif

		this.timer = timer_start(70, (_) => {
			if this.activity == Activity.PLAY
				this.Clear()
				this.UpdateGame()
				this.DrawGame()
			elseif this.activity == Activity.MENU
				this.DrawMenu()
			elseif this.activity == Activity.GAMEOVER
				this.DrawGameOver()
			elseif this.activity == Activity.NEXTLEVEL
				this.DrawNextLevel()
			elseif this.activity == Activity.CONGRATULATIONS
				this.DrawCongratulations()
			endif
		}, {repeat: -1})
	enddef



	################################
	## Change Activity
	## Handles transitions between different game states
	################################
	def ChangeActivity(new_activity: number)
		this.activity = new_activity

		const bufnr = winbufnr(this.popup)
		if this.activity == Activity.PLAY
			setbufvar(bufnr, '&filetype', 'suprapacmangame')
		elseif this.activity == Activity.MENU
			setbufvar(bufnr, '&filetype', 'suprapacman')
		elseif this.activity == Activity.GAMEOVER
			setbufvar(bufnr, '&filetype', 'suprapacman')
		elseif this.activity == Activity.NEXTLEVEL
			if this.timer_ghost != 0
				timer_stop(this.timer_ghost)
				this.timer_ghost = 0
			endif
			setbufvar(bufnr, '&filetype', 'suprapacman')
		elseif this.activity == Activity.CONGRATULATIONS
			if this.timer_ghost != 0
				timer_stop(this.timer_ghost)
				this.timer_ghost = 0
			endif
			setbufvar(bufnr, '&filetype', 'suprapacman')
		endif
	enddef



	##########################################
	## Initialize Game State
	## it's used to reset the game or start a new one
	##########################################
	def InitGame()
		if this.timer_ghost != 0
			timer_stop(this.timer_ghost)
			this.timer_ghost = 0
		endif

		# if level number is greater than number of levels, go to
		# congratulations

		if this.level_num > this.nb_levels
			this.ChangeActivity(Activity.CONGRATULATIONS)
			return
		endif

		this.remain_food = 0
		this.player = Pacman.new(15, 15, Dir.NONE)
		this.ChangeActivity(Activity.PLAY)
		this.highscore = g:SUPRA_PACMAN_HIGHSCORE

		const width_max = Const.width / 2
		const height_max = Const.height

		this.map = []
		this.lst_entity = []
		this.ghosts = []

		var this_level_file = this.directory_level .. '/' .. string(this.level_num) .. '.level'
		if !filereadable(this_level_file)
			this.Close()
			echoerr "Level Not Found" .. this_level_file
			return
		endif

		var level: list<list<number>>
		level = Utils.LoadMapFromFile(this_level_file)

		for i in level
			var line = []
			for j in i
				if j == Tile.PACMAN
					this.player.SetPosition(len(line), len(this.map))
				elseif j == Tile.BLINKY
					var new_ghost = BlinkyGhost.new(Dir.NONE, Tile.BLINKY)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == Tile.PINKY
					var new_ghost = PinkyGhost.new(Dir.NONE, Tile.PINKY)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == Tile.INKY
					var new_ghost = InkyGhost.new(Dir.NONE, Tile.INKY)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == Tile.CLYDE
					var new_ghost = ClydeGhost.new(Dir.NONE, Tile.CLYDE)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == Tile.CAGE
					this.cage_pos = [len(line), len(this.map)]
				elseif j == Tile.SIMPLE
					this.remain_food += 1
				endif
				add(line, j)
			endfor
			add(this.map, line)
			add(this.lst_entity, copy(line))
		endfor

		this.len_map = len(this.map)
		this.len_map_x = len(this.map[0])


		# Clear ghost from map and give it initial state
		for g in this.ghosts
			this.map[g.y][g.x] = Tile.EMPTY
			g.AddMapSize(this.len_map_x, this.len_map)
		endfor

		# Clear player from map
		this.map[this.player.y][this.player.x] = Tile.EMPTY



		# create this.map_opti with same size as map
		this.map_opti = []
		for i in range(len(this.map))
			var line = []
			for j in range(len(this.map[i]))
				add(line, '')
			endfor
			add(this.map_opti, line)
		endfor

		# Clear entities from map
		var n = 0
		for e in this.lst_entity
			for j in range(len(e))
				if e[j] == Tile.SIMPLE || e[j] == Tile.PACGOMME || (e[j] >= Tile.FOOD1 && e[j] <= Tile.FOOD8)
					this.map[n][j] = Tile.EMPTY # if there's an entity
				else
					e[j] = Tile.EMPTY
				endif
			endfor
			n += 1
		endfor

		for i in range(len(this.map))
			for j in range(len(this.map[i]))
				var right: bool
				var left: bool
				var up: bool
				var down: bool

				var up_right: bool
				var up_left: bool
				var down_right: bool
				var down_left: bool

				up = (i - 1 < 0) || (this.map[i - 1][j] == Tile.WALL)
				down = (i + 1 >= len(this.map)) || (this.map[i + 1][j] == Tile.WALL)
				left = (j - 1 < 0) || (this.map[i][j - 1] == Tile.WALL)
				right = (j + 1 >= len(this.map[i])) || (this.map[i][j + 1] == Tile.WALL)

				# Diagonales
				up_left = (i - 1 < 0 || j - 1 < 0) || (this.map[i - 1][j - 1] == Tile.WALL)
				up_right = (i - 1 < 0 || j + 1 >= len(this.map[i])) || (this.map[i - 1][j + 1] == Tile.WALL)
				down_left = (i + 1 >= len(this.map) || j - 1 < 0) || (this.map[i + 1][j - 1] == Tile.WALL)
				down_right = (i + 1 >= len(this.map) || j + 1 >= len(this.map[i])) || (this.map[i + 1][j + 1] == Tile.WALL)

				if up && down && left && right && up_right && up_left && down_right && down_left
					this.map_opti[i][j] = '  ' # Full wall
				elseif !up && !left && right && down
					this.map_opti[i][j] = '╭─'
				elseif !down && !left && right && up
					this.map_opti[i][j] = '╰─'
				elseif !up && !right && left && down
					this.map_opti[i][j] = '─╮'
				elseif !down && !left && right && up
					this.map_opti[i][j] = '╰─'
				elseif !down && !right && left && up
					this.map_opti[i][j] = '─╯'
				elseif !down || !up
					this.map_opti[i][j] = '──'
				elseif !left && right
					this.map_opti[i][j] = '│ '
				elseif left && !right
					this.map_opti[i][j] = ' │'
				elseif down && right && !down_right
					this.map_opti[i][j] = ' ╭'
				elseif up && right && !up_right
					this.map_opti[i][j] = ' ╰'
				elseif down && left && !down_left
					this.map_opti[i][j] = '╮ '
				elseif up && left && !up_left
					this.map_opti[i][j] = '╯ '
				else
					this.map_opti[i][j] = '⬜️'
				endif
			endfor
		endfor

		if this.timer_ghost != 0
			timer_stop(this.timer_ghost)
			this.timer_ghost = 0
		endif

		this.timer_ghost = timer_start(100, (_) => {
			for g in this.ghosts
				g.last_x = g.x
				g.last_y = g.y

				if g.IsEaten()
					# Move to cage
					g.GhostMoveToGoal(this.map, this.cage_pos[0], this.cage_pos[1])
					var rnd = rand() % 3
					if rnd >= 1 && rnd <= 2
						g.GhostMoveToGoal(this.map, this.cage_pos[0], this.cage_pos[1])
					endif
					# Check if reached cage
					if g.x >= this.cage_pos[0] - 1 && g.x <= this.cage_pos[0] + 1 && g.y >= this.cage_pos[1] - 1 && g.y <= this.cage_pos[1] + 1
						g.SetChase()
					endif
				elseif g.IsFrightened()
					var rnd = rand() % 3
					if rnd >= 1 && rnd <= 2
						g.GhostMoveFrightened(this.map, this.player)
					endif
				elseif g.IsNormal() || g.IsFrightened()
					g.GhostMove(this.map, this.player)
				endif

				if g.last_x == g.x && g.last_y == g.y
					g.is_block += 1
				else
					g.is_block = 0
				endif
				if g.y == this.player.y && g.x == this.player.x
					if g.IsNormal() 
						this.GameOver()
					elseif g.IsFrightened()
						this.IncreaseScore(200)
						g.SetEaten()
					endif
				endif
			endfor
		}, {repeat: -1})
	enddef


	################################
	## Increase Score
	################################
	def IncreaseScore(amount: number)
		this.score += amount
	enddef

	###############################
	## Game Over Logic
	###############################
	def GameOver()
		this.highscore = max([this.highscore, this.score])
		g:SUPRA_PACMAN_HIGHSCORE = this.highscore
		this.ChangeActivity(Activity.GAMEOVER)
	enddef

	###############################
	## Replay Game
	## When the game is over or player wants to restart
	###############################
	def Replay()
		this.score = 0
		this.level_num = this.level_min
		this.InitGame()
	enddef

	##############################
	## Key Filter
	## Handles key inputs based on current this.activity
	##############################
	def KeyFilter(wid: number, key: string): number
		# Play Activity
		if this.activity == Activity.PLAY
			if key ==? 'w' || key == "\<up>" || key == "k"
				this.player.dir_save = Dir.UP
				return 1
			elseif key ==? 's' || key == "\<down>" || key == "j"
				this.player.dir_save = Dir.DOWN
				return 1
			elseif key ==? 'a' || key == "\<left>" || key == "h"
				this.player.dir_save = Dir.LEFT
				return 1
			elseif key ==? 'd' || key == "\<right>" || key == "l"
				this.player.dir_save = Dir.RIGHT
			endif
		# Menu Activity
		elseif this.activity == Activity.MENU
			if key ==? "\<Enter>"
				this.Replay()
			elseif key ==? "\<LeftMouse>" || key ==? "\<2-LeftMouse>" || key ==? "\<3-LeftMouse>" || key ==? "\<4-LeftMouse>" || key ==? "\<5-LeftMouse>"
				const value = Utils.HandleClickPopup(wid, ['Play', 'Quit'])
				if value == 0
					this.Replay()
				elseif value == 1
					this.Close()
				endif
			endif
		elseif this.activity == Activity.NEXTLEVEL
			if key ==? "\<Enter>"
				this.level_num += 1
				this.InitGame()
				return 1
			elseif key ==? "\<LeftMouse>" || key ==? "\<2-LeftMouse>" || key ==? "\<3-LeftMouse>" || key ==? "\<4-LeftMouse>" || key ==? "\<5-LeftMouse>"
				const value = Utils.HandleClickPopup(wid, ['Next Level', 'Quit'])
				if value == 0
					this.level_num += 1
					this.InitGame()
				elseif value == 1
					this.Close()
				endif
			endif
		elseif this.activity == Activity.GAMEOVER
			if key ==? "\<Enter>"
				this.Replay()
				return 1
			elseif key ==? "\<LeftMouse>" || key ==? "\<2-LeftMouse>" || key ==? "\<3-LeftMouse>" || key ==? "\<4-LeftMouse>" || key ==? "\<5-LeftMouse>"
				const value = Utils.HandleClickPopup(wid, ['Retry', 'Quit'])
				if value == 0
					this.Replay()
				elseif value == 1 
					this.Close()
					return 0
				endif
			endif
		endif

		# All Activity
		if key == 'q' || key == 'Q' || key == "\<esc>"
			this.Close()
		endif
		return 1
	enddef

	##############################
	## Draw Game in the Popup
	##############################
	def DrawGame()
		var print_map = []
		this.DrawScore(print_map)

		# Draw player
		this.map[this.player.y][this.player.x] = Tile.PACMAN
		# draw ghost
		for g in this.ghosts
			# Check for ghost collision
			if g.y == this.player.y && g.x == this.player.x
				if g.IsFrightened()
					this.score += 200
					g.SetEaten()
				elseif g.IsNormal() 
					this.GameOver()
				endif
			endif
			this.map[g.y][g.x] = g.id
		endfor

		for i in range(this.len_map)
			var line_chars: list<string> = []
			for j in range(this.len_map_x)
				const value = this.map[i][j]
				if value == Tile.WALL
					add(line_chars, this.map_opti[i][j])
				elseif value == Tile.EMPTY
					add(line_chars, SPRITE_LOOKUP[this.lst_entity[i][j]])
				else
					add(line_chars, SPRITE_LOOKUP[value])
				endif
			endfor
			add(print_map, join(line_chars, ''))
		endfor
		popup_settext(this.popup, print_map)
	enddef



	##############################
	## Clear the Map
	##############################
	def Clear()
		# clear all ghost from map
		for g in this.ghosts
			this.map[g.y][g.x] = Tile.EMPTY
		endfor
		# clear player from map
		this.map[this.player.y][this.player.x] = Tile.EMPTY
	enddef



	##############################
	## Update Game Logic
	##############################
	def UpdateGame()
		const old_x = this.player.x
		const old_y = this.player.y
		var new_x = this.player.x
		var new_y = this.player.y

		if this.player.dir_save == Dir.DOWN
			var p_y = this.player.y + 1
			if p_y >= this.len_map
				p_y = 0
			endif
			if this.map[p_y][this.player.x] != Tile.WALL
				this.player.dir = Dir.DOWN
			endif
		elseif this.player.dir_save == Dir.UP
			var p_y = this.player.y - 1
			if p_y < 0
				p_y = this.len_map - 1
			endif
			if this.map[p_y][this.player.x] != Tile.WALL
				this.player.dir = Dir.UP
			endif
		elseif this.player.dir_save == Dir.LEFT
			var p_x = this.player.x - 1
			if p_x < 0
				p_x = this.len_map_x - 1
			endif
			if this.map[this.player.y][p_x] != Tile.WALL
				this.player.dir = Dir.LEFT
			endif
		elseif this.player.dir_save == Dir.RIGHT
			var p_x = this.player.x + 1
			if p_x >= this.len_map_x
				p_x = 0
			endif
			if this.map[this.player.y][p_x] != Tile.WALL
				this.player.dir = Dir.RIGHT
			endif
		else
			this.player.dir = this.player.dir_save
		endif

		# Update this.player based on dir
		if this.player.dir == Dir.UP
			new_y = this.player.y - 1
		elseif this.player.dir == Dir.DOWN
			new_y = this.player.y + 1
		elseif this.player.dir == Dir.LEFT
			new_x = this.player.x - 1
		elseif this.player.dir == Dir.RIGHT
			new_x = this.player.x + 1
		endif

		# if the player hit the bound of the this.map, teleport him to the other side
		if new_x < 0
			new_x = this.len_map_x - 1
		elseif new_x >= this.len_map_x
			new_x = 0
		endif
		if new_y < 0
			new_y = this.len_map - 1
		elseif new_y >= this.len_map
			new_y = 0
		endif

		# Check for wall collision
		if this.map[new_y][new_x] == Tile.WALL
			this.player.SetPosition(old_x, old_y)
			return
		endif

		# Move the player
		this.player.SetPosition(new_x, new_y)

		const e_under_pacman = this.lst_entity[new_y][new_x]

		if e_under_pacman == Tile.SIMPLE
			this.IncreaseScore(10)
			this.lst_entity[new_y][new_x] = Tile.EMPTY
			this.remain_food -= 1
			if this.remain_food == 0
				# Win the game
				this.highscore = max([this.highscore, this.score])
				g:SUPRA_PACMAN_HIGHSCORE = this.highscore
				this.ChangeActivity(Activity.NEXTLEVEL)
			endif
		elseif e_under_pacman == Tile.PACGOMME
			this.IncreaseScore(50)
			this.lst_entity[new_y][new_x] = Tile.EMPTY
			# Set all ghosts to FRIGHTENED
			for g in this.ghosts
				g.SetFrightened()
			endfor
		# FOOD1 to FOOD8
		elseif e_under_pacman >= Tile.FOOD1 && e_under_pacman <= Tile.FOOD8
			this.IncreaseScore(100 * (e_under_pacman - Tile.FOOD1 + 1))
			this.lst_entity[new_y][new_x] = Tile.EMPTY
		endif
	enddef


	###############################
	## Draw Scoreboard
	###############################
	def DrawScore(map_print: list<string>, is_over: bool = 0)
		const width_2 = Const.width / 2 - 14

		add(map_print, printf(' ╭─────────────╮ ╭─────────────╮%*s╭───────────────────╮', width_2, ' '))
		add(map_print, printf(' │%-10d💰 │ │%-10d🏆 │%*s│ 󰮯  Supra Pac-Man  │', this.score, this.highscore, width_2, ' '))
		add(map_print, printf(' ╰─────────────╯ ╰─────────────╯%*s╰───────────────────╯', width_2, ' '))
	enddef



	###############################
	## Draw Menu Screen
	###############################
	def DrawMenu()

		const ascii_txt = [
	'████████   ██████    ██████     █████████████    ██████   ████████',
	'░███░░███  ░░░░███  ███░░███    ░███░░███░░███   ░░░░███  ░███░░███',
	'░███ ░███  ███████ ░███ ░░░     ░███ ░███ ░███   ███████  ░███ ░███',
	'░███ ░███ ███░░███ ░███  ███    ░███ ░███ ░███  ███░░███  ░███ ░███',
	'░███████ ░░████████░░██████     █████░███ █████░░████████ ████ █████',
	'░███░░░   ░░░░░░░░  ░░░░░░     ░░░░░ ░░░ ░░░░░  ░░░░░░░░ ░░░░ ░░░░░',
	'░███',
	'█████',
	'░░░░░', '']

		var str = ['', '']
		# Center it with strcharlen of ascii_txt
		const space_center = repeat(' ', (Const.width / 2) - (strcharlen(ascii_txt[0]) / 2))
		for i in range(len(ascii_txt))
			add(str, space_center .. ascii_txt[i])
		endfor
		add(str, '')
		add(str, '')

		# Create a button Play with ╭ and ╮

		const button_play = [
			'╭────────────────────────────────────╮',
			'│         󰮯   Play Pac-man           │',
			'╰────────────────────────────────────╯']
		const button_quit = [
			'╭────────────────────────────────────╮',
			'│               Quit                │',
			'╰────────────────────────────────────╯']
		const space_center_btn = repeat(' ', (Const.width / 2) - (strcharlen(button_play[0]) / 2))

		for i in range(len(button_play))
			add(str, space_center_btn .. button_play[i])
		endfor

		for i in range(len(button_quit))
			add(str, space_center_btn .. button_quit[i])
		endfor

		popup_settext(this.popup, str)
	enddef


	###############################
	## Game Over Screen
	################################
	def DrawGameOver()
		const ascii_txt = [
		'  ░██████                                        ',
		' ░██   ░██                                       ',
		'░██         ░██████   ░█████████████   ░███████  ',
		'░██  █████       ░██  ░██   ░██   ░██ ░██    ░██ ',
		'░██     ██  ░███████  ░██   ░██   ░██ ░█████████ ',
		' ░██  ░███ ░██   ░██  ░██   ░██   ░██ ░██        ',
		'  ░█████░█  ░█████░██ ░██   ░██   ░██  ░███████  ',
		'                                                 ',
		'        ░████',
		'     ░██   ░██',
		'    ░██     ░██ ░██    ░██  ░███████  ░██░████',
		'    ░██     ░██ ░██    ░██ ░██    ░██ ░███',
		'    ░██     ░██  ░██  ░██  ░█████████ ░██',
		'     ░██   ░██    ░██░██   ░██        ░██',
		'      ░██████      ░███     ░███████  ░██',
		'']

		const space_center = repeat(' ', (Const.width / 2) - (strcharlen(ascii_txt[0]) / 2))
		var gameover = []

		add(gameover, '')
		for i in range(len(ascii_txt))
			add(gameover, space_center .. ascii_txt[i])
		endfor
		add(gameover, '')

		# Add Retry Button
		const button_retry = [
			'╭────────────────────────────────────╮',
			'│                Retry               │',
			'╰────────────────────────────────────╯']
		const button_quit = [
			'╭────────────────────────────────────╮',
			'│                Quit                │',
			'╰────────────────────────────────────╯']
		const space_center_btn = repeat(' ', (Const.width / 2) - (strcharlen(button_retry[0]) / 2))
		for i in range(len(button_retry))
			add(gameover, space_center_btn .. button_retry[i])
		endfor
		for i in range(len(button_quit))
			add(gameover, space_center_btn .. button_quit[i])
		endfor
		# Print the highscore and Score
		var highscore_str = '🏆 Highscore: ' .. this.highscore
		var score_str = '💰 Score: ' .. this.score
		var txt_len = len(gameover)
		# Add space When the height is atteint
		for i in range(txt_len, Const.height - 2)
			add(gameover, '')
		endfor
		add(gameover, score_str)
		add(gameover, highscore_str)

		popup_settext(this.popup, gameover)
	enddef


	###############################
	## Next Level Screen
	################################
	def DrawNextLevel()
		const ascii_txt = [
	' ',
	'░██       ░█████████ ░██    ░██ ░█████████ ░██',
	'░██       ░██        ░██    ░██ ░██        ░██',
	'░██       ░██        ░██    ░██ ░██        ░██',
	'░██       ░█████████ ░██    ░██ ░████████  ░██',
	'░██       ░██         ░██  ░██  ░██        ░██',
	'░██       ░██          ░██░██   ░██        ░██',
	'░████████ ░█████████    ░███    ░█████████ ░████████',
	'',
	'',
	'',
	'  ░██████  ░██       ░█████████    ░███    ░█████████',
	' ░██   ░██ ░██       ░██          ░██░██   ░██     ░██',
	'░██        ░██       ░██         ░██  ░██  ░██     ░██',
	'░██        ░██       ░████████  ░█████████ ░█████████',
	'░██        ░██       ░██        ░██    ░██ ░██   ░██',
	' ░██   ░██ ░██       ░██        ░██    ░██ ░██    ░██',
	'  ░██████  ░████████ ░█████████ ░██    ░██ ░██     ░██',
	'', '', '']

		# add a button 'Next Level' and 'Quit'
		const button_next = [
			'╭────────────────────────────────────╮',
			'│             Next Level             │',
			'╰────────────────────────────────────╯']
		const button_quit = [
			'╭────────────────────────────────────╮',
			'│                Quit                │',
			'╰────────────────────────────────────╯']
		# use printf to center the ascii art
		const space_center = repeat(' ', (Const.width / 2) - (strcharlen(ascii_txt[1]) / 2))
		var button = []
		for i in range(len(ascii_txt))
			add(button, space_center .. ascii_txt[i])
		endfor
		const space_center_btn = repeat(' ', (Const.width / 2) - (strcharlen(button_next[0]) / 2))
		for i in range(len(button_next))
			add(button, space_center_btn .. button_next[i])
		endfor
		for i in range(len(button_quit))
			add(button, space_center_btn .. button_quit[i])
		endfor
		# Print the highscore and Score
		const highscore_str = '🏆 Highscore: ' .. this.highscore
		const score_str = '💰 Score: ' .. this.score
		const txt_len = len(button)
		# Add space When the height is atteint
		for i in range(txt_len, Const.height - 2)
			add(button, '')
		endfor
		add(button, score_str)
		add(button, highscore_str)
		popup_settext(this.popup, button)
	enddef

	# When all levels are completed
	def DrawCongratulations()
		const ascii_txt = [' ',
			'  ░██████',
			' ░██   ░██',
			'░██         ░██    ░██ ░████████  ░██░████  ░██████',
			' ░████████  ░██    ░██ ░██    ░██ ░███           ░██',
			'        ░██ ░██    ░██ ░██    ░██ ░██       ░███████',
			' ░██   ░██  ░██   ░███ ░███   ░██ ░██      ░██   ░██',
			'  ░██████    ░█████░██ ░██░█████  ░██       ░█████░██',
			'                       ░██',
			'                       ░██',
			' ',
			'          ░████████ ░███    ░██ ░███████  ',
			'          ░██       ░████   ░██ ░██   ░██ ',
			'          ░██       ░██░██  ░██ ░██    ░██',
			'          ░███████  ░██ ░██ ░██ ░██    ░██',
			'          ░██       ░██  ░██░██ ░██    ░██',
			'          ░██       ░██   ░████ ░██   ░██ ',
			'          ░████████ ░██    ░███ ░███████  '
		]

		# affiche le score final et le highscore
		var str = ['', '']
		# Center it with strcharlen of ascii_txt
		const space_center = repeat(' ', (Const.width / 2) - (strcharlen(ascii_txt[4]) / 2))
		for i in range(len(ascii_txt))
			add(str, space_center .. ascii_txt[i])
		endfor
		add(str, '')
		add(str, '')
		const score_str = '💰 Final Score: ' .. this.score
		const highscore_str = '🏆 Highscore: ' .. this.highscore
		add(str, score_str)
		add(str, highscore_str)
		popup_settext(this.popup, str)
	enddef
endclass
