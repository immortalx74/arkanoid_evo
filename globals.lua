local timer = require "timer"

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
	BALL = 14,
	SND_BALL_BRICK_DESTROY = 15,
	SND_BALL_BRICK_DING = 16,
	SND_BALL_TO_PADDLE = 17,
	SND_BALL_TO_PADDLE_STICK = 18,
	SND_ENEMY_DESTROY = 19,
	SND_ESCAPE_LEVEL = 20,
	SND_GOT_LIFE = 21,
	SND_LASER_SHOOT = 22,
	SND_LEVEL_INTRO = 23,
	SND_LOST_LIFE = 24,
	SND_MOTHERSHIP_INTRO = 25,
	SND_PADDLE_AWAY = 26,
	SND_PADDLE_TURN_BIG = 27,
}

GAME_STATE = {
	INIT = 1,
	GENERATE_LEVEL = 2,
	PLAY = 3
}

BRICK_COLORS = {
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
room_walls = {}
player = { cooldown_interval = 1, contacted = false, hand = "right", cooldown_timer = timer( false ) }
cur_level = 17
world = lovr.physics.newWorld( {
	tags = { "ball", "brick", "paddle", "wall_right", "wall_left", "wall_top", "wall_bottom", "wall_back", "wall_front" },
	staticTags = { "ball", "brick", "paddle", "wall_right", "wall_left", "wall_top", "wall_bottom", "wall_back", "wall_front" },
	maxColliders = 512,
	threadSafe = false,
	tickRate = 480,
	maxPenetration = 0.02
} )
world:disableCollisionBetween( "brick", "brick" )
world:disableCollisionBetween( "ball", "ball" )
world:disableCollisionBetween( "brick", "paddle" )
paused = false
print( lovr.headset.getRefreshRates() )
