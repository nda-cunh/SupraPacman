vim9script

import autoload './Direction.vim' as Dir
import autoload './TileType.vim' as Tile
import autoload './Pacman.vim' as Pac
import autoload './Ghost.vim' as AGhost

type Direction = Dir.Direction
type Pacman = Pac.Pacman
type Ghost = AGhost.Ghost

export class ClydeGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, id: number)
		super.Ghost(dir, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		const ghost = this
		var target_x: number
		var target_y: number

		if ghost.IsBlocked()
			ghost.dir = Dir.NONE
		endif

		if this.state == Ghost.SCATTER
			# Target bottom-left corner
			target_x = 1
			target_y = ghost.len_map - 2
			super.PathFinding(map, target_x, target_y)
		else
			const distance_squared = pow((ghost.y - pacman.y), 2) + pow((ghost.x - pacman.x), 2)
			const distance = sqrt(distance_squared)

			if distance < 9.0
				target_x = 1
				target_y = ghost.len_map - 2
			else
				target_y = pacman.y
				target_x = pacman.x
			endif
			super.PathFinding(map, target_x, target_y)
		endif
	enddef
endclass


