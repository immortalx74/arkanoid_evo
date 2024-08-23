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
	local half_thickness = METRICS.WALL_THICKNESS / 2

	local right = world:newBoxCollider( (METRICS.ROOM_WIDTH / 2) + half_thickness, (METRICS.ROOM_HEIGHT / 2), (-METRICS.ROOM_DEPTH / 2) + METRICS.ROOM_OFFSET_Z, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT,
		METRICS.WALL_THICKNESS )
	right:setOrientation( math.pi / 2, 0, 1, 0 )
	right:setTag( "wall_right" )

	local left = world:newBoxCollider( -(METRICS.ROOM_WIDTH / 2) - half_thickness, (METRICS.ROOM_HEIGHT / 2), (-METRICS.ROOM_DEPTH / 2) + METRICS.ROOM_OFFSET_Z, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT,
		METRICS.WALL_THICKNESS )
	left:setOrientation( -math.pi / 2, 0, 1, 0 )
	left:setTag( "wall_left" )

	local top = world:newBoxCollider( 0, METRICS.ROOM_HEIGHT + half_thickness, (-METRICS.ROOM_DEPTH / 2) + METRICS.ROOM_OFFSET_Z, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	top:setOrientation( quat( m ) )
	top:setTag( "wall_top" )

	local bottom = world:newBoxCollider( 0, -half_thickness, (-METRICS.ROOM_DEPTH / 2) + METRICS.ROOM_OFFSET_Z, METRICS.ROOM_DEPTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( -math.pi / 2, 1, 0, 0 )
	bottom:setOrientation( quat( m ) )
	bottom:setTag( "wall_bottom" )

	local back = world:newBoxCollider( 0, (METRICS.ROOM_HEIGHT / 2), (-METRICS.ROOM_DEPTH - half_thickness) + METRICS.ROOM_OFFSET_Z, METRICS.ROOM_WIDTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
	back:setTag( "wall_far" )

	if player.invincible then
		local front = world:newBoxCollider( 0, (METRICS.ROOM_HEIGHT / 2), half_thickness + METRICS.ROOM_OFFSET_Z, METRICS.ROOM_WIDTH, METRICS.ROOM_HEIGHT, METRICS.WALL_THICKNESS )
		front:setTag( "wall_near" )
	end

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
	util.create_wanderers()
	powerup.owned = nil
	powerup.falling = nil

	local left = -(METRICS.ROOM_WIDTH / 2) + METRICS.GAP_LEFT + (METRICS.BRICK_WIDTH / 2)
	local top = METRICS.ROOM_HEIGHT - METRICS.GAP_TOP + (METRICS.BRICK_HEIGHT / 2)

	for i, v in ipairs( levels[ cur_level ] ) do
		if v ~= "0" then
			if v == "s" then
				gameobject( vec3( left, top, -METRICS.BRICK_DIST_Z ), ASSET_TYPE.BRICK_SILVER )
			elseif v == "$" then
				gameobject( vec3( left, top, -METRICS.BRICK_DIST_Z ), ASSET_TYPE.BRICK_GOLD )
			else
				gameobject( vec3( left, top, -METRICS.BRICK_DIST_Z ), ASSET_TYPE.BRICK, false, BRICK_COLORS[ v ], BRICK_POINTS[ v ] )
			end
		end

		left = left + METRICS.BRICK_WIDTH
		if i % METRICS.NUM_BRICK_COLS == 0 then
			top = top - METRICS.BRICK_HEIGHT
			left = -(METRICS.ROOM_WIDTH / 2) + METRICS.GAP_LEFT + (METRICS.BRICK_WIDTH / 2)
		end
	end

	util.spawn_paddle( ASSET_TYPE.PADDLE )
	obj_feet = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.FEET_MARK, METRICS.TRANSPARENCY_IDX_FEET_MARK )
	obj_room = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.ROOM )
	obj_room_glass = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.ROOM_GLASS, METRICS.TRANSPARENCY_IDX_ROOM_GLASS )

	if cur_level == 33 then
		gameobject( vec3( 0, 0, -METRICS.ROOM_DEPTH + 1 ), ASSET_TYPE.DOH )
		gameobject( vec3( 0, 0, -METRICS.ROOM_DEPTH + 1 ), ASSET_TYPE.DOH_COLLISION )
	end

	player.paddle_cooldown_timer:start()
	player.laser_cooldown_timer:start()
	player.gate_open = false
	powerup.timer:start()
end

