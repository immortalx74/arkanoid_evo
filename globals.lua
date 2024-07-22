ASSET_TYPE = {
	PADDLE = 1,
	PADDLE_TOP = 2,
	PADDLE_SPINNER = 3,
	BALL = 4,
	ROOM = 5,
	ROOM_GLASS = 6,
	SHADER_PBR = 7,
	SKYBOX = 8,
	SPHERICAL_HARMONICS = 9,
	ENVIRONMENT_MAP = 10,
	BRICK = 11,
	BRICK_SILVER = 12,
	BRICK_GOLD = 13,
	BALL = 14
}

GAME_STATE = {
	INIT = 1,
	GENERATE_LEVEL = 2,
	PLAY = 3
}

PASS_COLORS = {
	[ "w" ] = { 1, 1, 1 },
	[ "o" ] = { 1, 0.56, 0 },
	[ "c" ] = { 0, 1, 1 },
	[ "g" ] = { 0, 1, 0 },
	[ "r" ] = { 1, 0, 0 },
	[ "b" ] = { 0, 0.44, 1 },
	[ "p" ] = { 1, 0, 1 },
	[ "y" ] = { 1, 1, 0 },

}

METRICS = {
	WALL_LEFT_X = -1.1,
	WALL_LEFT_Y = 1.1,
	WALL_RIGHT_X = 1.1,
	WALL_RIGHT_Y = 1.1,
	CEILING_Y = 2.2,
}

gameobjects_list = {}
game_state = GAME_STATE.INIT
levels = {}
bricks = {}
balls = {}
paddle = nil
cur_level = 1
walls = {}
world = lovr.physics.newWorld( {
	tags = { "ball", "brick", "paddle", "wall_right", "wall_left", "wall_top", "wall_bottom", "wall_back", "wall_front" },
	staticTags = { "ball", "brick", "paddle", "wall_right", "wall_left", "wall_top", "wall_bottom", "wall_back", "wall_front" },
	maxColliders = 512,
	threadSafe = false,
	tickRate = 80,
	maxPenetration = 0.01
} )
world:disableCollisionBetween( "brick", "brick" )
world:disableCollisionBetween( "ball", "ball" )
world:disableCollisionBetween( "brick", "paddle" )
