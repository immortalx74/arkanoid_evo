-- TODO:
-- When exit gate is open you CAN collect any other powerup (and transform paddle too)
-- max lives = 6
-- collecting "life" powerup turns paddle to normal (also deactivates "catch" powerup)
-- silver bricks start with strength = 2, increasing by 1 every 8 stages
-- set playfield origin slightly forward (also let powerups travel a bit further on negative Z axis)
-- "owned" powerup shouldn't change when catching life powerup
-- prevent ball "extreme" reflection angles from paddle (favor Z direction)
-- The "disruption" powerup prevents other powerups to spawn, but when there's only one ball left it should return to normal

package.loaded[ ... ] = "globals"


local timer = require "timer"
local util = require "util"
local assets = require "assets"
local typewriter = require "typewriter"
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
	PROJECTILE = 39,
	ARKANOID_LOGO = 40,
	MOTHERSHIP = 41,
	TAITO_LOGO = 42,
	FONT = 43,
	ENEMY_SHIP = 44,
	ENEMY_LASER_BEAM = 45,
	PADDLE_ESCAPE = 46
}

GAME_STATE = {
	INIT = 1,
	START_SCREEN = 2,
	MOTHERSHIP_INTRO = 3,
	GENERATE_LEVEL = 4,
	LEVEL_INTRO = 5,
	PLAY = 6
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
	PROJECTILE_SPAWN_X_OFFSET = 0.09,
	PROJECTILE_SPEED = 5,

	PADDLE_COOLDOWN_INTERVAL = 1,
	LASER_COOLDOWN_INTERVAL = 0.12,

	TRANSPARENCY_IDX_ROOM_GLASS = 1,
	TRANSPARENCY_IDX_PADDLE_TOP = 2,
}

obj_arkanoid_logo = nil
obj_taito_logo = nil
obj_mothership = nil


gameobjects_list = {}
game_state = GAME_STATE.INIT
levels = {}
room_colliders = {}
player = { contacted = false, hand = "right", paddle_cooldown_timer = timer( false ), laser_cooldown_timer = timer( false ), lives = 3 }
level_intro_timer = timer( false )
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

phywire.options.wireframe = true
phywire.options.overdraw = true
math.randomseed( os.time() )

phrases = { current = 1, last_timer = timer( false ) }
table.insert( phrases, typewriter( "THE ERA AND TIME OF", vec3( -0.5, 1.5, -2 ), 0.02, true ) )
table.insert( phrases, typewriter( "THIS STORY IS UNKNOWN.", vec3( -0.5, 1.4, -2 ), 0.02, false ) )

table.insert( phrases, typewriter( "AFTER THE MOTHERSHIP", vec3( -0.5, 1.5, -2 ), 0.02, false ) )
table.insert( phrases, typewriter( '"ARKANOID" WAS DESTROYED,', vec3( -0.5, 1.4, -2 ), 0.02, false ) )
table.insert( phrases, typewriter( 'A SPACECRAFT "VAUS"', vec3( -0.5, 1.3, -2 ), 0.02, false ) )
table.insert( phrases, typewriter( "SCRAMBLED AWAY FROM IT.", vec3( -0.5, 1.2, -2 ), 0.02, false ) )

table.insert( phrases, typewriter( "BUT ONLY TO BE", vec3( -0.5, 1.5, -2 ), 0.02, false ) )
table.insert( phrases, typewriter( "TRAPPED IN SPACE WARPED", vec3( -0.5, 1.4, -2 ), 0.02, false ) )
table.insert( phrases, typewriter( "BY SOMEONE........", vec3( -0.5, 1.3, -2 ), 0.02, false ) )
