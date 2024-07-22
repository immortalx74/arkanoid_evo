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

	pass:box( 1.1 + half_thickness, 1.1, -5, 10, 2.2, thickness, math.pi / 2, 0, 1, 0 )

	pass:box( -1.1 - half_thickness, 1.1, -5, 10, 2.2, thickness, math.pi / 2, 0, 1, 0 )

	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	pass:box( 0, 2.2 + half_thickness, -5, 10, 2.2, thickness, quat( m ) )

	local m = mat4():rotate( math.pi / 2, 0, 1, 0 ):rotate( math.pi / 2, 1, 0, 0 )
	pass:box( 0, -half_thickness, -5, 10, 2.2, thickness, quat( m ) )
end

function util.reflection_vector( face_normal, direction )
	local n = face_normal:normalize()
	local d = direction:dot( n )

	return direction:sub( n:mul( 2 * d ) )
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
end

function util.generate_level()
	-- NOTE: Cleanup state here
	bricks = {}
	balls = {}
	local ball = gameobject( vec3( -0.8, 2, -1 ), ASSET_TYPE.BALL )

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
