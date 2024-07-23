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

function util.draw_room_colliders( pass )
	local thickness = 0.5
	local half_thickness = thickness / 2

	-- pass:box( 1.1 + half_thickness, 1.1, -5, 10, 2.2, thickness, math.pi / 2, 0, 1, 0 )

	-- pass:box( -1.1 - half_thickness, 1.1, -5, 10, 2.2, thickness, math.pi / 2, 0, 1, 0 )

	-- local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	-- pass:box( 0, 2.2 + half_thickness, -5, 10, 2.2, thickness, quat( m ) )

	-- local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	-- pass:box( 0, -half_thickness, -5, 10, 2.2, thickness, quat( m ) )

	-- pass:box( 0, 1.1, half_thickness, 2.2, 2.2, thickness )

	-- pass:box( 0, 1.1, -10 - half_thickness, 2.2, 2.2, thickness )

	local x, y, z, angle, ax, ay, az = obj_paddle.collider:getShapes()[ 1 ]:getPose()
	local radius = obj_paddle.collider:getShapes()[ 1 ]:getRadius()
	local length = obj_paddle.collider:getShapes()[ 1 ]:getLength()
	-- pass:cylinder( x, y, z, radius, length, angle, ax, ay, az )
end

function util.reflection_vector( face_normal, direction )
	local n = face_normal
	local d = direction:dot( n )
	return direction:sub( n:mul( 2 * d ) )
end

function util.brick_collision( cur_ball )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_ball.collider:getShapes()[ 1 ], vec3( cur_ball.pose ), quat( cur_ball.pose ), "brick" )

	if collider then
		if collider:getTag() == "brick" then
			local o = collider:getUserData()
			o:destroy()

			-- TODO: Currently reflecting from front of brick only.
			-- Need to determine which side of brick was hit
			cur_ball.direction:set( util.reflection_vector( vec3( 0, 0, -1 ), cur_ball.direction ) )
			assets[ ASSET_TYPE.SND_BALL_BRICK_DESTROY ]:stop()
			assets[ ASSET_TYPE.SND_BALL_BRICK_DESTROY ]:play()
		end
	end
end

function util.wall_collision( cur_ball )
	local room = cur_ball.collider:getShapes()

	for i, wall in ipairs( room ) do
		local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( wall, vec3( cur_ball.pose ), quat( cur_ball.pose ), "wall_left wall_right wall_top wall_bottom wall_back wall_front" )
		if collider then
			local n = vec3()
			local cur_ball_pos = vec3( cur_ball.pose )
			if collider:getTag() == "wall_right" then
				cur_ball.pose:set( vec3( 1.1 - 0.1, cur_ball_pos.y, cur_ball_pos.z ) )
				cur_ball.collider:setPosition( vec3( cur_ball.pose ) )
				n:set( -1, 0, 0 )
			elseif collider:getTag() == "wall_left" then
				cur_ball.pose:set( vec3( -1.1 + 0.1, cur_ball_pos.y, cur_ball_pos.z ) )
				cur_ball.collider:setPosition( vec3( cur_ball.pose ) )
				n:set( 1, 0, 0 )
			elseif collider:getTag() == "wall_top" then
				cur_ball.pose:set( vec3( cur_ball_pos.x, 2.2 - 0.1, cur_ball_pos.z ) )
				cur_ball.collider:setPosition( vec3( cur_ball.pose ) )
				n:set( 0, -1, 0 )
			elseif collider:getTag() == "wall_bottom" then
				cur_ball.pose:set( vec3( cur_ball_pos.x, 0.1, cur_ball_pos.z ) )
				cur_ball.collider:setPosition( vec3( cur_ball.pose ) )
				n:set( 0, 1, 0 )
			elseif collider:getTag() == "wall_back" then
				-- cur_ball.pose:set( vec3( cur_ball_pos.x, cur_ball_pos.y, -0.2 ) )
				n:set( 0, 0, -1 )
			elseif collider:getTag() == "wall_front" then
				-- cur_ball.pose:set( vec3( cur_ball_pos.x, cur_ball_pos.y, -4 + 0.2 ) )
				n:set( 0, 0, 1 )
			else
				print( "no tag" )
			end

			cur_ball.direction:set( util.reflection_vector( n, cur_ball.direction ) )
		end
	end
end

