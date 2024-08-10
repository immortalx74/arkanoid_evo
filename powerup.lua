local timer = require "timer"
local gameobject = require "gameobject"
local util = require "util"

powerup = {}

powerup.timer = timer( false )
powerup.falling = nil
powerup.owned = nil
powerup.interval = 3

function powerup.spawn( brick_pose )
	if powerup.timer:get_elapsed() > powerup.interval then
		local random_powerup = nil
		while true do
			random_powerup = math.random( ASSET_TYPE.POWERUP_B, ASSET_TYPE.POWERUP_S )
			if random_powerup ~= powerup.falling and random_powerup ~= powerup.owned then break end
		end

		-- Spawn near the front of the brick
		local v = mat4( brick_pose ):translate( 0, 0, (METRICS.BRICK_DEPTH / 2) - METRICS.POWERUP_RADIUS )
		gameobject( vec3( v ), random_powerup )
		powerup.timer:start()
		powerup.falling = random_powerup
	end
end

function powerup.acquire( pu_type )
	powerup.owned = pu_type

	if pu_type == ASSET_TYPE.POWERUP_E then
		util.spawn_paddle( ASSET_TYPE.PADDLE_BIG )
	elseif pu_type == ASSET_TYPE.POWERUP_L then
		util.spawn_paddle( ASSET_TYPE.PADDLE_LASER )
	elseif pu_type == ASSET_TYPE.POWERUP_P then
		if player.lives < 5 then
			player.lives = player.lives + 1
		end
		if powerup.owned == ASSET_TYPE.POWERUP_E or powerup.owned == ASSET_TYPE.POWERUP_L then
			util.spawn_paddle( ASSET_TYPE.PADDLE )
		end
	end
end

return powerup
