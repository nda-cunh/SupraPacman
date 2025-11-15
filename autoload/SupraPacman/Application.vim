vim9script

################################
## Const and Variables
################################

var t_ve: string
var hlcursor: dict<any>

# Window size
const width = 80
const height = 30

# Activity states
const MENU = 0
const PLAY = 1
const GAMEOVER = 2
const NEXTLEVEL = 3
const CONGRATULATIONS = 4

# Map constants
const EMPTY = 0
const WALL = 1
const PACMAN = 2
const GHOST_EAT = 3
const BLINKY = 4
const PINKY = 5
const INKY = 6
const CLYDE = 7
const SIMPLE = 8
const PACGOMME = 9
const FOOD1 = 10
const FOOD2 = 11
const FOOD3 = 12
const FOOD4 = 13
const FOOD5 = 14
const FOOD6 = 15
const FOOD7 = 16
const FOOD8 = 17
const GHOST_DEAD = 18
const CAGE = 19

# All the sprites used in the game
const SPRITE_LOOKUP = [
    '  ', '⬛️', '󰮯 ', '🟦', '🟥', '🟪', '🟩', '🟨', '🔸', '🔶', '🍒', '🍓', '🍊', '🍎', '🍉', '🛸', '🔔', '🔑', '👀', '  '
]

# DIRECTION
type Direction = number

const UP: Direction = 1
const LEFT: Direction = 2
const DOWN: Direction = 3
const RIGHT: Direction = 4
const NONE: Direction = 99



####################################
## Pacman class
## It's the player class
#####################################
class Pacman
	public var y: number
	public var x: number
	public var dir: Direction
	public var dir_save: Direction

	def new(y: number, x: number, dir: Direction)
		this.y = y
		this.x = x
		this.dir = NONE
		this.dir_save = NONE
	enddef

	def SetPosition(x: number, y: number)
		this.y = y
		this.x = x
	enddef
endclass

##############################
## Ghost class
##############################

