require "globals"
local assets = require "assets"
local util = require "util"

local collision = {}
function collision.paddle_to_powerup( cur_powerup )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_powerup.collider:getShapes()[ 1 ], vec3( cur_powerup.pose ), quat( cur_powerup.pose ), "paddle" )
	if collider then
		if collider:getTag() == "paddle" then
			return true
		end
	end

	return false
end

function collision.paddle_to_exit_gate( cur_exit_gate )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_exit_gate.collider:getShapes()[ 1 ], vec3( cur_exit_gate.pose ), quat( cur_exit_gate.pose ), "paddle" )
	if collider then
		if collider:getTag() == "paddle" then
			return true
		end
	end

	return false
end

function collision.ball_to_brick( cur_ball )
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
					powerup.spawn( o.pose )
					o:destroy()
					assets[ ASSET_TYPE.SND_BALL_BRICK_DESTROY ]:stop()
					assets[ ASSET_TYPE.SND_BALL_BRICK_DESTROY ]:play()

					if o.type == ASSET_TYPE.BRICK then -- add to score
						player.score = player.score + o.points
					end
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

function collision.ball_to_wall( cur_ball )
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

function collision.ball_to_doh( cur_ball )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_ball.collider:getShapes()[ 1 ], vec3( cur_ball.pose ), quat( cur_ball.pose ), "doh" )

	local normal = nil

	if collider then
		if collider:getTag() == "doh" then
			for i, v in ipairs( doh_d ) do
				local A = v.triangle[ 1 ]
				local B = v.triangle[ 2 ]
				local C = v.triangle[ 3 ]
				local point = vec3( x, y, z )

				if util.point_in_triangle( A, B, C, point ) then
					normal = v.normal
					break
				end
			end

			if normal then
				cur_ball.pose:translate( -nx, -ny, -nz )
				-- NOTE: I don't even know why I have to do this! (reversing direction only on right side of model? )
				if x > 0 then
					cur_ball.direction:set( util.reflection_vector( -normal, -cur_ball.direction ) )
				else
					cur_ball.direction:set( util.reflection_vector( -normal, cur_ball.direction ) )
				end

				player.doh_hits = player.doh_hits + 1
				player.doh_hit_timer:start()
				assets[ ASSET_TYPE.SND_DOH_HIT ]:stop()
				assets[ ASSET_TYPE.SND_DOH_HIT ]:play()
				return true
			end
		end
	end

	return false
end

function collision.ball_to_paddle( cur_ball )
	if player.contacted then
		if player.paddle_cooldown_timer:get_elapsed() >= METRICS.PADDLE_COOLDOWN_INTERVAL then
			player.contacted = false
			player.paddle_cooldown_timer:stop()
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
				player.paddle_cooldown_timer:start()
				return true
			end
		end
	end

	return false
end

function collision.projectile_to_brick( cur_proj )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_proj.collider:getShapes()[ 1 ], vec3( cur_proj.pose ), quat( cur_proj.pose ), "brick" )

	if collider then
		if collider:getTag() == "brick" then
			return true, collider:getUserData()
		end
	end

	return false, nil
end

function collision.projectile_to_wall( cur_proj )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_proj.collider:getShapes()[ 1 ], vec3( cur_proj.pose ), quat( cur_proj.pose ),
		"wall_left wall_right wall_top wall_bottom wall_far wall_near" )

	if collider then
		return true
	end

	return false
end

return collision
