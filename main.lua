require "globals"
local gameobject = require "gameobject"
local assets = require "assets"
local util = require "util"
local powerup = require "powerup"
local typewriter = require "typewriter"

function lovr.load()
	lovr.filesystem.mount( "res", "res" )
	assets.load()
	doh_v, doh_i, doh_d = util.get_model_normals( assets[ ASSET_TYPE.DOH_COLLISION ] )
	assets.load_levels()
	util.create_starfield()
end

function lovr.update( dt )
	if game_state == GAME_STATE.INIT then
		util.create_start_screen()
	elseif game_state == GAME_STATE.EXIT_GATE then
		if not assets[ ASSET_TYPE.SND_ESCAPE_LEVEL ]:isPlaying() then
			game_state = GAME_STATE.GENERATE_LEVEL
		end
	elseif game_state == GAME_STATE.START_SCREEN then
		if lovr.headset.wasPressed( "left", "trigger" ) then
			util.create_mothership_intro( "left" )
		elseif lovr.headset.wasPressed( "right", "trigger" ) then
			util.create_mothership_intro( "right" )
		end
	elseif game_state == GAME_STATE.MOTHERSHIP_INTRO then
		if lovr.headset.wasPressed( player.hand, "trigger" ) then
			assets[ ASSET_TYPE.SND_MOTHERSHIP_INTRO ]:stop()
			game_state = GAME_STATE.GENERATE_LEVEL
		end

		if phrases[ phrases.idx ]:has_finished() then
			if phrases.idx < #phrases then
				if phrases.idx == 2 or phrases.idx == 6 then
					if not phrases.between_timer.started then
						phrases.between_timer:start()
					end
				else
					phrases.idx = phrases.idx + 1
				end

				if phrases.between_timer:get_elapsed() > 0.5 then
					phrases.between_timer:stop()
					phrases.idx = phrases.idx + 1
				end

				phrases[ phrases.idx ]:start()
			else
				if not phrases.last_timer.started then
					phrases.last_timer:start()
				end
			end
		end

		if phrases.idx == 9 and phrases.last_timer:get_elapsed() > 5 then
			enemy_ship_timer:stop()
			game_state = GAME_STATE.GENERATE_LEVEL
		elseif phrases.idx == 9 and phrases.last_timer:get_elapsed() > 2 and not assets[ ASSET_TYPE.SND_PADDLE_AWAY ]:isPlaying() then
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
			player.flashing_timer:start()
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
					util.release_sticky_ball()
				end
			end
		end

		local bricks_left = util.get_bricks_left()
		if bricks_left == 0 then
			local num_levels = #levels
			if cur_level < num_levels then
				cur_level = cur_level + 1
				game_state = GAME_STATE.GENERATE_LEVEL
			else
				-- NOTE Do Doh level here
			end
		end

		if player.doh_hits >= METRICS.DOH_STRENGTH then
			game_state = GAME_STATE.DEFEAT_DOH
		end
	end

	util.move_starfield( dt )
	if player.score > player.high_score then
		player.high_score = player.score
	end

	if game_state ~= GAME_STATE.EXIT_GATE and game_state ~= GAME_STATE.DEFEAT_DOH then
		gameobject.update_all( dt )
	end
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
		pass:text( "PRESS LEFT OR RIGHT TRIGGER TO START!", vec3( 0, 1.2, -2 ), METRICS.TEXT_SCALE_BIG )
		pass:text( "© 1986 TAITO CORP JAPAN", vec3( 0, 0.5, -2 ), METRICS.TEXT_SCALE_BIG )
		pass:text( "ALL RIGHTS RESERVED", vec3( 0, 0.4, -2 ), METRICS.TEXT_SCALE_BIG )
		pass:text( "This is a free, open source project made for fun.", vec3( 0, 0.3, -2 ), METRICS.TEXT_SCALE_SMALL )
		pass:text( "No copyright infringement is intended", vec3( 0, 0.25, -2 ), METRICS.TEXT_SCALE_SMALL )
	elseif game_state == GAME_STATE.MOTHERSHIP_INTRO then
		pass:setShader()
		obj_enemy_ship.model:animate( 1, enemy_ship_timer:get_elapsed() )
		obj_enemy_laser_beam.model:animate( 1, enemy_ship_timer:get_elapsed() )
		obj_paddle_escape.model:animate( 1, enemy_ship_timer:get_elapsed() )

		if phrases.idx < 3 then
			phrases[ 1 ]:draw( pass )
			phrases[ 2 ]:draw( pass )
		elseif phrases.idx < 7 then
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
		-- phywire.xray( pass, world )
		util.draw_score( pass )
	elseif game_state == GAME_STATE.LEVEL_INTRO then
		pass:setShader()
		pass:text( "ROUND " .. cur_level, vec3( 0, 1.2, -2 ), METRICS.TEXT_SCALE_BIG )
		if level_intro_timer:get_elapsed() > 1 then
			pass:text( "START", vec3( 0, 1.1, -2 ), METRICS.TEXT_SCALE_BIG )
		end
	end

	util.draw_starfield( pass )
	gameobject.draw_all( pass )
end
