vim9script

import autoload './Direction.vim' as Dir
import autoload './TileType.vim' as Tile
import autoload './Pacman.vim' as Pac
import autoload './Ghost.vim' as AGhost

type Direction = Dir.Direction
type Pacman = Pac.Pacman
type Ghost = AGhost.Ghost

export class BlinkyGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, id: number)
		super.Ghost(dir, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		var blinky = this
		var target_x = pacman.x
		var target_y = pacman.y

		if blinky.IsBlocked()
			blinky.dir = Dir.NONE
		endif

		if this.state == Ghost.SCATTER
			# Target top-right corner
			target_x = blinky.len_map_x - 2
			target_y = 1
			super.PathFinding(map, target_x, target_y)
		else
			super.PathFinding(map, target_x, target_y)
		endif
	enddef
endclass

