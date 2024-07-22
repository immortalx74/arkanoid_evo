require "globals"
local util = {}
package.loaded[ ... ] = util

local gameobject = require "gameobject"

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

	pass:box( 0, 1.1, half_thickness, 2.2, 2.2, thickness )

	pass:box( 0, 1.1, -10 - half_thickness, 2.2, 2.2, thickness )

	local x, y, z, angle, ax, ay, az = obj_paddle.collider:getShapes()[ 1 ]:getPose()
	local radius = obj_paddle.collider:getShapes()[ 1 ]:getRadius()
	local length = obj_paddle.collider:getShapes()[ 1 ]:getLength()
	pass:cylinder( x, y, z, radius, length, angle, ax, ay, az )
end

function util.reflection_vector( face_normal, direction )
	local n = face_normal
	local d = direction:dot( n )
	return direction:sub( n:mul( 2 * d ) )
end

function util.brick_collision( self )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( self.collider:getShapes()[ 1 ], vec3( self.pose ), quat( self.pose ), "brick" )

	if collider then
		if collider:getTag() == "brick" then
			local o = collider:getUserData()
			o:destroy()

			-- TODO: Currently reflecting from front of brick only.
			-- Need to determine which side of brick was hit
			self.direction:set( util.reflection_vector( vec3( 0, 0, -1 ), self.direction ) )
		end
	end
end

function util.wall_collision( self )
	local room = self.collider:getShapes()

	for i, wall in ipairs( room ) do
		local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( wall, vec3( self.pose ), quat( self.pose ), "wall" )
		if shape then
			if collider:getTag() == "wall" then
				local n = vec3()
				local cur_ball_pos = vec3( self.pose )
				if shape:getUserData() == "right" then
					-- self.pose:set( vec3( 1.1 - 0.2, cur_ball_pos.y, cur_ball_pos.z ) )
					n:set( -1, 0, 0 )
				elseif shape:getUserData() == "left" then
					-- self.pose:set( vec3( -1.1 + 0.2, cur_ball_pos.y, cur_ball_pos.z ) )
					n:set( 1, 0, 0 )
				elseif shape:getUserData() == "top" then
					-- self.pose:set( vec3( cur_ball_pos.x, 1.1 - 0.2, cur_ball_pos.z ) )
					n:set( 0, -1, 0 )
				elseif shape:getUserData() == "bottom" then
					-- self.pose:set( vec3( cur_ball_pos.x, 0.2, cur_ball_pos.z ) )
					n:set( 0, 1, 0 )
				elseif shape:getUserData() == "back" then
					-- self.pose:set( vec3( cur_ball_pos.x, cur_ball_pos.y, -0.2 ) )
					n:set( 0, 0, -1 )
				elseif shape:getUserData() == "front" then
					-- self.pose:set( vec3( cur_ball_pos.x, cur_ball_pos.y, -10 + 0.2 ) )
					n:set( 0, 0, 1 )
				else
					local x, y, z = shape:getPosition()
					print( shape:getType(), shape:getCollider():getTag(), x, y, z )
				end

				if n then
					self.direction:set( util.reflection_vector( n, self.direction ) )
					return
				else
					print( self.direction )
					self.direction:set( -self.direction )
					return
				end
			end
		end
	end
end

function util.setup_room_collider_shapes( collider )
	-- TODO: Ball collision is undetected when passing through wall corners
	-- Extend wall colliders???
	local thickness = 0.5
	local half_thickness = thickness / 2

	local right = lovr.physics.newBoxShape( 10, 2.2, thickness )
	right:setOffset( 1.1 + half_thickness, 1.1, -5, math.pi / 2, 0, 1, 0 )
	right:setUserData( "right" )
	collider:addShape( right )

	local left = lovr.physics.newBoxShape( 10, 2.2, thickness )
	left:setOffset( -1.1 - half_thickness, 1.1, -5, -math.pi / 2, 0, 1, 0 )
	left:setUserData( "left" )
	collider:addShape( left )

	local top = lovr.physics.newBoxShape( 10, 2.2, thickness )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	top:setOffset( 0, 2.2 + half_thickness, -5, quat( m ) )
	top:setUserData( "top" )
	collider:addShape( top )

	local bottom = lovr.physics.newBoxShape( 10, 2.2, thickness )
	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	bottom:setOffset( 0, -half_thickness, -5, quat( m ) )
	bottom:setUserData( "bottom" )
	collider:addShape( bottom )

	local back = lovr.physics.newBoxShape( 2.2, 2.2, thickness )
	back:setOffset( 0, 1.1, half_thickness )
	back:setUserData( "back" )
	collider:addShape( back )

	local front = lovr.physics.newBoxShape( 2.2, 2.2, thickness )
	front:setOffset( 0, 1.1, -10 - half_thickness )
	front:setUserData( "front" )
	collider:addShape( front )
end

function util.generate_level()
	-- NOTE: Cleanup state here
	bricks = {}
	balls = {}
	local ball = gameobject( vec3( -0.8, 2, -1 ), ASSET_TYPE.BALL )
	table.insert( balls, ball )

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
end

return util
