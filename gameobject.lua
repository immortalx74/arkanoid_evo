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
		obj.velocity = 2.8 / METRICS.SUBSTEPS
		obj.direction = lovr.math.newVec3( 0.5, -0.2, -1 )
		obj.collider = world:newSphereCollider( lovr.math.newVec3( obj.pose ), METRICS.BALL_RADIUS )
		obj.collider:setTag( "ball" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.BRICK or type == ASSET_TYPE.BRICK_GOLD or type == ASSET_TYPE.BRICK_SILVER then
		obj.collider = world:newBoxCollider( lovr.math.newVec3( obj.pose ), vec3( METRICS.BRICK_WIDTH, METRICS.BRICK_HEIGHT, METRICS.BRICK_DEPTH ) )
		obj.collider:setTag( "brick" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
		if type == ASSET_TYPE.BRICK then
			obj.strength = 1
		elseif type == ASSET_TYPE.BRICK_SILVER then
			obj.strength = 2
		else
			obj.strength = -1
		end
	elseif type == ASSET_TYPE.ROOM then
		util.setup_room_colliders()
		for i, v in ipairs( room_colliders ) do
			v:setUserData( obj )
			v:setSensor( true )
		end
	elseif type == ASSET_TYPE.PADDLE then
		local length = METRICS.PADDLE_COLLIDER_THICKNESS
		obj.collider = world:newCylinderCollider( 0, 0, 0, METRICS.PADDLE_RADIUS, length )
		obj.collider:getShapes()[ 1 ]:setOffset( 0, length / 2, 0, math.pi / 2, 1, 0, 0 )
		obj.collider:setTag( "paddle" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.PADDLE_BIG then
		local length = METRICS.PADDLE_COLLIDER_THICKNESS
		obj.collider = world:newCylinderCollider( 0, 0, 0, METRICS.PADDLE_BIG_RADIUS, length )
		obj.collider:getShapes()[ 1 ]:setOffset( 0, length / 2, 0, math.pi / 2, 1, 0, 0 )
		obj.collider:setTag( "paddle" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.PADDLE_LASER then
		local length = METRICS.PADDLE_COLLIDER_THICKNESS
		obj.collider = world:newCylinderCollider( 0, 0, 0, METRICS.PADDLE_RADIUS, length )
		obj.collider:getShapes()[ 1 ]:setOffset( 0, length / 2, 0, math.pi / 2, 1, 0, 0 )
		obj.collider:setTag( "paddle" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type >= ASSET_TYPE.POWERUP_B and type <= ASSET_TYPE.POWERUP_S then
		obj.collider = world:newCylinderCollider( lovr.math.newVec3( obj.pose ), METRICS.POWERUP_RADIUS, METRICS.POWERUP_LENGTH )
		obj.collider:setOrientation( math.pi / 2, 0, 1, 0 )
		obj.collider:setTag( "powerup" )
		obj.collider:setUserData( obj )
	end

	table.insert( gameobjects_list, obj )
	table.sort( gameobjects_list, function( a, b ) -- sort by transparency...
		return b.transparent and not a.transparent
	end )
	return obj
end

function gameobject:update( dt )
	if lovr.headset.wasPressed( player.hand, "trigger" ) then
		balls[ 1 ].pose:set( vec3( 0, 1.5, -2 ) )
		balls[ 1 ].direction:set( 0.5, -0.1, -1 )
		balls[ 1 ].collider:setPosition( vec3( balls[ 1 ].pose ) )
	end

	if self.type == ASSET_TYPE.BALL then
		for i = 1, METRICS.SUBSTEPS do
			-- paddle substep first (src, dst, stp = source, destination, current-step)
			local x, y, z, angle, ax, ay, az = lovr.headset.getPose( player.hand )
			local v_src = vec3( obj_paddle.pose )
			local q_src = quat( obj_paddle.pose )
			local v_dst = vec3( x, y, z )
			local q_dst = quat( angle, ax, ay, az )
			local n = (i - 1) / (METRICS.SUBSTEPS - 1) -- normalized
			local v_stp = v_src:lerp( v_dst, n )
			local q_stp = q_src:slerp( q_dst, n )

			obj_paddle.pose:set( vec3( v_stp ), quat( q_stp ) )
			obj_paddle_top.pose:set( vec3( v_stp ), quat( q_stp ) )
			obj_paddle_spinner.pose:set( vec3( v_stp ), quat( q_stp ) )
			obj_paddle.collider:setPose( vec3( v_stp ), quat( q_stp ) )

			local v = vec3( self.direction * self.velocity * dt )
			self.pose:translate( v )
			self.collider:setPosition( vec3( self.pose ) )

			util.brick_collision( self )
			util.wall_collision( self )
			local hit = util.paddle_collision( self )
			if hit then
				obj_paddle.pose:set( vec3( v_dst ), quat( q_dst ) )
				obj_paddle_top.pose:set( vec3( v_dst ), quat( q_dst ) )
				obj_paddle_spinner.pose:set( vec3( v_dst ), quat( q_dst ) )
				obj_paddle.collider:setPose( vec3( v_dst ), quat( q_dst ) )
				break
			end
		end
	elseif self.type >= ASSET_TYPE.POWERUP_B and self.type <= ASSET_TYPE.POWERUP_S then
		if vec3( self.pose ).z < 0 then
			local hit = util.powerup_collision( self )
			if hit then
				local o = self.collider:getUserData()
				powerup.owned = o.type
				if powerup.owned == ASSET_TYPE.POWERUP_E then
					obj_paddle:destroy()
					obj_paddle = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_BIG )
					obj_paddle_top:destroy()
					obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP_BIG, true )
					obj_paddle_spinner:destroy()
					obj_paddle_spinner = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_SPINNER_BIG )
				elseif powerup.owned == ASSET_TYPE.POWERUP_L then
					obj_paddle:destroy()
					obj_paddle = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_LASER )
					obj_paddle_top:destroy()
					obj_paddle_top = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_TOP, true )
					obj_paddle_spinner:destroy()
					obj_paddle_spinner = gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.PADDLE_SPINNER )
					-- NOTE: add case to turn to normal again
				end
				o:destroy()
			else
				self.pose:translate( 0, 0, 0.8 * dt )
				self.collider:setPosition( vec3( self.pose ) )
			end
		else
			powerup.falling = nil
			local o = self.collider:getUserData()
			o:destroy()
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

	if self.type == ASSET_TYPE.PADDLE_SPINNER then
		self.model:animate( 1, lovr.timer.getTime() )
	elseif self.type >= ASSET_TYPE.POWERUP_B and self.type <= ASSET_TYPE.POWERUP_S then
		self.model:animate( 1, lovr.timer.getTime() )
	elseif self.type == ASSET_TYPE.PADDLE or self.type == ASSET_TYPE.PADDLE_BIG or self.type == ASSET_TYPE.PADDLE_LASER then
		local count = self.model:getAnimationCount()
		for i = 1, count do
			self.model:animate( i, lovr.timer.getTime() )
		end
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
