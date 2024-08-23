require "globals"
local util = require "util"

local assets = {}

function assets.load()
	assets[ ASSET_TYPE.ARKANOID_LOGO ] = lovr.graphics.newModel( "res/models/arkanoid_logo.glb" )
	assets[ ASSET_TYPE.MOTHERSHIP ] = lovr.graphics.newModel( "res/models/mothership.glb" )
	assets[ ASSET_TYPE.TAITO_LOGO ] = lovr.graphics.newModel( "res/models/taito_logo.glb" )
	assets[ ASSET_TYPE.ENEMY_SHIP ] = lovr.graphics.newModel( "res/models/enemy_ship.glb" )
	assets[ ASSET_TYPE.ENEMY_LASER_BEAM ] = lovr.graphics.newModel( "res/models/enemy_laser_beam.glb" )
	assets[ ASSET_TYPE.PADDLE_ESCAPE ] = lovr.graphics.newModel( "res/models/paddle_escape.glb" )
	assets[ ASSET_TYPE.ENEMY_BALOONS ] = lovr.graphics.newModel( "res/models/enemy_baloons.glb" )
	assets[ ASSET_TYPE.ENEMY_CONE ] = lovr.graphics.newModel( "res/models/enemy_cone.glb" )
	assets[ ASSET_TYPE.ENEMY_PYRAMID ] = lovr.graphics.newModel( "res/models/enemy_pyramid.glb" )
	assets[ ASSET_TYPE.FEET_MARK ] = lovr.graphics.newModel( "res/models/feet_mark.glb" )
	assets[ ASSET_TYPE.EXIT_GATE ] = lovr.graphics.newModel( "res/models/exit_gate.glb" )
	assets[ ASSET_TYPE.EXIT_GATE_COLUMN ] = lovr.graphics.newModel( "res/models/exit_gate_column.glb" )
	assets[ ASSET_TYPE.DOH ] = lovr.graphics.newModel( "res/models/doh.glb" )
	assets[ ASSET_TYPE.DOH_COLLISION ] = lovr.graphics.newModel( "res/models/doh_collision.glb" )
	assets[ ASSET_TYPE.FONT ] = lovr.graphics.newFont( "res/fonts/PressStart2P-Regular.ttf" )

	assets[ ASSET_TYPE.PADDLE ] = lovr.graphics.newModel( "res/models/paddle.glb" )
	assets[ ASSET_TYPE.PADDLE_TOP ] = lovr.graphics.newModel( "res/models/paddle_top.glb" )
	assets[ ASSET_TYPE.PADDLE_SPINNER ] = lovr.graphics.newModel( "res/models/spinner.glb" )
	assets[ ASSET_TYPE.PADDLE_BIG ] = lovr.graphics.newModel( "res/models/paddle_big.glb" )
	assets[ ASSET_TYPE.PADDLE_TOP_BIG ] = lovr.graphics.newModel( "res/models/paddle_top_big.glb" )
	assets[ ASSET_TYPE.PADDLE_SPINNER_BIG ] = lovr.graphics.newModel( "res/models/spinner_big.glb" )
	assets[ ASSET_TYPE.PADDLE_LASER ] = lovr.graphics.newModel( "res/models/paddle_laser.glb" )
	assets[ ASSET_TYPE.PROJECTILE ] = lovr.graphics.newModel( "res/models/projectile.glb" )
	assets[ ASSET_TYPE.ROOM ] = lovr.graphics.newModel( "res/models/room.glb" )
	assets[ ASSET_TYPE.ROOM_GLASS ] = lovr.graphics.newModel( "res/models/glass.glb" )
	assets[ ASSET_TYPE.SHADER_PBR ] = lovr.graphics.newShader( "res/shaders/shader_PBR.vs", "res/shaders/shader_PBR.fs",
		{ flags = { glow = true, normalMap = true, vertexTangents = false, tonemap = true } } )
	assets[ ASSET_TYPE.SHADER_UNLIT ] = lovr.graphics.newShader( "unlit", "unlit", { flags = { pointSize = 1 } } )
	assets[ ASSET_TYPE.SKYBOX ] = lovr.graphics.newTexture( "res/images/galaxy.png" )
	assets[ ASSET_TYPE.LIFE_ICON ] = lovr.graphics.newTexture( "res/images/life.png" )
	assets[ ASSET_TYPE.ENVIRONMENT_MAP ] = lovr.graphics.newTexture( 'res/images/ibl.ktx' )
	assets[ ASSET_TYPE.BRICK ] = lovr.graphics.newModel( "res/models/brick.glb" )
	assets[ ASSET_TYPE.BRICK_SILVER ] = lovr.graphics.newModel( "res/models/brick_silver.glb" )
	assets[ ASSET_TYPE.BRICK_GOLD ] = lovr.graphics.newModel( "res/models/brick_gold.glb" )
	assets[ ASSET_TYPE.BALL ] = lovr.graphics.newModel( "res/models/ball.glb" )

	assets[ ASSET_TYPE.SND_BALL_BRICK_DESTROY ] = lovr.audio.newSource( "res/sounds/ball_brick_destroy.wav" )
	assets[ ASSET_TYPE.SND_BALL_BRICK_DING ] = lovr.audio.newSource( "res/sounds/ball_brick_ding.wav" )
	assets[ ASSET_TYPE.SND_BALL_TO_PADDLE ] = lovr.audio.newSource( "res/sounds/ball_to_paddle.wav" )
	assets[ ASSET_TYPE.SND_BALL_TO_PADDLE_STICK ] = lovr.audio.newSource( "res/sounds/ball_to_paddle_stick.wav" )
	assets[ ASSET_TYPE.SND_ENEMY_DESTROY ] = lovr.audio.newSource( "res/sounds/enemy_destroy.wav" )
	assets[ ASSET_TYPE.SND_ESCAPE_LEVEL ] = lovr.audio.newSource( "res/sounds/escape_level.wav" )
	assets[ ASSET_TYPE.SND_GOT_LIFE ] = lovr.audio.newSource( "res/sounds/got_life.wav" )
	assets[ ASSET_TYPE.SND_LASER_SHOOT ] = lovr.audio.newSource( "res/sounds/laser_shoot.wav" )
	assets[ ASSET_TYPE.SND_LEVEL_INTRO ] = lovr.audio.newSource( "res/sounds/level_intro.wav" )
	assets[ ASSET_TYPE.SND_LOST_LIFE ] = lovr.audio.newSource( "res/sounds/lost_life.wav" )
	assets[ ASSET_TYPE.SND_MOTHERSHIP_INTRO ] = lovr.audio.newSource( "res/sounds/mothership_intro.wav" )
	assets[ ASSET_TYPE.SND_PADDLE_AWAY ] = lovr.audio.newSource( "res/sounds/paddle_away.wav" )
	assets[ ASSET_TYPE.SND_PADDLE_TURN_BIG ] = lovr.audio.newSource( "res/sounds/paddle_turn_big.wav" )
	assets[ ASSET_TYPE.SND_GAME_OVER ] = lovr.audio.newSource( "res/sounds/game_over.wav" )
	assets[ ASSET_TYPE.SND_DOH_HIT ] = lovr.audio.newSource( "res/sounds/doh_hit.wav" )
	assets[ ASSET_TYPE.SND_ENDING_THEME ] = lovr.audio.newSource( "res/sounds/ending_theme.wav" )

	-- NOTE: Maybe set all to no looping?
	assets[ ASSET_TYPE.SND_LOST_LIFE ]:setLooping( false )

	assets[ ASSET_TYPE.POWERUP_B ] = lovr.graphics.newModel( "res/models/powerup_b.glb" )
	assets[ ASSET_TYPE.POWERUP_C ] = lovr.graphics.newModel( "res/models/powerup_c.glb" )
	assets[ ASSET_TYPE.POWERUP_D ] = lovr.graphics.newModel( "res/models/powerup_d.glb" )
	assets[ ASSET_TYPE.POWERUP_E ] = lovr.graphics.newModel( "res/models/powerup_e.glb" )
	assets[ ASSET_TYPE.POWERUP_L ] = lovr.graphics.newModel( "res/models/powerup_l.glb" )
	assets[ ASSET_TYPE.POWERUP_P ] = lovr.graphics.newModel( "res/models/powerup_p.glb" )
	assets[ ASSET_TYPE.POWERUP_S ] = lovr.graphics.newModel( "res/models/powerup_s.glb" )

	assets[ ASSET_TYPE.SPHERICAL_HARMONICS ] = lovr.graphics.newBuffer( { 'vec3', layout = 'std140' }, {
		{ 0.611764907836914,  0.599504590034485,  0.479980736970901 },
		{ 0.659514904022217,  0.665349841117859,  0.567680120468140 },
		{ 0.451633930206299,  0.450751245021820,  0.355226665735245 },
		{ -0.044383134692907, -0.053154513239861, -0.019974749535322 },
		{ -0.053045745939016, -0.057957146316767, -0.011247659102082 },
		{ 0.485697060823441,  0.490428507328033,  0.397530466318130 },
		{ -0.023690477013588, -0.024272611364722, -0.021886156871915 },
		{ -0.179465517401695, -0.181243389844894, -0.141314014792442 },
		{ -0.144527092576027, -0.143508568406105, -0.122757166624069 }
	} )
end

function assets.load_levels()
	local files = lovr.filesystem.getDirectoryItems( "res/levels" )

	for i, v in ipairs( files ) do
		local str = lovr.filesystem.read( "res/levels/" .. i .. ".csv" )
		table.insert( levels, util.split( str ) )
	end
end

return assets
