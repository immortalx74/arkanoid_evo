-- TODO:
-- silver bricks shouldn't spawn powerups
-- When exit gate is open you CAN collect any other powerup
-- max lives = 6
-- collecting "life" powerup turns paddle to normal
-- silver bricks start with strength = 2, increasing by 1 every 8 stages
-- set playfield origin slightly forward (also let powerups travel a bit further on negative Z axis)
-- "owned" powerup shouldn't change when catching life powerup

package.loaded[ ... ] = "globals"


local timer = require "timer"
local util = require "util"
local assets = require "assets"
phywire = require "phywire"

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
	POWERUP_B = 28,
	POWERUP_C = 29,
	POWERUP_D = 30,
	POWERUP_E = 31,
	POWERUP_L = 32,
	POWERUP_P = 33,
	POWERUP_S = 34,
	PADDLE_BIG = 35,
	PADDLE_TOP_BIG = 36,
	PADDLE_SPINNER_BIG = 37,
	PADDLE_LASER = 38,
	PROJECTILE = 39
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
	ROOM_WIDTH = 2.2,
	ROOM_HEIGHT = 2.2,
	ROOM_DEPTH = 4,

	BRICK_WIDTH = 0.162,
	BRICK_HEIGHT = 0.084,
	-- BRICK_DEPTH = 0.084,
	BRICK_DEPTH = 0.5,
	BRICK_DIST_Z = 3.4,

	POWERUP_RADIUS = 0.042,
	POWERUP_LENGTH = 0.162,
	POWERUP_SPEED = 0.8,

	GAP_LEFT = 0.047, -- (ROOM_WIDTH - (13 * BRICK_WIDTH) ) / 2
	GAP_TOP = 0.344, -- (ROOM_HEIGHT - (18 * BRICK_HEIGHT) ) / 2

	NUM_BRICK_COLS = 13,
	NUM_BRICK_ROWS = 18,

	WALL_THICKNESS = 0.5,

	BALL_RADIUS = 0.03,
	PADDLE_RADIUS = 0.14,
	PADDLE_BIG_RADIUS = 0.2,
	PADDLE_COLLIDER_THICKNESS = 0.04,
	SUBSTEPS = 10,
	POWERUP_SPAWN_INTERVAL = 3,

	PROJECTILE_LENGTH = 0.05,
	PROJECTILE_RADIUS = 0.01,
	PROJECTILE_X_OFFSET = 0.09,
	PROJECTILE_SPEED = 0.8,

	PADDLE_COOLDOWN_INTERVAL = 1,
	LASER_COOLDOWN_INTERVAL = 0.5
}

gameobjects_list = {}
game_state = GAME_STATE.INIT
levels = {}
balls = {}
room_colliders = {}
player = { contacted = false, hand = "left", paddle_cooldown_timer = timer( false ), laser_cooldown_timer = timer( false ), lives = 3 }
cur_level = 17

world = lovr.physics.newWorld( {
	tags = { "ball", "brick", "paddle", "wall_right", "wall_left", "wall_top", "wall_bottom", "wall_far", "wall_near", "powerup", "projectile" },
	staticTags = { "ball", "brick", "paddle", "wall_right", "wall_left", "wall_top", "wall_bottom", "wall_far", "wall_near", "powerup", "projectile" },
	maxColliders = 512,
	threadSafe = false,
	tickRate = 60,
	maxPenetration = 0.02
} )
world:disableCollisionBetween( "brick", "brick" )
world:disableCollisionBetween( "ball", "ball" )
world:disableCollisionBetween( "brick", "paddle" )
world:disableCollisionBetween( "brick", "powerup" )
world:disableCollisionBetween( "ball", "powerup" )
world:disableCollisionBetween( "projectile", "powerup" )
world:disableCollisionBetween( "projectile", "ball" )
world:disableCollisionBetween( "projectile", "paddle" )
paused = false
phywire.options.wireframe = true
phywire.options.overdraw = true
math.randomseed( os.time() )
