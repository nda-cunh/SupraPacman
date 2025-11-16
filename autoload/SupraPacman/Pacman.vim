vim9script

import autoload './Direction.vim' as Dir
type Direction = Dir.Direction

####################################
## Pacman class
## It's the player class
#####################################
export class Pacman
	var init_x: number
	var init_y: number
	public var y: number
	public var x: number
	public var dir: Direction
	public var dir_save: Direction

	def new()
		this.dir = Dir.NONE
		this.dir_save = Dir.NONE
	enddef

	def Reset()
		this.dir = Dir.NONE
		this.dir_save = Dir.NONE
		this.SetPosition(this.init_x, this.init_y)
	enddef

	def InitPosition(x: number, y: number)
		this.init_x = x
		this.init_y = y
		this.SetPosition(x, y)
	enddef

	def SetPosition(x: number, y: number)
		this.y = y
		this.x = x
	enddef
endclass