function util.create_start_screen()
	gameobject.destroy_all()
	powerup.owned = nil
	powerup.falling = nil
	player.paddle_cooldown_timer:stop()
	player.laser_cooldown_timer:stop()
	player.gate_open = false
	player.lives = 3
	player.score = 0
	player.doh_hits = 0
	powerup.timer:stop()

	obj_arkanoid_logo = gameobject( vec3( 0, 2, -2 ), ASSET_TYPE.ARKANOID_LOGO )
	obj_taito_logo = gameobject( vec3( 0, 0.65, -2 ), ASSET_TYPE.TAITO_LOGO )
	game_state = GAME_STATE.START_SCREEN
end

function util.point_in_volume( px, py, pz, vx, vy, vz, vw, vh, vd )
	if px > vx - (vw / 2) and px < vx + (vw / 2) and
		py > vy - (vh / 2) and py < vy + (vh / 2) and
		pz > vz - (vd / 2) and pz < vz + (vd / 2)
	then
		return true
	end

	return false
end

function util.create_mothership_intro( hand, invincible )
	if invincible then player.invincible = true end
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

function util.create_ending()
	gameobject.destroy_all()
	
	obj_mothership = gameobject( vec3( 0, -0.8, -3 ), ASSET_TYPE.MOTHERSHIP )
	obj_mothership.pose:rotate( -0.8, 0, 1, 0 )

	obj_enemy_ship = gameobject( vec3( 0, -0.8, -3 ), ASSET_TYPE.ENEMY_SHIP )
	obj_enemy_laser_beam = gameobject( vec3( 0, -0.8, -3 ), ASSET_TYPE.ENEMY_LASER_BEAM )
	obj_paddle_escape = gameobject( vec3( 0, -0.87, -3 ), ASSET_TYPE.PADDLE_ESCAPE )
	assets[ ASSET_TYPE.SND_ENDING_THEME ]:play()
end

function util.create_starfield()
	for i = 1, 1000 do
		local rx = math.random( -10, 10 )
		local ry = math.random( -10, 10 )
		local rz = math.random( -50, 49 )
		local rs = math.random( 1, 3 )
		table.insert( starfield, { rx, ry, rz, rs } )
	end
end

function util.move_starfield( dt )
	if game_state == GAME_STATE.LEVEL_INTRO or game_state == GAME_STATE.PLAY then
		starfield.points = {}
		for i, v in ipairs( starfield ) do
			v[ 3 ] = v[ 3 ] + (v[ 4 ] * dt)

			if v[ 3 ] > 50 then v[ 3 ] = -50 end

			if not util.point_in_volume( v[ 1 ], v[ 2 ], v[ 3 ], 0, 1.1, -1.5, 2.2, 2.2, 5 ) then
				table.insert( starfield.points, v[ 1 ] )
				table.insert( starfield.points, v[ 2 ] )
				table.insert( starfield.points, v[ 3 ] )
			end
		end
	end
end

function util.draw_starfield( pass )
	if game_state == GAME_STATE.LEVEL_INTRO or game_state == GAME_STATE.PLAY or game_state == GAME_STATE.LOST_LIFE or game_state == GAME_STATE.GAME_OVER then
		pass:setShader( assets[ ASSET_TYPE.SHADER_UNLIT ] )
		pass:setColor( 1, 1, 1 )
		pass:points( starfield.points )
		pass:setShader( assets[ ASSET_TYPE.SHADER_PBR ] )
		pass:send( 'cubemap', assets[ ASSET_TYPE.SKYBOX ] )
		pass:send( 'sphericalHarmonics', assets[ ASSET_TYPE.SPHERICAL_HARMONICS ] )
	end
end

function util.get_bricks_left()
	local count = 0

	for i, v in ipairs( gameobjects_list ) do
		if v.type == ASSET_TYPE.BRICK or v.type == ASSET_TYPE.BRICK_SILVER then
			count = count + 1
		end
	end

	return count
end

function util.set_ball_speed( speed )
	local ball = nil
	for i, v in ipairs( gameobjects_list ) do
		if v.type == ASSET_TYPE.BALL then
			v.velocity = speed / METRICS.SUBSTEPS
			break
		end
	end
end