function util.paddle_collision( cur_ball )
	if paddle_settings.contacted then
		if paddle_settings.counter >= paddle_settings.frames_innactive then
			paddle_settings.contacted = false
			paddle_settings.counter = 0
			return
		else
			paddle_settings.counter = paddle_settings.counter + 1
			return
		end
	else
		local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_ball.collider:getShapes()[ 1 ], vec3( cur_ball.pose ), quat( cur_ball.pose ), "paddle" )

		if collider then
			if collider:getTag() == "paddle" then
				local dir = quat( obj_paddle.pose ):direction()
				cur_ball.direction:set( util.reflection_vector( dir, -cur_ball.direction ) )
				paddle_settings.contacted = true
				assets[ ASSET_TYPE.SND_BALL_TO_PADDLE ]:stop()
				assets[ ASSET_TYPE.SND_BALL_TO_PADDLE ]:play()
			end
		end
	end
end

function util.setup_room_colliders( collider )
	local thickness = 0.5
	local half_thickness = thickness / 2

	local right = world:newBoxCollider( 1.1 + half_thickness, 1.1, -5, 10, 2.2, thickness )
	right:setOrientation( math.pi / 2, 0, 1, 0 )
	right:setTag( "wall_right" )

	local left = world:newBoxCollider( -1.1 - half_thickness, 1.1, -5, 10, 2.2, thickness )
	left:setOrientation( -math.pi / 2, 0, 1, 0 )
	left:setTag( "wall_left" )

	local top = world:newBoxCollider( 0, 2.2 + half_thickness, -5, 10, 2.2, thickness )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	top:setOrientation( quat( m ) )
	top:setTag( "wall_top" )

	local bottom = world:newBoxCollider( 0, 0 - half_thickness, -5, 10, 2.2, thickness )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( -math.pi / 2, 1, 0, 0 )
	bottom:setOrientation( quat( m ) )
	bottom:setTag( "wall_bottom" )

	-- NOTE: Moved closer for testing
	local back = world:newBoxCollider( 0, 1.1, -3.3 - half_thickness, 2.2, 2.2, thickness )
	back:setTag( "wall_back" )

	local front = world:newBoxCollider( 0, 1.1, 0 + half_thickness, 2.2, 2.2, thickness )
	front:setTag( "wall_front" )

	table.insert( room_walls, right )
	table.insert( room_walls, left )
	table.insert( room_walls, top )
	table.insert( room_walls, bottom )
	table.insert( room_walls, back )
	table.insert( room_walls, front )
end

function util.generate_level()
	-- NOTE: Cleanup state here
	bricks = {}
	balls = {}
	local ball = gameobject( vec3( -0.8, 1.6, -1 ), ASSET_TYPE.BALL )
	table.insert( balls, ball )

	-- local ball = gameobject( vec3( 0.3, 1, -0.2 ), ASSET_TYPE.BALL )
	-- table.insert( balls, ball )

	-- local ball = gameobject( vec3( 0.8, 1.8, -2 ), ASSET_TYPE.BALL )
	-- table.insert( balls, ball )

	-- local ball = gameobject( vec3( 0.6, 0.8, -1 ), ASSET_TYPE.BALL )
	-- table.insert( balls, ball )

	-- w:13, h:18
	-- brick volume
	-- brick w:0.162, h:0.084
	-- gap left 0.047
	-- gap top 0.344

	local left = -(2.2 / 2) + 0.047 + (0.162 / 2)
	local top = 2.2 - 0.344 + (0.084 / 2)

	for i, v in ipairs( levels[ cur_level ] ) do
		if v ~= "0" then
			if v == "s" then
				gameobject( vec3( left, top, -3 ), ASSET_TYPE.BRICK_SILVER )
			elseif v == "$" then
				gameobject( vec3( left, top, -3 ), ASSET_TYPE.BRICK_GOLD )
			else
				gameobject( vec3( left, top, -3 ), ASSET_TYPE.BRICK, false, PASS_COLORS[ v ] )
			end

			table.insert( bricks, { position = vec3( left, top, -3 ), color = PASS_COLORS[ v ] } )
		end

		left = left + 0.162
		if i % 13 == 0 then
			top = top - 0.084
			left = -(2.2 / 2) + 0.047 + (0.162 / 2)
		end
	end

	obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP, true )
end

return util
