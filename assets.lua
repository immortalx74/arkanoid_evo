require "globals"
local util = require "util"

local assets = {}

function assets.load()
	assets[ ASSET_TYPE.PADDLE ] = lovr.graphics.newModel( "devres/paddle.glb" )
	assets[ ASSET_TYPE.PADDLE_TOP ] = lovr.graphics.newModel( "devres/paddle_top.glb" )
	assets[ ASSET_TYPE.PADDLE_SPINNER ] = lovr.graphics.newModel( "devres/spinner.glb" )
	assets[ ASSET_TYPE.ROOM ] = lovr.graphics.newModel( "devres/room.glb" )
	assets[ ASSET_TYPE.ROOM_GLASS ] = lovr.graphics.newModel( "devres/glass.glb" )
	assets[ ASSET_TYPE.SHADER_PBR ] = lovr.graphics.newShader( "devres/shader_PBR.vs", "devres/shader_PBR.fs", { flags = { glow = true, normalMap = true, vertexTangents = false, tonemap = true } } )
	assets[ ASSET_TYPE.SKYBOX ] = lovr.graphics.newTexture( "devres/galaxy.png" )
	assets[ ASSET_TYPE.ENVIRONMENT_MAP ] = lovr.graphics.newTexture( 'devres/ibl.ktx' )
	assets[ ASSET_TYPE.BRICK ] = lovr.graphics.newModel( "devres/brick.glb" )
	assets[ ASSET_TYPE.BRICK_SILVER ] = lovr.graphics.newModel( "devres/brick_silver.glb" )
	assets[ ASSET_TYPE.BRICK_GOLD ] = lovr.graphics.newModel( "devres/brick_gold.glb" )
	assets[ ASSET_TYPE.BALL ] = lovr.graphics.newModel( "devres/ball.glb" )
	assets[ ASSET_TYPE.SPHERICAL_HARMONICS ] = lovr.graphics.newBuffer( { 'vec3', layout = 'std140' }, {
		{ 0.611764907836914,  0.599504590034485,  0.479980736970901 },
		{ 0.659514904022217,  0.665349841117859,  0.567680120468140 },
		{ 0.451633930206299,  0.450751245021820,  0.355226665735245 },
		{ -0.044383134692907, -0.053154513239861, -0.019974749535322 },
		{ -0.053045745939016, -0.057957146316767, -0.011247659102082 },
		{ 0.485697060823441,  0.490428507328033,  0.397530466318130 },
		{ -0.023690477013588, -0.024272611364722, -0.021886156871915 },
		{ -0.179465517401695, -0.181243389844894, -0.141314014792442 },
		{ -0.144527092576027, -0.143508568406105, -0.122757166624069 }
	} )
end

function assets.load_levels()
	local files = lovr.filesystem.getDirectoryItems( "res/levels" )

	for i, v in ipairs( files ) do
		local str = lovr.filesystem.read( "res/levels/" .. i .. ".csv" )
		table.insert( levels, util.split( str ) )
	end
end

return assets
