require "globals"

local gameobject = {}
package.loaded[ ... ] = gameobject

local util = require "util"
local assets = require "assets"
local powerup = require "powerup"
local collision = require "collision"

function gameobject:new( pose, type, transparent, color, points )
	local obj = {}
	setmetatable( obj, { __index = self } )

	obj.pose = lovr.math.newMat4( pose )
	obj.type = type
	obj.model = assets[ type ]
	obj.transparent = transparent or false
	obj.color = color or false

	if type == ASSET_TYPE.BALL then
		obj.stick = false
		obj.velocity = METRICS.BALL_SPEED_NORMAL / METRICS.SUBSTEPS
		local rand_x = math.random( -20, 20 ) * 0.1
		local rand_y = math.random( -20, 20 ) * 0.1
		local rand_y = math.random( -20, 20 ) * 0.1
		local rand_z = math.random( -20, -10 ) * 0.1
		obj.direction = lovr.math.newVec3( rand_x, rand_y, -1 ):normalize()
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
			obj.points = points
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
		obj.collider = world:newCylinderCollider( vec3( obj.pose ), METRICS.POWERUP_RADIUS, METRICS.POWERUP_LENGTH )
		obj.collider:setOrientation( math.pi / 2, 0, 1, 0 )
		obj.collider:setTag( "powerup" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.PROJECTILE then
		obj.collider = world:newCylinderCollider( vec3( obj.pose ), METRICS.PROJECTILE_RADIUS, METRICS.PROJECTILE_LENGTH )
		obj.collider:setTag( "projectile" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.EXIT_GATE then
		-- obj.collider = world:newCylinderCollider( vec3( obj.pose ), METRICS.EXIT_GATE_RADIUS, METRICS.ROOM_HEIGHT )
		-- obj.collider:getShapes()[ 1 ]:setOffset( 0, METRICS.ROOM_HEIGHT / 2, 0, -math.pi / 2, 1, 0, 0 )
		obj.collider = world:newCollider( vec3( obj.pose ) )
		local shape = lovr.physics.newCylinderShape( METRICS.EXIT_GATE_RADIUS, METRICS.ROOM_HEIGHT )
		shape:setOffset( 0, METRICS.ROOM_HEIGHT / 2, 0, math.pi / 2, 1, 0, 0 )
		obj.collider:addShape( shape )
		obj.collider:setTag( "exit_gate" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
	elseif type == ASSET_TYPE.DOH_COLLISION then
		obj.invisible = true
		obj.collider = world:newMeshCollider( assets[ ASSET_TYPE.DOH_COLLISION ] )
		obj.collider:setTag( "doh" )
		obj.collider:setUserData( obj )
		obj.collider:setSensor( true )
		obj.collider:getShapes()[ 1 ]:setOffset( vec3( obj.pose ) )
	end

	table.insert( gameobjects_list, obj )
	table.sort( gameobjects_list, util.sort_transparency )
	return obj
end

function gameobject:update( dt )
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

			-- Setting the paddle pose here to go hand-in-hand with ball substeps
			obj_paddle.pose:set( vec3( v_stp ), quat( q_stp ) )
			obj_paddle_top.pose:set( vec3( v_stp ), quat( q_stp ) )
			obj_paddle_spinner.pose:set( vec3( v_stp ), quat( q_stp ) )
			obj_paddle.collider:setPose( vec3( v_stp ), quat( q_stp ) )

			if not player.sticky_ball then
				local v = vec3( self.direction * self.velocity * dt )
				self.pose:translate( v )
				self.collider:setPosition( vec3( self.pose ) )
			else
				self.pose:set( obj_paddle.pose ):translate( 0, -0.04, 0 )
				self.collider:setPosition( vec3( self.pose ) )
			end

			collision.ball_to_brick( self )
			collision.ball_to_wall( self )
			if cur_level == 33 then
				collision.ball_to_doh( self )
			end
			local hit = collision.ball_to_paddle( self )
			if hit then
				if powerup.owned == ASSET_TYPE.POWERUP_C then
					player.sticky_ball = self
				end
				break
			end

			local x, y, z = self.pose:getPosition()
			if z > METRICS.ROOM_OFFSET_Z + 0.2 then
				self:destroy()
				return
			end
		end
	elseif self.type >= ASSET_TYPE.POWERUP_B and self.type <= ASSET_TYPE.POWERUP_S then
		if vec3( self.pose ).z < METRICS.ROOM_OFFSET_Z then
			local hit = collision.paddle_to_powerup( self )
			if hit then
				local o = self.collider:getUserData()
				powerup.acquire( o.type )
				o:destroy()
			else
				self.pose:translate( 0, 0, METRICS.POWERUP_SPEED * dt )
				self.collider:setPosition( vec3( self.pose ) )
			end
		else
			powerup.falling = nil
			local o = self.collider:getUserData()
			o:destroy()
		end
	elseif self.type == ASSET_TYPE.PROJECTILE then
		self.pose:translate( 0, 0, -METRICS.PROJECTILE_SPEED * dt )
		self.collider:setPosition( vec3( self.pose ) )
		local brick_collision, brick = collision.projectile_to_brick( self )

		if brick_collision then
			if brick.type == ASSET_TYPE.BRICK or brick.type == ASSET_TYPE.BRICK_SILVER then
				brick.strength = brick.strength - 1
			end

			if brick.strength == 0 then
				if brick.type == ASSET_TYPE.BRICK then -- Only colored bricks can spawn powerups and give points
					player.score = player.score + brick.points
					powerup.spawn( brick.pose )
				end
				brick:destroy()
			end
			self:destroy()
		else
			local wall_collision = collision.projectile_to_wall( self )
			if wall_collision then
				self:destroy()
			end
		end
	elseif self.type == ASSET_TYPE.EXIT_GATE and game_state == GAME_STATE.PLAY then
		local hit = collision.paddle_to_exit_gate( self )
		if hit then
			local num_levels = #levels
			if cur_level < num_levels then
				cur_level = cur_level + 1
				assets[ ASSET_TYPE.SND_ESCAPE_LEVEL ]:stop()
				assets[ ASSET_TYPE.SND_ESCAPE_LEVEL ]:play()
				game_state = GAME_STATE.EXIT_GATE
			else
				-- NOTE: Escape to Doh level
			end
		end
	end
end

function gameobject:draw( pass )
	if self.invisible then return end

	if self.transparent then
		pass:setShader( assets[ ASSET_TYPE.SHADER_UNLIT ] )
	else
		pass:setShader( assets[ ASSET_TYPE.SHADER_PBR ] )
	end

	if self.color then
		pass:setColor( self.color )
	end

	local animated_models =
		self.type == ASSET_TYPE.PADDLE_SPINNER or
		self.type == ASSET_TYPE.PADDLE_SPINNER_BIG or
		self.type == ASSET_TYPE.EXIT_GATE or
		self.type == ASSET_TYPE.ENEMY_BALOONS or
		self.type == ASSET_TYPE.ENEMY_CONE or
		self.type == ASSET_TYPE.ENEMY_PYRAMID or
		self.type >= ASSET_TYPE.POWERUP_B and self.type <= ASSET_TYPE.POWERUP_S

	if animated_models then
		if self.type >= ASSET_TYPE.ENEMY_BALOONS and self.type <= ASSET_TYPE.ENEMY_PYRAMID then
			if game_state == GAME_STATE.PLAY or game_state == GAME_STATE.LEVEL_INTRO then
				self.model:animate( 1, lovr.timer.getTime() )
			end
		else
			self.model:animate( 1, lovr.timer.getTime() )
		end
	elseif self.type == ASSET_TYPE.PADDLE or self.type == ASSET_TYPE.PADDLE_BIG or self.type == ASSET_TYPE.PADDLE_LASER then
		local count = self.model:getAnimationCount()
		for i = 1, count do
			self.model:animate( i, lovr.timer.getTime() )
		end
	elseif self.type == ASSET_TYPE.BALL then
		local v = vec3( self.pose )
		pass:circle( v.x, 0, v.z, 0.03, -math.pi / 2, 1, 0, 0 )
	elseif self.type == ASSET_TYPE.DOH then
		if player.doh_hit_timer:get_elapsed() < 0.1 then
			pass:setColor( 1, 0, 0 )
		else
			pass:setColor( 0.5, 0, 0 )
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

function gameobject.destroy_all()
	for i, v in ipairs( gameobjects_list ) do
		if v.collider then
			v.collider:destroy()
		end
	end

	gameobjects_list = {}
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
	__call = function( self, position, type, transparent, color, points )
		return self:new( position, type, transparent, color, points )
	end
} )

return gameobject
