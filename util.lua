require "globals"
local util = {}
package.loaded[ ... ] = util

local gameobject = require "gameobject"
local assets = require "assets"

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

function util.brick_collision( cur_ball )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_ball.collider:getShapes()[ 1 ], vec3( cur_ball.pose ), quat( cur_ball.pose ), "brick" )

	if collider then
		if collider:getTag() == "brick" then
			local o = collider:getUserData()

			local t = util.get_hit_face( nx, ny, nz )
			local str = t[ 1 ]
			local face_normal = t[ 2 ]

			cur_ball.direction:set( util.reflection_vector( face_normal, cur_ball.direction ) )

			if o.type == ASSET_TYPE.BRICK or o.type == ASSET_TYPE.BRICK_SILVER then
				o.strength = o.strength - 1
				if o.strength == 0 then
					o:destroy()
					assets[ ASSET_TYPE.SND_BALL_BRICK_DESTROY ]:stop()
					assets[ ASSET_TYPE.SND_BALL_BRICK_DESTROY ]:play()
				else
					assets[ ASSET_TYPE.SND_BALL_BRICK_DING ]:stop()
					assets[ ASSET_TYPE.SND_BALL_BRICK_DING ]:play()
				end
			else
				assets[ ASSET_TYPE.SND_BALL_BRICK_DING ]:stop()
				assets[ ASSET_TYPE.SND_BALL_BRICK_DING ]:play()
			end

			-- Do crude collision resolution
			local v = vec3( cur_ball.pose )
			cur_ball.pose:set( vec3( v.x - nx, v.y - ny, v.z - nz ) )
			cur_ball.collider:setPosition( vec3( cur_ball.pose ) )
		end
	end
end

function util.wall_collision( cur_ball )
	local room = cur_ball.collider:getShapes()

	for i, wall in ipairs( room ) do
		local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( wall, vec3( cur_ball.pose ), quat( cur_ball.pose ), "wall_left wall_right wall_top wall_bottom wall_far wall_near" )
		if collider then
			local n = vec3()
			local cur_ball_pos = vec3( cur_ball.pose )
			if collider:getTag() == "wall_right" then
				n:set( -1, 0, 0 )
			elseif collider:getTag() == "wall_left" then
				n:set( 1, 0, 0 )
			elseif collider:getTag() == "wall_top" then
				n:set( 0, -1, 0 )
			elseif collider:getTag() == "wall_bottom" then
				n:set( 0, 1, 0 )
			elseif collider:getTag() == "wall_far" then
				n:set( 0, 0, -1 )
			elseif collider:getTag() == "wall_near" then
				n:set( 0, 0, 1 )
			end

			cur_ball.pose:translate( -nx, -ny, -nz )
			cur_ball.direction:set( util.reflection_vector( n, cur_ball.direction ) )
		end
	end
end

function util.paddle_collision( cur_ball )
	if player.contacted then
		if player.cooldown_timer:get_elapsed() >= player.cooldown_interval then
			player.contacted = false
			player.cooldown_timer:start()
		end
	else
		local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_ball.collider:getShapes()[ 1 ], vec3( cur_ball.pose ), quat( cur_ball.pose ), "paddle" )

		if collider then
			if collider:getTag() == "paddle" then
				local m = mat4( obj_paddle.pose ):rotate( math.pi / 2, 1, 0, 0 )
				local v = quat( m ):direction()

				local dir = quat( obj_paddle.pose ):direction()
				cur_ball.direction:set( util.reflection_vector( vec3( v ), cur_ball.direction ) )

				-- Place ball slightly in front to prevent collision on subsequent frames
				local v = vec3( cur_ball.pose )
				cur_ball.pose:set( vec3( v.x - nx, v.y - ny, v.z - nz - 0.05 ) )
				cur_ball.collider:setPosition( vec3( cur_ball.pose ) )

				player.contacted = true
				assets[ ASSET_TYPE.SND_BALL_TO_PADDLE ]:stop()
				assets[ ASSET_TYPE.SND_BALL_TO_PADDLE ]:play()
				return true
			end
		end
	end

	return false
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

function util.generate_level()
	-- NOTE: Cleanup state here
	balls = {}
	local ball = gameobject( vec3( -0.8, 1.6, -1 ), ASSET_TYPE.BALL )
	table.insert( balls, ball )

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

	obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP, true )
	player.cooldown_timer:start()
end

return util
