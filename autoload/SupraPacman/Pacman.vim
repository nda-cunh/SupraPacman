vim9script

import autoload './Direction.vim' as Dir
type Direction = Dir.Direction

####################################
## Pacman class
## It's the player class
#####################################
export class Pacman
	public var y: number
	public var x: number
	public var dir: Direction
	public var dir_save: Direction

	def new(y: number, x: number, dir: Direction)
		this.y = y
		this.x = x
		this.dir = Dir.NONE
		this.dir_save = Dir.NONE
	enddef

	def SetPosition(x: number, y: number)
		this.y = y
		this.x = x
	enddef
endclass
