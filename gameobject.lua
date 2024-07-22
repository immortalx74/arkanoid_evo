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
		obj.direction = lovr.math.newVec3( 0.4, -0.2, -1 )
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
	end

	table.insert( gameobjects_list, obj )

	return obj
end

function gameobject:update( dt )
	if self.type == ASSET_TYPE.BALL then
		if aaa then
			local n = vec3( 0, 0, -1 ):normalize()
			local d = self.direction:dot( n )
			local reflected = self.direction:sub( n:mul( 2 * d ) )
			self.direction:set( reflected )
			aaa = false
		end
		local v = vec3( self.direction * self.velocity * dt )
		self.pose:translate( v )
		self.collider:setPosition( vec3( self.pose ) )
		local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( self.collider:getShapes()[ 1 ], vec3( self.pose ), quat( self.pose ), "brick wall" )

		if collider then
			if collider:getTag() == "brick" then
				local o = collider:getUserData()
				o:destroy()

				-- TODO: Currently reflecting from front of brick only.
				-- Need to determine which side of brick was hit
				self.direction:set( util.reflection_vector( vec3( 0, 0, -1 ), self.direction ) )
			elseif collider:getTag() == "wall" then
				local n
				if shape:getUserData() == "right" then
					n = vec3( -1, 0, 0 ):normalize()
				elseif shape:getUserData() == "left" then
					n = vec3( 1, 0, 0 ):normalize()
				elseif shape:getUserData() == "top" then
					n = vec3( 0, -1, 0 ):normalize()
				elseif shape:getUserData() == "bottom" then
					n = vec3( 0, 1, 0 ):normalize()
				end

				if n then
					self.direction:set( util.reflection_vector( n, self.direction ) )
				end
			end
		end
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
