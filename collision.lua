require "globals"
local assets = require "assets"
local util = require "util"

local collision = {}
function collision.ball_to_powerup( cur_powerup )
	local collider, shape, x, y, z, nx, ny, nz = world:overlapShape( cur_powerup.collider:getShapes()[ 1 ], vec3( cur_powerup.pose ), quat( cur_powerup.pose ), "paddle" )
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
