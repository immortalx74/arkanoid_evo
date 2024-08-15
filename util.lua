require "globals"
local util = {}
package.loaded[ ... ] = util

local gameobject = require "gameobject"
local assets = require "assets"
local powerup = require "powerup"
local timer = require "timer"

function util.sort_transparency( a, b )
	local val1 = a.transparent
	local val2 = b.transparent

	if not val1 then val1 = 0 end
	if not val2 then val2 = 0 end
	return val2 > val1
end

function util.split( input )
	local stripped = input:gsub( "[\r\n,]", "" ) -- Remove newlines and commas
	local characters = {}

	for char in stripped:gmatch( "." ) do
		table.insert( characters, char )
	end

	return characters
end

function util.reflection_vector( face_normal, direction )
	local n = face_normal
	local d = direction:dot( n )
	return direction:sub( n:mul( 2 * d ) )
end

function util.get_hit_face( nx, ny, nz )
	-- snippet credit: j_miskov, https://github.com/jmiskovic
	local direcions = {
		{ 'top',    vec3.down },
		{ 'bottom', vec3.up },
		{ 'left',   vec3.right },
		{ 'right',  vec3.left },
		{ 'front',  vec3.forward },
		{ 'back',   vec3.back }
	}

	local n = vec3( nx, ny, nz )
	local max_dot_product = -math.huge
	local best_match
	for _, dir in ipairs( direcions ) do
		local dot = n:dot( dir[ 2 ] )
		if dot > max_dot_product then
			max_dot_product = dot
			best_match = dir
		end
	end
	return best_match
end

function util.setup_room_colliders( collider )
	local thickness = 0.5
	local half_thickness = METRICS.WALL_THICKNESS / 2

	local right = world:newBoxCollider( (METRICS.ROOM_WIDTH / 2) + half_thickness, (METRICS.ROOM_HEIGHT / 2), -METRICS.ROOM_DEPTH / 2, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	right:setOrientation( math.pi / 2, 0, 1, 0 )
	right:setTag( "wall_right" )

	local left = world:newBoxCollider( -(METRICS.ROOM_WIDTH / 2) - half_thickness, (METRICS.ROOM_HEIGHT / 2), -METRICS.ROOM_DEPTH / 2, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	left:setOrientation( -math.pi / 2, 0, 1, 0 )
	left:setTag( "wall_left" )

	local top = world:newBoxCollider( 0, METRICS.ROOM_HEIGHT + half_thickness, -METRICS.ROOM_DEPTH / 2, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	top:setOrientation( quat( m ) )
	top:setTag( "wall_top" )

	local bottom = world:newBoxCollider( 0, -half_thickness, -METRICS.ROOM_DEPTH / 2, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( -math.pi / 2, 1, 0, 0 )
	bottom:setOrientation( quat( m ) )
	bottom:setTag( "wall_bottom" )

	-- NOTE: Moved closer for testing
	local back = world:newBoxCollider( 0, (METRICS.ROOM_HEIGHT / 2), -METRICS.ROOM_DEPTH - half_thickness, METRICS.ROOM_WIDTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	back:setTag( "wall_far" )

	local front = world:newBoxCollider( 0, (METRICS.ROOM_HEIGHT / 2), half_thickness, METRICS.ROOM_WIDTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	front:setTag( "wall_near" )

	table.insert( room_colliders, right )
	table.insert( room_colliders, left )
	table.insert( room_colliders, top )
	table.insert( room_colliders, bottom )
	table.insert( room_colliders, back )
	table.insert( room_colliders, front )
end

function util.spawn_paddle( paddle_type )
	if obj_paddle then obj_paddle:destroy() end
	if obj_paddle_top then obj_paddle_top:destroy() end
	if obj_paddle_spinner then obj_paddle_spinner:destroy() end

	if paddle_type == ASSET_TYPE.PADDLE then
		obj_paddle = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE )
		obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP, METRICS.TRANSPARENCY_IDX_PADDLE_TOP )
		obj_paddle_spinner = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_SPINNER )
	elseif paddle_type == ASSET_TYPE.PADDLE_BIG then
		obj_paddle = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_BIG )
		obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP_BIG, METRICS.TRANSPARENCY_IDX_PADDLE_TOP )
		obj_paddle_spinner = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_SPINNER_BIG )
	else
		obj_paddle = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_LASER )
		obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP, METRICS.TRANSPARENCY_IDX_PADDLE_TOP )
		obj_paddle_spinner = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_SPINNER )
	end
end

function util.generate_level()
	gameobject.destroy_all()

	local left = -(METRICS.ROOM_WIDTH / 2) + METRICS.GAP_LEFT + (METRICS.BRICK_WIDTH / 2)
	local top = METRICS.ROOM_HEIGHT - METRICS.GAP_TOP + (METRICS.BRICK_HEIGHT / 2)

	for i, v in ipairs( levels[ cur_level ] ) do
		if v ~= "0" then
			if v == "s" then
				gameobject( vec3( left, top, -METRICS.BRICK_DIST_Z ), ASSET_TYPE.BRICK_SILVER )
			elseif v == "$" then
				gameobject( vec3( left, top, -METRICS.BRICK_DIST_Z ), ASSET_TYPE.BRICK_GOLD )
			else
				gameobject( vec3( left, top, -METRICS.BRICK_DIST_Z ), ASSET_TYPE.BRICK, false, BRICK_COLORS[ v ] )
			end
		end

		left = left + METRICS.BRICK_WIDTH
		if i % METRICS.NUM_BRICK_COLS == 0 then
			top = top - METRICS.BRICK_HEIGHT
			left = -(METRICS.ROOM_WIDTH / 2) + METRICS.GAP_LEFT + (METRICS.BRICK_WIDTH / 2)
		end
	end

	util.spawn_paddle( ASSET_TYPE.PADDLE )
	obj_room = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.ROOM )
	obj_room_glass = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.ROOM_GLASS, METRICS.TRANSPARENCY_IDX_ROOM_GLASS )

	player.paddle_cooldown_timer:start()
	player.laser_cooldown_timer:start()
	powerup.timer:start()
end

function util.create_start_screen()
	obj_arkanoid_logo = gameobject( vec3( 0, 2, -2 ), ASSET_TYPE.ARKANOID_LOGO )
	obj_taito_logo = gameobject( vec3( 0, 0.65, -2 ), ASSET_TYPE.TAITO_LOGO )
	game_state = GAME_STATE.START_SCREEN
end

function util.create_mothership_intro( hand )
	player.hand = hand
	obj_arkanoid_logo:destroy()
	obj_taito_logo:destroy()
	obj_mothership = gameobject( vec3( 0, -0.8, -3 ), ASSET_TYPE.MOTHERSHIP )
	obj_mothership.pose:rotate( -0.8, 0, 1, 0 )

	obj_enemy_ship = gameobject( vec3( 0, -0.8, -3 ), ASSET_TYPE.ENEMY_SHIP )
	obj_enemy_laser_beam = gameobject( vec3( 0, -0.8, -3 ), ASSET_TYPE.ENEMY_LASER_BEAM )
	obj_paddle_escape = gameobject( vec3( 0, -0.87, -3 ), ASSET_TYPE.PADDLE_ESCAPE )
	enemy_ship_timer = timer( true )
	
	assets[ ASSET_TYPE.SND_MOTHERSHIP_INTRO ]:stop()
	assets[ ASSET_TYPE.SND_MOTHERSHIP_INTRO ]:play()
	
	game_state = GAME_STATE.MOTHERSHIP_INTRO
end

return util
