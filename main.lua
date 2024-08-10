require "globals"
local gameobject = require "gameobject"
local assets = require "assets"
local util = require "util"
local powerup = require "powerup"
local timer = require "timer"

function lovr.load()
	assets.load()
	assets.load_levels()
	game_state = GAME_STATE.GENERATE_LEVEL
end

function lovr.keypressed( key, scancode, rep )
	if key == "return" then
		paused = not paused
	end
end

function lovr.update( dt )
	if game_state == GAME_STATE.GENERATE_LEVEL then
		util.generate_level()
		game_state = GAME_STATE.PLAY
	elseif game_state == GAME_STATE.PLAY then
		if powerup.owned == ASSET_TYPE.POWERUP_L then
			if lovr.headset.wasPressed( player.hand, "trigger" ) then
				if player.laser_cooldown_timer:get_elapsed() >= METRICS.LASER_COOLDOWN_INTERVAL then
					local x, y, z, angle, ax, ay, az = lovr.headset.getPose( player.hand )
					gameobject( mat4( vec3( x, y, z ), quat( angle, ax, ay, az ) ), ASSET_TYPE.PROJECTILE )
					player.laser_cooldown_timer:start()
				end
			end
		end
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

	if game_state == GAME_STATE.PLAY then
		gameobject.draw_all( pass )
		-- phywire.draw( pass, world )
	end
end
