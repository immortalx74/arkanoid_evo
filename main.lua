require "globals"
local gameobject = require "gameobject"
local assets = require "assets"
local util = require "util"

function lovr.load()
	assets.load()
	assets.load_levels()

	obj_paddle = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE )
	obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP, true )
	obj_room = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.ROOM )
	obj_room_glass = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.ROOM_GLASS, true )
	game_state = GAME_STATE.GENERATE_LEVEL
end

function lovr.keypressed( key, scancode, rep )
	if key == "return" then
		aaa = true
	end
end

function lovr.update( dt )
	if game_state == GAME_STATE.GENERATE_LEVEL then
		util.generate_level()
		game_state = GAME_STATE.PLAY
	elseif game_state == GAME_STATE.PLAY then
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
		util.draw_room_colliders( pass )
	end
end