abstract class Ghost
	# Ghost properties
	public var y: number
	public var x: number
	public var last_y: number
	public var last_x: number
	public var dir: Direction
	public var walk_on: number
	public var state: number
	public var id: number
	public var real_id: number
	public var is_block = 0
	var timer_isblue = 0

	# Constant for states
	public static const CHASE: number = 0  # 🟥
	public static const SCATTER: number = 1 # 🟥 (but not attack)
	public static const FRIGHTENED: number = 2  # 🟦
	public static const EATEN: number = 3  # 👀

	##############################
	## Constructor
	##############################
	def Ghost(dir: Direction, walk_on: number, state: number, id: number)
		this.dir = dir
		this.walk_on = walk_on
		this.state = state
		this.id = id
		this.real_id = id
	enddef


	###########################
	## Set Position
	###########################
	def SetPosition(x: number, y: number)
		this.y = y
		this.x = x
	enddef


	###########################
	## Path Finding Algorithm
	###########################
	def PathFinding(map: list<list<number>>, target_x: number, target_y: number)
		var possible_dirs: list<Direction> = []

		var width_max = len(map[0])
		var height_max = len(map)

		# --- UP 
		if this.y > 0 && map[this.y - 1][this.x] != WALL && this.dir != DOWN
			add(possible_dirs, UP)
		endif

		# --- DOWN 
		if this.y < height_max - 1 && map[this.y + 1][this.x] != WALL && this.dir != UP
			add(possible_dirs, DOWN)
		endif

		# --- LEFT 
		var left_x = this.x - 1
		if left_x < 0
			left_x = width_max - 1
		endif
		if map[this.y][left_x] != WALL && this.dir != RIGHT
			add(possible_dirs, LEFT)
		endif

		# --- RIGHT 
		var right_x = this.x + 1
		if right_x >= width_max
			right_x = 0
		endif
		if map[this.y][right_x] != WALL && this.dir != LEFT
			add(possible_dirs, RIGHT)
		endif

		if len(possible_dirs) == 1
			this.Move(possible_dirs[0], map)
			this.dir = possible_dirs[0]
			return 
		endif

		var best_dir: Direction = NONE
		var best_dist = 999999.0

		for dir in possible_dirs
			var new_x = this.x
			var new_y = this.y

			if dir == UP
				new_y = this.y - 1
			elseif dir == DOWN
				new_y = this.y + 1
			elseif dir == LEFT
				new_x = this.x - 1
			elseif dir == RIGHT
				new_x = this.x + 1
			endif

			var dist = pow((target_y - new_y), 2) + pow((target_x - new_x), 2)

			if dist < best_dist
				best_dist = dist
				best_dir = dir
			elseif dist == best_dist
				if dir < best_dir
					best_dist = dist
					best_dir = dir
				endif
			endif
		endfor

		if best_dir != NONE
			this.Move(best_dir, map)
			this.dir = best_dir
		endif
	enddef

	def IsBlocked(): bool
		return this.is_block >= 4
	enddef

	###########################
	## Check if the ghost is eaten
	###########################
	def IsEaten(): bool
		return this.state == Ghost.EATEN
	enddef

	def IsFrightened(): bool
		return this.state == Ghost.FRIGHTENED
	enddef

	# def IsScatter(): bool
		# return this.state == Ghost.SCATTER
	# enddef

	def IsChase(): bool
		return this.state == Ghost.CHASE
	enddef

	###########################
	## State Setters
	###########################
	def SetChase()
		this.state = Ghost.CHASE
		this.id = this.real_id
	enddef

	# def SetScatter() # Not used now
		# this.state = Ghost.SCATTER
		# this.id = this.real_id
	# enddef

	def SetFrightened() # BLUE
		if this.state == Ghost.CHASE || this.state == Ghost.SCATTER || this.state == Ghost.FRIGHTENED
			if this.timer_isblue != 0
				timer_stop(this.timer_isblue)
			endif
			this.timer_isblue = timer_start(8000, (_) => {
				if this.state == Ghost.FRIGHTENED
					this.SetChase()
				endif
				this.timer_isblue = 0
			}, {repeat: 0})
		endif
		this.state = Ghost.FRIGHTENED
		this.id = GHOST_EAT
	enddef

	def SetEaten()
		this.state = Ghost.EATEN
		this.id = GHOST_DEAD
	enddef

	###########################
	## Move Ghost
	###########################
	def Move(dir: Direction, map: list<list<number>>)
		var new_x = this.x
		var new_y = this.y
		if dir == UP
			new_y = this.y - 1
		elseif dir == DOWN
			new_y = this.y + 1
		elseif dir == LEFT
			new_x = this.x - 1
		elseif dir == RIGHT
			new_x = this.x + 1
		endif

		# if the ghost hit the bound of the this.map, teleport him to the other side
		if new_x < 0
			new_x = len(map[0]) - 1
		elseif new_x >= len(map[0])
			new_x = 0
		endif
		if new_y < 0
			new_y = len(map) - 1
		elseif new_y >= len(map)
			new_y = 0
		endif

		if map[new_y][new_x] != WALL
			map[this.y][this.x] = EMPTY
			this.x = new_x
			this.y = new_y

			map[this.y][this.x] = this.id
		endif
		if this.last_x == this.x && this.last_y == this.y
			this.is_block = 0
		else
			this.is_block += 1
		endif
	enddef


	abstract def GhostMove(map: list<list<number>>, pacman: Pacman)
	def GhostMoveToGoal(map: list<list<number>>, cage_x: number, cage_y: number)
		var ghost = this
		var target_x = cage_x
		var target_y = cage_y

		if ghost.IsBlocked()
			ghost.dir = NONE
		endif
		this.PathFinding(map, target_x, target_y)
	enddef

	# Move when ghost is blue (frightened)
	def GhostMoveFrightened(map: list<list<number>>, pacman: Pacman)
		var ghost = this
		var target_x: number
		var target_y: number

		# Move away from pacman
		if ghost.x < pacman.x
			target_x = 0
		else
			target_x = len(map[0]) - 1
		endif
		if ghost.y < pacman.y
			target_y = 0
		else
			target_y = len(map) - 1
		endif
		if ghost.IsBlocked()
			ghost.dir = NONE
		endif
		this.PathFinding(map, target_x, target_y)
	enddef
endclass

class PinkyGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, walk_on: number, state: number, id: number)
		super.Ghost(dir, walk_on, state, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		var pinky = this
		var target_y: number
		var target_x: number

		if pacman.dir == UP
			target_y = pacman.y - 4
			target_x = pacman.x
		elseif pacman.dir == DOWN
			target_y = pacman.y + 4
			target_x = pacman.x
		elseif pacman.dir == LEFT
			target_y = pacman.y
			target_x = pacman.x - 4
		elseif pacman.dir == RIGHT
			target_y = pacman.y
			target_x = pacman.x + 4
		else
			target_y = pacman.y
			target_x = pacman.x
		endif

		if pinky.IsBlocked()
			pinky.dir = NONE
		endif
		super.PathFinding(map, target_x, target_y)
	enddef
endclass

class ClydeGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, walk_on: number, state: number, id: number)
		super.Ghost(dir, walk_on, state, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		var clyde = this
		var target_x: number
		var target_y: number

		if clyde.IsBlocked()
			clyde.dir = NONE
		endif

		if sqrt(pow((clyde.y - pacman.y), 2) + pow((clyde.x - pacman.x), 2)) < 9.0
			target_y = pacman.y
			target_x = pacman.x
		else
			target_y = 0
			target_x = len(map[0]) - 1
		endif
		super.PathFinding(map, target_x, target_y)
	enddef
endclass


class InkyGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, walk_on: number, state: number, id: number)
		super.Ghost(dir, walk_on, state, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		var clyde = this
		var target_x: number
		var target_y: number

		if clyde.IsBlocked()
			clyde.dir = NONE
		endif
		if sqrt(pow((clyde.y - pacman.y), 2) + pow((clyde.x - pacman.x), 2)) < 9.0
			target_y = pacman.y
			target_x = pacman.x
		else
			target_y = 0
			target_x = 0
		endif
		super.PathFinding(map, target_x, target_y)
	enddef
endclass


class BlinkyGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, walk_on: number, state: number, id: number)
		super.Ghost(dir, walk_on, state, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		var blinky = this
		var target_x = pacman.x
		var target_y = pacman.y

		if blinky.IsBlocked()
			blinky.dir = NONE
		endif

		super.PathFinding(map, target_x, target_y)
	enddef
endclass

export class Application
	var timer: number
	var popup: number
	var player: Pacman
	var score: number
	var highscore: number
	var activity = MENU
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

	##############################
	## Constructor
	##############################
	def new(directories: string, level_chose: number)
		this.directory_level = directories
		this.level_min = level_chose
		HideCursor()
		this.InitializePopup()
		this.ChangeActivity(MENU)
		# count number of levels in directory
		var files = split(globpath(this.directory_level, '*.level'), '\n')
		this.nb_levels = len(files)
	enddef

	def Close()
		if this.timer != 0
			timer_stop(this.timer)
			this.timer = 0
		endif
		if this.timer_ghost != 0
			timer_stop(this.timer_ghost)
			this.timer_ghost = 0
		endif
		ShowCursor()
		popup_close(this.popup)
	enddef

	##############################
	## Initialize Popup Window
	## Sets up the popup window with desired settings
	##############################
	def InitializePopup()
		# const pos = line('w0')
		# call cursor(pos, 1)

		this.popup = popup_create([], {
			borderhighlight: ['Normal', 'Normal', 'Normal', 'Normal'],
			borderchars: ['─', '│', '─', '│', '╭', '╮', '╯', '╰'],
			highlight: 'Normal',
			border: [1],
			minwidth: width,
			minheight: height,
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


	def Run()
		if this.timer != 0
			timer_stop(this.timer)
		endif

		this.timer = timer_start(70, (_) => {
			if this.activity == PLAY
				this.Clear()
				this.UpdateGame()
				# this.Draw()
				this.DrawGame()
			elseif this.activity == MENU
				this.DrawMenu()
			elseif this.activity == GAMEOVER
				this.DrawGameOver()
			elseif this.activity == NEXTLEVEL
				this.DrawNextLevel()
			elseif this.activity == CONGRATULATIONS
				this.DrawCongratulations()
			endif
		}, {repeat: -1})
	enddef

	def ChangeActivity(new_activity: number)
		this.activity = new_activity

		const bufnr = winbufnr(this.popup)
		if this.activity == PLAY
			setbufvar(bufnr, '&filetype', 'suprapacmangame')
		elseif this.activity == MENU
			setbufvar(bufnr, '&filetype', 'suprapacman')
		elseif this.activity == GAMEOVER
			setbufvar(bufnr, '&filetype', 'suprapacman')
		elseif this.activity == NEXTLEVEL
			# stop move ghost timer
			if this.timer_ghost != 0
				timer_stop(this.timer_ghost)
			endif
			setbufvar(bufnr, '&filetype', 'suprapacman')
		elseif this.activity == CONGRATULATIONS
			# stop move ghost timer
			if this.timer_ghost != 0
				timer_stop(this.timer_ghost)
			endif
			setbufvar(bufnr, '&filetype', 'suprapacman')
		endif
	enddef

	def LoadMapFromFile(file_path: string): list<list<number>>
		const lines = readfile(file_path)
		# the format is just number separate by space
		# and each line is a new row
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
			this.ChangeActivity(CONGRATULATIONS)
			return
		endif

		this.remain_food = 0
		this.player = Pacman.new(15, 15, NONE)
		this.ChangeActivity(PLAY)
		this.highscore = g:SUPRA_PACMAN_HIGHSCORE

		const width_max = width / 2
		const height_max = height

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
		level = this.LoadMapFromFile(this_level_file)
		for i in level 
			var line = []
			for j in i
				if j == PACMAN
					this.player.SetPosition(len(line), len(this.map))
				elseif j == BLINKY
					var new_ghost = BlinkyGhost.new(NONE, EMPTY, Ghost.CHASE, BLINKY)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == PINKY
					var new_ghost = PinkyGhost.new(NONE, EMPTY, Ghost.CHASE, PINKY)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == INKY
					var new_ghost = InkyGhost.new(NONE, EMPTY, Ghost.CHASE, INKY)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == CLYDE
					var new_ghost = ClydeGhost.new(NONE, EMPTY, Ghost.CHASE, CLYDE)
					new_ghost.SetPosition(len(line), len(this.map))
					add(this.ghosts, new_ghost)
				elseif j == CAGE
					this.cage_pos = [len(line), len(this.map)]
				elseif j == SIMPLE
					this.remain_food += 1
				endif
				add(line, j)
			endfor
			add(this.map, line)
			add(this.lst_entity, copy(line))
		endfor

		# Clear ghost from map
		for g in this.ghosts
			this.map[g.y][g.x] = EMPTY
		endfor

		# Clear player from map
		this.map[this.player.y][this.player.x] = EMPTY



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
				if e[j] == SIMPLE || e[j] == PACGOMME || (e[j] >= FOOD1 && e[j] <= FOOD8)
					this.map[n][j] = EMPTY # if there's an entity
				else
					e[j] = EMPTY
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

				up = (i - 1 < 0) || (this.map[i - 1][j] == WALL)
				down = (i + 1 >= len(this.map)) || (this.map[i + 1][j] == WALL)
				left = (j - 1 < 0) || (this.map[i][j - 1] == WALL)
				right = (j + 1 >= len(this.map[i])) || (this.map[i][j + 1] == WALL)

				# Diagonales
				up_left = (i - 1 < 0 || j - 1 < 0) || (this.map[i - 1][j - 1] == WALL)
				up_right = (i - 1 < 0 || j + 1 >= len(this.map[i])) || (this.map[i - 1][j + 1] == WALL)
				down_left = (i + 1 >= len(this.map) || j - 1 < 0) || (this.map[i + 1][j - 1] == WALL)
				down_right = (i + 1 >= len(this.map) || j + 1 >= len(this.map[i])) || (this.map[i + 1][j + 1] == WALL)

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
				elseif g.IsChase() || g.IsFrightened() # TODO || g.IsScatter()
					g.GhostMove(this.map, this.player)
				endif

				if g.last_x == g.x && g.last_y == g.y
					g.is_block += 1
				else
					g.is_block = 0
				endif
				if g.y == this.player.y && g.x == this.player.x
					if g.IsChase() # TODO || g.IsScatter()
						this.GameOver()
					elseif g.IsFrightened()
						this.IncreaseScore(200)
						g.SetEaten()
					endif
				endif
			endfor
		}, {repeat: -1})
	enddef


	def IncreaseScore(amount: number)
		this.score += amount
	enddef

	###############################
	## Game Over Logic
	###############################
	def GameOver()
		this.highscore = max([this.highscore, this.score])
		g:SUPRA_PACMAN_HIGHSCORE = this.highscore
		this.ChangeActivity(GAMEOVER)
	enddef

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
		if this.activity == PLAY
			if key ==? 'w' || key == "\<up>" || key == "k"
				this.player.dir_save = UP
				return 1
			elseif key ==? 's' || key == "\<down>" || key == "j"
				this.player.dir_save = DOWN
				return 1
			elseif key ==? 'a' || key == "\<left>" || key == "h"
				this.player.dir_save = LEFT
				return 1
			elseif key ==? 'd' || key == "\<right>" || key == "l"
				this.player.dir_save = RIGHT
				return 1
			endif
		# Menu Activity
		elseif this.activity == MENU
			if key ==? "\<Enter>"
				this.Replay()
			elseif key ==? "\<LeftMouse>" || key ==? "\<2-LeftMouse>" || key ==? "\<3-LeftMouse>" || key ==? "\<4-LeftMouse>" || key ==? "\<5-LeftMouse>"
				var bufnr = winbufnr(wid)
				var pos = getmousepos()
				if pos.winid != wid
					return 0
				endif
				try
				var line = getbufline(bufnr, pos.winrow - 2, pos.winrow + 1)
				for i in line
					if stridx(i, 'Play') != -1
						this.Replay()
						this.ChangeActivity(PLAY)
						break
					elseif stridx(i, 'Quit') != -1
						this.Close()
						return 0
					endif
				endfor
				catch
				endtry
				return 1
			endif
		elseif this.activity == NEXTLEVEL
			if key ==? "\<Enter>"
				this.level_num += 1
				this.InitGame()
				return 1
			elseif key ==? "\<LeftMouse>" || key ==? "\<2-LeftMouse>" || key ==? "\<3-LeftMouse>" || key ==? "\<4-LeftMouse>" || key ==? "\<5-LeftMouse>"
				var bufnr = winbufnr(wid)
				var pos = getmousepos()
				if pos.winid != wid
					return 0
				endif
				try
					var line = getbufline(bufnr, pos.winrow - 2, pos.winrow + 1)
					for i in line
						if stridx(i, 'Next Level') != -1
							this.level_num += 1
							this.InitGame()
							break
						elseif stridx(i, 'Quit') != -1
							this.Close()
							return 0
						endif
					endfor
				catch
				endtry
				return 1
			endif
		elseif this.activity == GAMEOVER
			if key ==? "\<Enter>"
				this.Replay()
				return 1
			elseif key ==? "\<LeftMouse>" || key ==? "\<2-LeftMouse>" || key ==? "\<3-LeftMouse>" || key ==? "\<4-LeftMouse>" || key ==? "\<5-LeftMouse>"
				var bufnr = winbufnr(wid)
				var pos = getmousepos()
				if pos.winid != wid
					return 0
				endif
				try
					var line = getbufline(bufnr, pos.winrow - 2, pos.winrow + 1)
					for i in line
						if stridx(i, 'Retry') != -1
							this.Replay()
							break
						elseif stridx(i, 'Quit') != -1
							this.Close()
							return 0
						endif
					endfor
				catch
				endtry
				return 1
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

		# draw all entities

		this.map[this.player.y][this.player.x] = PACMAN
		# draw ghost
		for g in this.ghosts
			# Check for ghost collision
			if g.y == this.player.y && g.x == this.player.x
				if g.IsFrightened()
					this.score += 200
					g.SetEaten()
				elseif g.IsChase() # TODO || g.IsScatter()
					this.GameOver()
				endif
			endif
			this.map[g.y][g.x] = g.id
		endfor

		for i in range(len(this.map))
			var line_chars: list<string> = []
			for j in range(len(this.map[i]))
				const value = this.map[i][j]
				if value == WALL
					add(line_chars, this.map_opti[i][j])
				elseif value == EMPTY
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
			this.map[g.y][g.x] = EMPTY
		endfor
		# clear player from map
		this.map[this.player.y][this.player.x] = EMPTY
	enddef

	##############################
	## Update Game Logic
	##############################
	def UpdateGame()

		# Update Player Position
		const old_x = this.player.x
		const old_y = this.player.y
		var new_x = this.player.x
		var new_y = this.player.y

		if this.player.dir_save == DOWN
			var p_y = this.player.y + 1
			if p_y >= len(this.map)
				p_y = 0
			endif
			if this.map[p_y][this.player.x] != WALL
				this.player.dir = DOWN
			endif
		elseif this.player.dir_save == UP
			var p_y = this.player.y - 1
			if p_y < 0
				p_y = len(this.map) - 1
			endif
			if this.map[p_y][this.player.x] != WALL
				this.player.dir = UP
			endif
		elseif this.player.dir_save == LEFT
			var p_x = this.player.x - 1
			if p_x < 0
				p_x = len(this.map[0]) - 1
			endif
			if this.map[this.player.y][p_x] != WALL
				this.player.dir = LEFT
			endif
		elseif this.player.dir_save == RIGHT
			var p_x = this.player.x + 1
			if p_x >= len(this.map[0])
				p_x = 0
			endif
			if this.map[this.player.y][p_x] != WALL
				this.player.dir = RIGHT
			endif
		else
			this.player.dir = this.player.dir_save
		endif

		# Update this.player based on dir
		if this.player.dir == UP
			new_y = this.player.y - 1
		elseif this.player.dir == DOWN
			new_y = this.player.y + 1
		elseif this.player.dir == LEFT
			new_x = this.player.x - 1
		elseif this.player.dir == RIGHT
			new_x = this.player.x + 1
		endif

		# if the player hit the bound of the this.map, teleport him to the other side
		if new_x < 0
			new_x = len(this.map[0]) - 1
		elseif new_x >= len(this.map[0])
			new_x = 0
		endif
		if new_y < 0
			new_y = len(this.map) - 1
		elseif new_y >= len(this.map)
			new_y = 0
		endif

		# Check for wall collision
		if this.map[new_y][new_x] == WALL
			this.player.SetPosition(old_x, old_y)
			return
		endif

		this.player.SetPosition(new_x, new_y)

		var e_under_pacman = this.lst_entity[new_y][new_x]

		if e_under_pacman == SIMPLE
			this.IncreaseScore(10)
			this.lst_entity[new_y][new_x] = EMPTY
			this.remain_food -= 1
			if this.remain_food == 0
				# Win the game
				this.highscore = max([this.highscore, this.score])
				g:SUPRA_PACMAN_HIGHSCORE = this.highscore
				this.ChangeActivity(NEXTLEVEL)
			endif
		elseif e_under_pacman == PACGOMME
			this.IncreaseScore(50)
			this.lst_entity[new_y][new_x] = EMPTY
			# Set all ghosts to FRIGHTENED
			for g in this.ghosts
				if g.IsEaten()
					continue
				endif
				g.SetFrightened()
			endfor
		# FOOD1 to FOOD8
		elseif e_under_pacman >= FOOD1 && e_under_pacman <= FOOD8
			this.IncreaseScore(100 * (e_under_pacman - FOOD1 + 1))
			this.lst_entity[new_y][new_x] = EMPTY
		endif
	enddef


	###############################
	## Draw Scoreboard
	###############################
	def DrawScore(map_print: list<string>, is_over: bool = 0)
		const width_2 = width / 2 - 14

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
		const space_center = repeat(' ', (width / 2) - (strcharlen(ascii_txt[0]) / 2))
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
		const space_center_btn = repeat(' ', (width / 2) - (strcharlen(button_play[0]) / 2))

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

		const space_center = repeat(' ', (width / 2) - (strcharlen(ascii_txt[0]) / 2))
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
		const space_center_btn = repeat(' ', (width / 2) - (strcharlen(button_retry[0]) / 2))
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
		for i in range(txt_len, height - 2)
			add(gameover, '')
		endfor
		add(gameover, score_str)
		add(gameover, highscore_str)

		popup_settext(this.popup, gameover)
	enddef

	###############################
	## Game Over Screen
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
		const space_center = repeat(' ', (width / 2) - (strcharlen(ascii_txt[1]) / 2))
		var button = []
		for i in range(len(ascii_txt))
			add(button, space_center .. ascii_txt[i])
		endfor
		const space_center_btn = repeat(' ', (width / 2) - (strcharlen(button_next[0]) / 2))
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
		for i in range(txt_len, height - 2)
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
		const space_center = repeat(' ', (width / 2) - (strcharlen(ascii_txt[4]) / 2))
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


# Use to hide the cursor while popups active
def HideCursor()
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
def ShowCursor()
    # terminal cursor
    if &t_ve != t_ve
        &t_ve = t_ve
    endif
    # gui cursor
    if len(hlget('Cursor')) > 0 && get(hlget('Cursor')[0], 'cleared', false)
        hlset([hlcursor])
    endif
enddef
