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
	def new(dir: Direction, walk_on: number, state: number, id: number)
		super.Ghost(dir, walk_on, state, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		var blinky = this
		var target_x = pacman.x
		var target_y = pacman.y

		if blinky.IsBlocked()
			blinky.dir = Dir.NONE
		endif

		super.PathFinding(map, target_x, target_y)
	enddef
endclass

