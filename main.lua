require "globals"
local gameobject = require "gameobject"
local assets = require "assets"
local util = require "util"
local powerup = require "powerup"
local timer = require "timer"

function lovr.load()
	assets.load()
	assets.load_levels()
	-- game_state = GAME_STATE.GENERATE_LEVEL
end

function lovr.update( dt )
	if game_state == GAME_STATE.INIT then
		obj_arkanoid_logo = gameobject( vec3( 0, 2, -2 ), ASSET_TYPE.ARKANOID_LOGO )
		obj_taito_logo = gameobject( vec3( 0, 0.65, -2 ), ASSET_TYPE.TAITO_LOGO )
		game_state = GAME_STATE.START_SCREEN
	elseif game_state == GAME_STATE.START_SCREEN then
		if lovr.headset.wasPressed( "left", "trigger" ) then
			player.hand = "left"
			obj_arkanoid_logo:destroy()
			obj_taito_logo:destroy()
			game_state = GAME_STATE.GENERATE_LEVEL
		elseif lovr.headset.wasPressed( "right", "trigger" ) then
			player.hand = "right"
			obj_arkanoid_logo:destroy()
			obj_taito_logo:destroy()
			game_state = GAME_STATE.GENERATE_LEVEL
		end
	elseif game_state == GAME_STATE.GENERATE_LEVEL then
		util.generate_level()
		game_state = GAME_STATE.PLAY
	elseif game_state == GAME_STATE.PLAY then
		if powerup.owned == ASSET_TYPE.POWERUP_L then
			if lovr.headset.wasPressed( player.hand, "trigger" ) then
				if player.laser_cooldown_timer:get_elapsed() >= METRICS.LASER_COOLDOWN_INTERVAL then
					local x, y, z, angle, ax, ay, az = lovr.headset.getPose( player.hand )
					local left = mat4( vec3( x, y, z ), quat( angle, ax, ay, az ) ):translate( -METRICS.PROJECTILE_SPAWN_X_OFFSET, 0, 0 ):rotate( -math.pi / 2, 1, 0, 0 )
					local right = mat4( vec3( x, y, z ), quat( angle, ax, ay, az ) ):translate( METRICS.PROJECTILE_SPAWN_X_OFFSET, 0, 0 ):rotate( -math.pi / 2, 1, 0, 0 )
					gameobject( left, ASSET_TYPE.PROJECTILE )
					gameobject( right, ASSET_TYPE.PROJECTILE )
					player.laser_cooldown_timer:start()
					assets[ ASSET_TYPE.SND_LASER_SHOOT ]:stop()
					assets[ ASSET_TYPE.SND_LASER_SHOOT ]:play()
				end
			end
		elseif powerup.owned == ASSET_TYPE.POWERUP_C then
			if lovr.headset.wasPressed( player.hand, "trigger" ) then
				if player.sticky_ball then
					player.sticky_ball:destroy()
					player.sticky_ball = nil
					local m = mat4( obj_paddle.pose ):rotate( -math.pi / 2, 1, 0, 0 )
					local angle, ax, ay, az = m:getOrientation()
					local q = quat( angle, ax, ay, az )
					local v = vec3( q )
					m:translate( 0, 0, -0.04 )
					local ball = gameobject( vec3( m ), ASSET_TYPE.BALL )
					ball.direction:set( v )
					ball.direction:normalize()
				end
			end
		end
		-- gameobject.update_all( dt )
	end

	gameobject.update_all( dt )
end

function lovr.draw( pass )
	pass:skybox( assets[ ASSET_TYPE.SKYBOX ] )
	pass:setSampler( "nearest" )
	pass:setCullMode( 'back' )
	pass:setShader( assets[ ASSET_TYPE.SHADER_PBR ] )
	pass:send( 'cubemap', assets[ ASSET_TYPE.SKYBOX ] )
	pass:send( 'sphericalHarmonics', assets[ ASSET_TYPE.SPHERICAL_HARMONICS ] )
	pass:setFont( assets[ ASSET_TYPE.FONT ] )

	if game_state == GAME_STATE.START_SCREEN then
		pass:setShader()
		pass:text( "PRESS LEFT OR RIGHT TRIGGER TO START!", vec3( 0, 1.2, -2 ), 0.06 )
		pass:text( "© 1986 TAITO CORP JAPAN", vec3( 0, 0.5, -2 ), 0.06 )
		pass:text( "ALL RIGHTS RESERVED", vec3( 0, 0.4, -2 ), 0.06 )
		pass:text( "This is a free, open source project made for fun.", vec3( 0, 0.3, -2 ), 0.03 )
		pass:text( "No copyright infringement is intended", vec3( 0, 0.25, -2 ), 0.03 )
	elseif game_state == GAME_STATE.PLAY then
		-- gameobject.draw_all( pass )
		-- phywire.draw( pass, world )
	end

	gameobject.draw_all( pass )
end