function util.create_wanderers()
	local rx, ry, rz = math.random( -15, -10 ), math.random( -10, -4 ), math.random( -15, -10 )
	local ro = math.random( ASSET_TYPE.ENEMY_BALOONS, ASSET_TYPE.ENEMY_PYRAMID )
	gameobject( vec3( rx, ry, rz ), ro )

	local rx, ry, rz = math.random( 15, 10 ), math.random( -10, -4 ), math.random( -15, -10 )
	local ro = math.random( ASSET_TYPE.ENEMY_BALOONS, ASSET_TYPE.ENEMY_PYRAMID )
	gameobject( vec3( rx, ry, rz ), ro )

	local rx, ry, rz = math.random( -15, -10 ), math.random( 10, 4 ), math.random( -10, -5 )
	local ro = math.random( ASSET_TYPE.ENEMY_BALOONS, ASSET_TYPE.ENEMY_PYRAMID )
	gameobject( vec3( rx, ry, rz ), ro )

	local rx, ry, rz = math.random( 15, 10 ), math.random( 10, -4 ), math.random( -10, -5 )
	local ro = math.random( ASSET_TYPE.ENEMY_BALOONS, ASSET_TYPE.ENEMY_PYRAMID )
	gameobject( vec3( rx, ry, rz ), ro )

	local rx, ry, rz = math.random( -10, -5 ), math.random( 0, 5 ), math.random( -25, -20 )
	local ro = math.random( ASSET_TYPE.ENEMY_BALOONS, ASSET_TYPE.ENEMY_PYRAMID )
	gameobject( vec3( rx, ry, rz ), ro )

	local rx, ry, rz = math.random( 10, 5 ), math.random( 0, 5 ), math.random( -25, -20 )
	local ro = math.random( ASSET_TYPE.ENEMY_BALOONS, ASSET_TYPE.ENEMY_PYRAMID )
	gameobject( vec3( rx, ry, rz ), ro )
end

function util.draw_score( pass )
	pass:setShader()
	pass:setColor( 1, 0, 0 )
	if player.flashing_timer:get_elapsed() > 0.5 and player.flashing_timer:get_elapsed() < 1 then
		pass:text( "1UP", vec3( -0.9, 3, -5 ), 0.1 )
	end

	if player.flashing_timer:get_elapsed() > 1 then
		player.flashing_timer:start()
	end

	pass:text( "HIGH SCORE", vec3( 0, 3, -5 ), 0.1 )

	pass:setColor( 1, 1, 1 )
	pass:text( player.score, vec3( -0.9, 2.9, -5 ), 0.1 )
	pass:text( player.high_score, vec3( 0, 2.9, -5 ), 0.1 )

	pass:setMaterial( assets[ ASSET_TYPE.LIFE_ICON ] )

	local x = -0.9
	for i = 1, player.lives - 1 do
		pass:plane( vec3( x, 2.7, -5 ), vec2( 0.2, 0.1 ) )
		x = x + 0.2
	end
	pass:setMaterial()
end

function util.release_sticky_ball()
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

function util.get_num_balls()
	local count = 0
	for i, v in ipairs( gameobjects_list ) do
		if v.type == ASSET_TYPE.BALL then
			count = count + 1
		end
	end

	return count
end

function util.get_model_normals( model )
	local vertices, indices = model:getTriangles()
	local directions = {}

	for i = 1, #indices, 3 do
		local va = vec3( vertices[ indices[ i + 0 ] + 0 ], vertices[ indices[ i + 0 ] + 1 ], vertices[ indices[ i + 0 ] ] + 2 )
		local vb = vec3( vertices[ indices[ i + 1 ] + 0 ], vertices[ indices[ i + 1 ] + 1 ], vertices[ indices[ i + 1 ] ] + 2 )
		local vc = vec3( vertices[ indices[ i + 2 ] + 0 ], vertices[ indices[ i + 2 ] + 1 ], vertices[ indices[ i + 2 ] ] + 2 )

		local triangle = vec3( va, vb, vc )
		local dir = vec3( vb - va )
		dir:cross( vc - va )
		dir:normalize()
		table.insert( directions, { triangle = { lovr.math.newVec3( va ), lovr.math.newVec3( vb ), lovr.math.newVec3( vc ) }, normal = lovr.math.newVec3( dir ) } )
	end

	return vertices, indices, directions
end

function util.point_in_triangle( A, B, C, P )
	local AB = A:sub( B )
	local AC = A:sub( C )
	local AP = A:sub( P )

	local ABxAC = AB:cross( AC )
	local ABxAP = AB:cross( AP )
	local ACxAP = AC:cross( AP )

	local area_ABC = ABxAC:length()
	local area_ABP = ABxAP:length()
	local area_ACP = ACxAP:length()

	local PB = P:sub( B )
	local PC = P:sub( C )
	local PBxPC = PB:cross( PC )
	local area_PBC = PBxPC:length()

	local total_sub_areas = area_ABP + area_ACP + area_PBC

	local tolerance = 1e-6
	return math.abs( area_ABC - total_sub_areas ) < tolerance
end

return util
