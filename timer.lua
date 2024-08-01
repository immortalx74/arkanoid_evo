local timer = {}

function timer:new( auto_start )
	local obj = {}
	setmetatable( obj, { __index = self } )
	obj.start_time = auto_start and lovr.timer.getTime() or 0
	obj.started = auto_start or false
	return obj
end

function timer:start()
	self.start_time = lovr.timer.getTime()
	self.started = true
end

function timer.stop()
	self.start_time = 0
	self.started = false
end

function timer:get_elapsed()
	return self.started and lovr.timer.getTime() - self.start_time or 0
end

setmetatable( timer, {
	__call = function( self, auto_start )
		return self:new( auto_start )
	end
} )

return timer
