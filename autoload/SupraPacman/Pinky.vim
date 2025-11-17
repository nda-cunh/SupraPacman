vim9script

import autoload './Direction.vim' as Dir
import autoload './TileType.vim' as Tile
import autoload './Pacman.vim' as Pac
import autoload './Ghost.vim' as AGhost

type Direction = Dir.Direction
type Pacman = Pac.Pacman
type Ghost = AGhost.Ghost

export class PinkyGhost extends Ghost
	# Additional properties or methods specific to Blinky can be added here
	def new(dir: Direction, id: number)
		super.Ghost(dir, id)
	enddef

	def GhostMove(map: list<list<number>>, pacman: Pacman)
		var pinky = this
		var target_y: number
		var target_x: number

		if this.state == Ghost.SCATTER
			# Target top-left corner
			target_x = 1
			target_y = 1
			super.PathFinding(map, target_x, target_y)
		else
			if pacman.dir == Dir.UP
				target_y = pacman.y - 4
				target_x = pacman.x
			elseif pacman.dir == Dir.DOWN
				target_y = pacman.y + 4
				target_x = pacman.x
			elseif pacman.dir == Dir.LEFT
				target_y = pacman.y
				target_x = pacman.x - 4
			elseif pacman.dir == Dir.RIGHT
				target_y = pacman.y
				target_x = pacman.x + 4
			else
				target_y = pacman.y
				target_x = pacman.x
			endif
			super.PathFinding(map, target_x, target_y)
		endif


	enddef
endclass

