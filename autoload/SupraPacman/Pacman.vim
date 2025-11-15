vim9script

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
