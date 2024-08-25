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
	elseif game_state == GAME_STATE.ENDING then
		if lovr.headset.wasPressed( player.hand, "trigger" ) then
			assets[ ASSET_TYPE.SND_ENDING_THEME ]:stop()
			game_state = GAME_STATE.INIT
		end

		if phrases_ending[ phrases_ending.idx ]:has_finished() then
			if phrases_ending.idx < #phrases_ending then
				if phrases_ending.idx == 4 or phrases_ending.idx == 6 then
					if not phrases_ending.between_timer.started then
						phrases_ending.between_timer:start()
					end
				else
					phrases_ending.idx = phrases_ending.idx + 1
				end

				if phrases_ending.between_timer:get_elapsed() > 0.5 then
					phrases_ending.between_timer:stop()
					phrases_ending.idx = phrases_ending.idx + 1
				end

				phrases_ending[ phrases_ending.idx ]:start()
			else
				if not phrases_ending.last_timer.started then
					phrases_ending.last_timer:start()
				end
			end
		end

		if phrases_ending.idx == 9 and phrases_ending.last_timer:get_elapsed() > 5 then
			enemy_ship_timer:stop()
			-- game_state = GAME_STATE.GENERATE_LEVEL
		elseif phrases_ending.idx == 9 and phrases_ending.last_timer:get_elapsed() > 2 then
			enemy_ship_timer:stop()
		end
	elseif game_state == GAME_STATE.GAME_OVER then
		if lovr.headset.wasPressed( player.hand, "trigger" ) then
			cur_level = 1
			game_state = GAME_STATE.INIT
		end
	elseif game_state == GAME_STATE.LOST_LIFE then
		if not assets[ ASSET_TYPE.SND_LOST_LIFE ]:isPlaying() then
			if player.lives == 0 then
				game_state = GAME_STATE.GAME_OVER
				if not assets[ ASSET_TYPE.SND_GAME_OVER ]:isPlaying() then
					assets[ ASSET_TYPE.SND_GAME_OVER ]:play()
				end
			else
				game_state = GAME_STATE.LEVEL_INTRO
				level_intro_timer:start()
				assets[ ASSET_TYPE.SND_LEVEL_INTRO ]:stop()
				assets[ ASSET_TYPE.SND_LEVEL_INTRO ]:play()
			end
		end
	elseif game_state == GAME_STATE.EXIT_GATE then
		if not assets[ ASSET_TYPE.SND_ESCAPE_LEVEL ]:isPlaying() then
			game_state = GAME_STATE.GENERATE_LEVEL
		end
	elseif game_state == GAME_STATE.START_SCREEN then
		local invincible = lovr.headset.isDown( "left", "x" ) or lovr.headset.isDown( "right", "a" )
		if lovr.headset.wasPressed( "left", "trigger" ) then
			util.create_mothership_intro( "left", invincible )
		elseif lovr.headset.wasPressed( "right", "trigger" ) then
			util.create_mothership_intro( "right", invincible )
		end
	elseif game_state == GAME_STATE.MOTHERSHIP_INTRO then
		if lovr.headset.wasPressed( player.hand, "trigger" ) then
			assets[ ASSET_TYPE.SND_MOTHERSHIP_INTRO ]:stop()
			game_state = GAME_STATE.GENERATE_LEVEL
		end

		if phrases_intro[ phrases_intro.idx ]:has_finished() then
			if phrases_intro.idx < #phrases_intro then
				if phrases_intro.idx == 2 or phrases_intro.idx == 6 then
					if not phrases_intro.between_timer.started then
						phrases_intro.between_timer:start()
					end
				else
					phrases_intro.idx = phrases_intro.idx + 1
				end

				if phrases_intro.between_timer:get_elapsed() > 0.5 then
					phrases_intro.between_timer:stop()
					phrases_intro.idx = phrases_intro.idx + 1
				end

				phrases_intro[ phrases_intro.idx ]:start()
			else
				if not phrases_intro.last_timer.started then
					phrases_intro.last_timer:start()
				end
			end
		end

		if phrases_intro.idx == 9 and phrases_intro.last_timer:get_elapsed() > 5 then
			enemy_ship_timer:stop()
			game_state = GAME_STATE.GENERATE_LEVEL
		elseif phrases_intro.idx == 9 and phrases_intro.last_timer:get_elapsed() > 2 and not assets[ ASSET_TYPE.SND_PADDLE_AWAY ]:isPlaying() then
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
			level_intro_timer:stop()
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
			end
		end

		local num_balls_left = util.get_num_balls()
		if num_balls_left == 0 then
			game_state = GAME_STATE.LOST_LIFE
			player.lives = player.lives - 1
			if not assets[ ASSET_TYPE.SND_LOST_LIFE ]:isPlaying() then
				assets[ ASSET_TYPE.SND_LOST_LIFE ]:play()
			end
		end

		if player.doh_hits >= METRICS.DOH_STRENGTH then
			game_state = GAME_STATE.ENDING
			util.create_ending()
			enemy_ship_timer:start()
		end
	end

	util.move_starfield( dt )
	if player.score > player.high_score then
		player.high_score = player.score
	end

	if game_state ~= GAME_STATE.EXIT_GATE and game_state ~= GAME_STATE.ENDING then
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
	elseif game_state == GAME_STATE.ENDING then
		pass:setShader()
		obj_enemy_ship.model:animate( 1, obj_enemy_ship.model:getAnimationDuration( 1 ) - enemy_ship_timer:get_elapsed() )
		obj_enemy_laser_beam.model:animate( 1, obj_enemy_laser_beam.model:getAnimationDuration( 1 ) - enemy_ship_timer:get_elapsed() )
		obj_paddle_escape.model:animate( 1, obj_paddle_escape.model:getAnimationDuration( 1 ) - enemy_ship_timer:get_elapsed() )

		if phrases_ending.idx < 5 then
			phrases_ending[ 1 ]:draw( pass )
			phrases_ending[ 2 ]:draw( pass )
			phrases_ending[ 3 ]:draw( pass )
			phrases_ending[ 4 ]:draw( pass )
		elseif phrases_ending.idx < 7 then
			phrases_ending[ 5 ]:draw( pass )
			phrases_ending[ 6 ]:draw( pass )
		else
			phrases_ending[ 7 ]:draw( pass )
			phrases_ending[ 8 ]:draw( pass )
			phrases_ending[ 9 ]:draw( pass )
		end
	elseif game_state == GAME_STATE.MOTHERSHIP_INTRO then
		pass:setShader()
		obj_enemy_ship.model:animate( 1, enemy_ship_timer:get_elapsed() )
		obj_enemy_laser_beam.model:animate( 1, enemy_ship_timer:get_elapsed() )
		obj_paddle_escape.model:animate( 1, enemy_ship_timer:get_elapsed() )

		if phrases_intro.idx < 3 then
			phrases_intro[ 1 ]:draw( pass )
			phrases_intro[ 2 ]:draw( pass )
		elseif phrases_intro.idx < 7 then
			phrases_intro[ 3 ]:draw( pass )
			phrases_intro[ 4 ]:draw( pass )
			phrases_intro[ 5 ]:draw( pass )
			phrases_intro[ 6 ]:draw( pass )
		else
			phrases_intro[ 7 ]:draw( pass )
			phrases_intro[ 8 ]:draw( pass )
			phrases_intro[ 9 ]:draw( pass )
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
	elseif game_state == GAME_STATE.GAME_OVER then
		pass:setShader()
		pass:text( "GAME OVER", vec3( 0, 1.2, -2 ), METRICS.TEXT_SCALE_BIG )
		pass:text( "[Press trigger to restart]", vec3( 0, 1.1, -2 ), METRICS.TEXT_SCALE_SMALL )
		pass:setShader( assets[ ASSET_TYPE.SHADER_PBR ] )
	end

	util.draw_starfield( pass )
	gameobject.draw_all( pass )
end
