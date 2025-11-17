vim9script

import autoload './Direction.vim' as Dir
import autoload './TileType.vim' as Tile
import autoload './Pacman.vim' as Pac
import autoload './Ghost.vim' as AGhost

type Direction = Dir.Direction
type Pacman = Pac.Pacman
type Ghost = AGhost.Ghost

export class InkyGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, id: number)
		super.Ghost(dir, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		const ghost = this
		var target_x: number
		var target_y: number

		if this.state == Ghost.SCATTER
			# Target bottom-right corner
			target_x = ghost.len_map_x - 2
			target_y = ghost.len_map - 2
			super.PathFinding(map, target_x, target_y)
		else
			if sqrt(pow((ghost.y - pacman.y), 2) + pow((ghost.x - pacman.x), 2)) < 9.0
				target_y = pacman.y
				target_x = pacman.x
			else
				target_y = 0
				target_x = 0
			endif
			super.PathFinding(map, target_x, target_y)
		endif
	enddef
endclass


