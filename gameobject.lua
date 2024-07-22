require "globals"

local gameobject = {}
package.loaded[ ... ] = gameobject

local util = require "util"
local assets = require "assets"

function gameobject:new( pose, type, transparent, color )
	local obj = {}
	setmetatable( obj, { __index = self } )

	obj.pose = lovr.math.newMat4( pose )
	obj.type = type
	obj.model = assets[ type ]
	obj.transparent = transparent or false
	obj.color = color or false
	if type == ASSET_TYPE.BALL then
		obj.velocity = 0.8
		obj.direction = lovr.math.newVec3( 0.5, -0.2, -1 )
		obj.collider = world:newSphereCollider( lovr.math.newVec3( obj.pose ), 0.03 )
		obj.collider:setTag( "ball" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.BRICK or type == ASSET_TYPE.BRICK_GOLD or type == ASSET_TYPE.BRICK_SILVER then
		obj.collider = world:newBoxCollider( lovr.math.newVec3( obj.pose ), vec3( 0.162, 0.084, 0.084 ) )
		obj.collider:setTag( "brick" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.ROOM then
		obj.collider = world:newCollider( 0, 0, 0 )
		util.setup_room_collider_shapes( obj.collider )
		obj.collider:setTag( "wall" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.PADDLE then
		local length = 0.2
		local half_length = length / 2
		obj.collider = world:newCylinderCollider( 0, 0, 0, 0.14, length )
		obj.collider:getShapes()[ 1 ]:setOffset( 0, length / 2, 0, math.pi / 2, 1, 0, 0 )
		obj.collider:setTag( "paddle" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	end

	table.insert( gameobjects_list, obj )

	return obj
end

function gameobject:update( dt )
	if self.type == ASSET_TYPE.BALL then
		-- if aaa then
		-- 	local n = vec3( 0, 0, -1 )
		-- 	local d = self.direction:dot( n )
		-- 	local reflected = self.direction:sub( n:mul( 2 * d ) )
		-- 	self.direction:set( reflected )
		-- 	aaa = false
		-- end

		local v = vec3( self.direction * self.velocity * dt )
		self.pose:translate( v )
		self.collider:setPosition( vec3( self.pose ) )

		util.brick_collision( self )
		util.wall_collision( self )
	elseif self.type == ASSET_TYPE.PADDLE then
		local x, y, z, angle, ax, ay, az = lovr.headset.getPose( "right" )
		obj_paddle.pose:set( vec3( x, y, z ), quat( angle, ax, ay, az ) )
		obj_paddle_top.pose:set( vec3( x, y, z ), quat( angle, ax, ay, az ) )
		obj_paddle.collider:setPose( vec3( x, y, z ), quat( angle, ax, ay, az ) )
	end
end

function gameobject:draw( pass )
	if self.transparent then
		pass:setShader()
	else
		pass:setShader( assets[ ASSET_TYPE.SHADER_PBR ] )
	end

	if self.color then
		pass:setColor( self.color )
	end

	pass:draw( self.model, self.pose )
	pass:setColor( 1, 1, 1 )
end

function gameobject:destroy()
	for i, v in ipairs( gameobjects_list ) do
		if v == self then
			if v.collider then
				v.collider:destroy()
			end
			table.remove( gameobjects_list, i )
			break
		end
	end
end

function gameobject.update_all( dt )
	for i, obj in ipairs( gameobjects_list ) do
		obj:update( dt )
	end
end

function gameobject.draw_all( pass )
	for i, obj in ipairs( gameobjects_list ) do
		obj:draw( pass )
	end
end

setmetatable( gameobject, {
	__call = function( self, position, type, transparent, color )
		return self:new( position, type, transparent, color )
	end
} )

return gameobject
