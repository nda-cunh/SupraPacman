vim9script

import autoload './Direction.vim' as Dir
import autoload './TileType.vim' as Tile
import autoload './Pacman.vim' as Pac

type Direction = Dir.Direction
type Pacman = Pac.Pacman

##############################
## Ghost class
##############################

export abstract class Ghost
	# Ghost properties
	var y: number
	var x: number
	var id: number
	var dir: Direction
	var state: number
	var real_id: number
	var timer_isblue = 0
	var len_map_x: number
	var len_map: number
	public var last_y: number
	public var last_x: number
	public var is_block = 0

	# Constant for states
	public static const CHASE: number = 0  # 🟥
	public static const SCATTER: number = 1 # 🟥 (but not attack)
	public static const FRIGHTENED: number = 2  # 🟦
	public static const EATEN: number = 3  # 👀

	##############################
	## Constructor
	##############################
	def Ghost(dir: Direction, id: number)
		this.dir = dir
		this.state = Ghost.CHASE
		this.id = id
		this.real_id = id
	enddef

	def AddMapSize(len_map_x: number, len_map_y: number)
		this.len_map_x = len_map_x
		this.len_map = len_map_y
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

		var width_max = this.len_map_x
		var height_max = this.len_map

		# --- Dir.UP 
		if this.y > 0 && map[this.y - 1][this.x] != Tile.WALL && this.dir != Dir.DOWN
			add(possible_dirs, Dir.UP)
		endif

		# --- Dir.DOWN 
		if this.y < height_max - 1 && map[this.y + 1][this.x] != Tile.WALL && this.dir != Dir.UP
			add(possible_dirs, Dir.DOWN)
		endif

		# --- Dir.LEFT 
		var left_x = this.x - 1
		if left_x < 0
			left_x = width_max - 1
		endif
		if map[this.y][left_x] != Tile.WALL && this.dir != Dir.RIGHT
			add(possible_dirs, Dir.LEFT)
		endif

		# --- Dir.RIGHT 
		var right_x = this.x + 1
		if right_x >= width_max
			right_x = 0
		endif
		if map[this.y][right_x] != Tile.WALL && this.dir != Dir.LEFT
			add(possible_dirs, Dir.RIGHT)
		endif

		if len(possible_dirs) == 1
			this.Move(possible_dirs[0], map)
			this.dir = possible_dirs[0]
			return 
		endif

		var best_dir: Direction = Dir.NONE
		var best_dist = 999999.0

		for dir in possible_dirs
			var new_x = this.x
			var new_y = this.y

			if dir == Dir.UP
				new_y = this.y - 1
			elseif dir == Dir.DOWN
				new_y = this.y + 1
			elseif dir == Dir.LEFT
				new_x = this.x - 1
			elseif dir == Dir.RIGHT
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

		if best_dir != Dir.NONE
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
		if this.IsEaten()
			return
		endif
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
		this.id = Tile.GHOST_EAT
	enddef

	def SetEaten()
		this.state = Ghost.EATEN
		this.id = Tile.GHOST_DEAD
	enddef

	###########################
	## Move Ghost
	###########################
	def Move(dir: Direction, map: list<list<number>>)
		var new_x = this.x
		var new_y = this.y
		if dir == Dir.UP
			new_y = this.y - 1
		elseif dir == Dir.DOWN
			new_y = this.y + 1
		elseif dir == Dir.LEFT
			new_x = this.x - 1
		elseif dir == Dir.RIGHT
			new_x = this.x + 1
		endif

		# if the ghost hit the bound of the this.map, teleport him to the other side
		if new_x < 0
			new_x = this.len_map_x - 1
		elseif new_x >= this.len_map_x
			new_x = 0
		endif
		if new_y <= 0
			new_y = this.len_map - 1
		elseif new_y >= this.len_map
			new_y = 0
		endif

		if map[new_y][new_x] != Tile.WALL
			map[this.y][this.x] = Tile.EMPTY
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

	def GhostMoveToGoal(map: list<list<number>>, cage_x: number, cage_y: number)
		if this.IsBlocked()
			this.dir = Dir.NONE
		endif
		this.PathFinding(map, cage_x, cage_y)
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
			target_x = this.len_map_x - 1
		endif
		if ghost.y < pacman.y
			target_y = 0
		else
			target_y = this.len_map - 1
		endif
		if ghost.IsBlocked()
			ghost.dir = Dir.NONE
		endif
		this.PathFinding(map, target_x, target_y)
	enddef

	###########################
	## Abstract Method for Ghost Movement
	###########################
	abstract def GhostMove(map: list<list<number>>, pacman: Pacman)
endclass
