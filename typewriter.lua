local assets = require "assets"
local timer = require "timer"

local typewriter = {}

function typewriter:new( text, position, interval, auto_start )
	local obj = {}
	setmetatable( obj, { __index = self } )

	obj.text = text
	obj.text_writer = ""
	obj.position = lovr.math.newVec3( position )
	obj.interval = interval
	obj.cursor = 1
	obj.started = auto_start or false
	obj.timer = timer( auto_start)
	obj.finished = false
	return obj
end

function typewriter:start()
	self.started = true
	self.timer:start()
end

function typewriter:has_finished()
	return self.finished
end

function typewriter:draw( pass )
	if self.started then
		local char_count = #self.text_writer
		local char_width = (assets[ ASSET_TYPE.FONT ]:getWidth( "W" )) * METRICS.TEXT_SCALE_BIG
		local half = (char_count * char_width) / 2
		pass:text( self.text_writer, self.position.x + half, self.position.y, self.position.z, METRICS.TEXT_SCALE_BIG )

		if not self.finished and self.timer:get_elapsed() > self.interval then
			self.text_writer = string.sub( self.text, 1, self.cursor )
			self.cursor = self.cursor + 1
			self.timer:start()
		end

		if self.cursor > #self.text then
			self.finished = true
		end
	end
end

setmetatable( typewriter, {
	__call = function( self, text, position, timer, interval, auto_start )
		return self:new( text, position, timer, interval, auto_start )
	end
} )

return typewriter
