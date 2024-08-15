require "globals"
local gameobject = require "gameobject"
local assets = require "assets"
local util = require "util"
local powerup = require "powerup"
local typewriter = require "typewriter"

function lovr.load()
	assets.load()
	assets.load_levels()
end

function lovr.update( dt )
	if game_state == GAME_STATE.INIT then
		util.create_start_screen()
	elseif game_state == GAME_STATE.START_SCREEN then
		if lovr.headset.wasPressed( "left", "trigger" ) then
			util.create_mothership_intro( "left" )
			game_state = GAME_STATE.MOTHERSHIP_INTRO
		elseif lovr.headset.wasPressed( "right", "trigger" ) then
			util.create_mothership_intro( "right" )
			game_state = GAME_STATE.MOTHERSHIP_INTRO
		end
	elseif game_state == GAME_STATE.MOTHERSHIP_INTRO then
		if lovr.headset.wasPressed( player.hand, "trigger" ) then
			game_state = GAME_STATE.GENERATE_LEVEL
		end

		if phrases[ phrases.current ]:has_finished() then
			if phrases.current < #phrases then
				phrases.current = phrases.current + 1
				phrases[ phrases.current ]:start()
			else
				if not phrases.last_timer.started then
					phrases.last_timer:start()
				end
			end
		end

		if phrases.current == 9 and phrases.last_timer:get_elapsed() > 7 then
			game_state = GAME_STATE.GENERATE_LEVEL
		elseif phrases.current == 9 and phrases.last_timer:get_elapsed() > 4 and not assets[ ASSET_TYPE.SND_PADDLE_AWAY ]:isPlaying() then
			assets[ ASSET_TYPE.SND_PADDLE_AWAY ]:play()
			enemy_ship_timer:stop()
		end
	elseif game_state == GAME_STATE.GENERATE_LEVEL then
		util.generate_level()
		game_state = GAME_STATE.LEVEL_INTRO
		level_intro_timer:start()
		assets[ ASSET_TYPE.SND_LEVEL_INTRO ]:stop()
		assets[ ASSET_TYPE.SND_LEVEL_INTRO ]:play()
	elseif game_state == GAME_STATE.LEVEL_INTRO then
		if level_intro_timer:get_elapsed() > 3 then
			local ball = gameobject( vec3( -0.8, 1.6, -1 ), ASSET_TYPE.BALL )
			game_state = GAME_STATE.PLAY
		end
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
	elseif game_state == GAME_STATE.MOTHERSHIP_INTRO then
		pass:setShader()
		obj_enemy_ship.model:animate( 1, enemy_ship_timer:get_elapsed() )
		obj_enemy_laser_beam.model:animate( 1, enemy_ship_timer:get_elapsed() )
		obj_paddle_escape.model:animate( 1, enemy_ship_timer:get_elapsed() )

		if phrases.current < 3 then
			phrases[ 1 ]:draw( pass )
			phrases[ 2 ]:draw( pass )
		elseif phrases.current < 7 then
			phrases[ 3 ]:draw( pass )
			phrases[ 4 ]:draw( pass )
			phrases[ 5 ]:draw( pass )
			phrases[ 6 ]:draw( pass )
		else
			phrases[ 7 ]:draw( pass )
			phrases[ 8 ]:draw( pass )
			phrases[ 9 ]:draw( pass )
		end
	elseif game_state == GAME_STATE.PLAY then
		-- phywire.draw( pass, world )
	elseif game_state == GAME_STATE.LEVEL_INTRO then
		pass:setShader()
		pass:text( "ROUND 1", vec3( 0, 1.2, -2 ), 0.06 )
		if level_intro_timer:get_elapsed() > 1 then
			pass:text( "START", vec3( 0, 1.1, -2 ), 0.06 )
		end
	end

	gameobject.draw_all( pass )
end
