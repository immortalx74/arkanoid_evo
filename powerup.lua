local timer = require "timer"
local gameobject = require "gameobject"
local util = require "util"
local assets = require "assets"

powerup = {}

powerup.timer = timer( false )
powerup.falling = nil
powerup.owned = nil
powerup.interval = 6

function powerup.spawn( brick_pose )
	local num_balls = util.get_num_balls()
	if powerup.timer:get_elapsed() > powerup.interval and num_balls == 1 then -- (multiple balls means we own POWERUP_D, so prevent spawning)
		local random_powerup = nil
		local first = ASSET_TYPE.POWERUP_B
		if player.gate_open then
			first = ASSET_TYPE.POWERUP_C -- prevent a 2nd "B" powerup
		end
		while true do
			random_powerup = math.random( first, ASSET_TYPE.POWERUP_S )
			if random_powerup ~= powerup.falling and random_powerup ~= powerup.owned then
				break
			end
		end

		-- Spawn near the front of the brick
		local v = mat4( brick_pose ):translate( 0, 0, (METRICS.BRICK_DEPTH / 2) - METRICS.POWERUP_RADIUS )
		gameobject( vec3( v ), random_powerup )
		-- gameobject( vec3( v ), ASSET_TYPE.POWERUP_B )
		powerup.timer:start()
		powerup.falling = random_powerup
	end
end

function powerup.acquire( pu_type )
	local prev_owned = powerup.owned
	powerup.owned = pu_type

	if player.sticky_ball then
		util.release_sticky_ball()
	end

	if prev_owned == ASSET_TYPE.POWERUP_S and powerup.owned ~= ASSET_TYPE.POWERUP_S then
		util.set_ball_speed( METRICS.BALL_SPEED_NORMAL )
	end

	if pu_type == ASSET_TYPE.POWERUP_E then
		util.spawn_paddle( ASSET_TYPE.PADDLE_BIG )
		assets[ ASSET_TYPE.SND_PADDLE_TURN_BIG ]:stop()
		assets[ ASSET_TYPE.SND_PADDLE_TURN_BIG ]:play()
	elseif pu_type == ASSET_TYPE.POWERUP_L then
		util.spawn_paddle( ASSET_TYPE.PADDLE_LASER )
	elseif pu_type == ASSET_TYPE.POWERUP_P then
		if player.lives < 5 then
			player.lives = player.lives + 1
		end
		if prev_owned == ASSET_TYPE.POWERUP_E or prev_owned == ASSET_TYPE.POWERUP_L then
			util.spawn_paddle( ASSET_TYPE.PADDLE )
		end
		assets[ ASSET_TYPE.SND_GOT_LIFE ]:stop()
		assets[ ASSET_TYPE.SND_GOT_LIFE ]:play()
	elseif pu_type == ASSET_TYPE.POWERUP_C then
		util.spawn_paddle( ASSET_TYPE.PADDLE )
	elseif pu_type == ASSET_TYPE.POWERUP_B then
		local x, y, z = lovr.headset.getPosition( player.hand )
		local zone_size = METRICS.ROOM_WIDTH / 3
		local spawn_x = 0
		if x <= -(zone_size / 2) or x >= (zone_size / 2) then
			spawn_x = -x
		else
			if x > 0 then
				spawn_x = -0.9
			else
				spawn_x = 0.9
			end
		end

		player.gate_open = true
		gameobject( vec3( spawn_x, 0, z ), ASSET_TYPE.EXIT_GATE, METRICS.TRANSPARENCY_IDX_EXIT_GATE )
		gameobject( vec3( spawn_x, 0, z ), ASSET_TYPE.EXIT_GATE_COLUMN, METRICS.TRANSPARENCY_IDX_EXIT_GATE_COLUMN )
	elseif pu_type == ASSET_TYPE.POWERUP_D then
		util.spawn_paddle( ASSET_TYPE.PADDLE )
		gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.BALL )
		gameobject( vec3( 0, 0, 0 ), ASSET_TYPE.BALL )
	elseif pu_type == ASSET_TYPE.POWERUP_S then
		util.set_ball_speed( METRICS.BALL_SPEED_SLOW )
	end
end

return powerup
