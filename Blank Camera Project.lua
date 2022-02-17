--[[
	A blank project with support for rendering things.
--]]

if true then	
	-- The FOV and and border variables are specific
	-- to Spyro the Dragon. If you want to make this code
	-- work with any other game, you'll need to figure out
	-- the appropriate values for that game. I originally
	-- found the FOV values by rendering lines over level
	-- geometry at known coordinates, then adjusting the
	-- FOV values until the rendered lines matched
	-- the level geometry. You'll also need to
	-- update getCameraValues() to get the camera position
	-- and orientation from the game's memory.
	FOVx = 1.22
	FOVy = 1.78

	screen_width = 560
	screen_height = 240

	border_left = 24
	border_right = screen_width - 25
	border_top = 8
	border_bottom = screen_height - 9

	nearClip = 500
	
	screen_halfWidth = screen_width / 2
	screen_halfHeight = screen_height / 2
	
	if cameraX == nil then
		cameraX = 0
		cameraX_buffer = {}
		cameraY = 0
		cameraY_buffer = {}
		cameraZ = 0
		cameraZ_buffer = {}
		
		cameraYaw = 0
		cameraYaw_buffer = {}

		cameraPitch = 0
		cameraPitch_buffer = {}

		bufferLength = 3
		bufferIndex = 0
	end
	
	function worldSpaceToScreenSpace(x, y, z)
		local relativeX = x - cameraX
		local relativeY = y - cameraY
		
		local rotatedX = math.cos(-cameraYaw) * relativeX - math.sin(-cameraYaw) * relativeY
		local rotatedZ = z - cameraZ

		local pitchedX = math.cos(cameraPitch) * rotatedX - math.sin(cameraPitch) * rotatedZ
		local pitchedY = math.sin(-cameraYaw) * relativeX + math.cos(-cameraYaw) * relativeY
		local pitchedZ = math.sin(cameraPitch) * rotatedX + math.cos(cameraPitch) * rotatedZ
		
		if pitchedX < nearClip then
			return nil
		end
		
		--viewport should range from -1 to 1
		local viewportX = (pitchedY / pitchedX) * FOVx
		local viewportY  = (pitchedZ / pitchedX) * FOVy
		
		--screen should vary from 0 to width/height (560/240)
		local screenX = (viewportX * -screen_halfWidth) + screen_halfWidth
		local screenY = (viewportY * -screen_halfHeight) + screen_halfHeight
		
		return screenX, screenY
	end

	function drawDiamond (x, y, z, s)
		if type(s) ~= "number" then s = 200 end
		
		if (cameraX - x) * (cameraX - x) + (cameraY - y) * (cameraY - y) + (cameraZ - z) * (cameraZ - z) > 1600000000 then
			drawCrosshair(x, y, z, s)
			return
		end
		
		drawLine_world(x - s, y, z, x, y - s, z)
		drawLine_world(x, y - s, z, x + s, y, z)
		drawLine_world(x + s, y, z, x, y + s, z)
		drawLine_world(x, y + s, z, x - s, y, z)
		
		drawLine_world(x - s, y, z, x, y, z + s)
		drawLine_world(x + s, y, z, x, y, z + s)
		drawLine_world(x, y - s, z, x, y, z + s)
		drawLine_world(x, y + s, z, x, y, z + s)
		
		drawLine_world(x - s, y, z, x, y, z - s)
		drawLine_world(x + s, y, z, x, y, z - s)
		drawLine_world(x, y - s, z, x, y, z - s)
		drawLine_world(x, y + s, z, x, y, z - s)
	end
	
	function drawCrosshair (x, y, z, s)
		if type(s) ~= "number" then s = 200 end
		drawLine_world(x - s, y, z, x + s, y, z)
		drawLine_world(x, y - s, z, x, y + s, z)
		drawLine_world(x, y, z - s, x, y, z + s)
	end

	function drawLine_worldVector (v1, v2)
		-- Example: drawLine_worldVector({1, 2, 3}, {4, 5, 6})
		-- This should only be used if your coordinates are already in vector form.
		drawLine_world (v1[1], v1[2], v1[3], v2[1], v2[2], v2[3])
	end

	function drawLine_world (x1, y1, z1, x2, y2, z2)
		local scp = cameraPitch_sin
		local ccp = cameraPitch_cos
		local scy = cameraYaw_sin
		local ccy = cameraYaw_cos
	
		local relativeX1 = x1 - cameraX
		local relativeY1 = y1 - cameraY
		local relativeX2 = x2 - cameraX
		local relativeY2 = y2 - cameraY
		
		local rotatedX1 = ccy * relativeX1 - scy * relativeY1
		local rotatedZ1 = z1 - cameraZ
		local rotatedX2 = ccy * relativeX2 - scy * relativeY2
		local rotatedZ2 = z2 - cameraZ
		
		local pitchedX1 = ccp * rotatedX1 - scp * rotatedZ1
		local pitchedX2 = ccp * rotatedX2 - scp * rotatedZ2

		local pitchedY1 = scy * relativeX1 + ccy * relativeY1
		local pitchedZ1 = scp * rotatedX1 + ccp * rotatedZ1
		local pitchedY2 = scy * relativeX2 + ccy * relativeY2
		local pitchedZ2 = scp * rotatedX2 + ccp * rotatedZ2
		
		if pitchedX1 < nearClip then
			if pitchedX2 < nearClip then
				return
			end
			pitchedY1 = pitchedY1 + (pitchedY2-pitchedY1)/(pitchedX2-pitchedX1)*(nearClip-pitchedX1)
			pitchedZ1 = pitchedZ1 + (pitchedZ2-pitchedZ1)/(pitchedX2-pitchedX1)*(nearClip-pitchedX1)
			pitchedX1 = nearClip
		end
		
		if pitchedX2 < nearClip then
			pitchedY2 = pitchedY2 + (pitchedY1-pitchedY2)/(pitchedX1-pitchedX2)*(nearClip-pitchedX2)
			pitchedZ2 = pitchedZ2 + (pitchedZ1-pitchedZ2)/(pitchedX1-pitchedX2)*(nearClip-pitchedX2)
			pitchedX2 = nearClip
		end
		
		drawLine_screen(
			screen_halfWidth * (((pitchedY1 / pitchedX1) * -FOVx) + 1),
			screen_halfHeight * (((pitchedZ1 / pitchedX1) * -FOVy) + 1),
			screen_halfWidth * (((pitchedY2 / pitchedX2) * -FOVx) + 1),
			screen_halfHeight * (((pitchedZ2 / pitchedX2) * -FOVy) + 1)
		)	
		
	end
	
	function drawLine_screen (x1, y1, x2, y2)
		if x1 == 0 or x2 == 0 then return end
		
		if math.abs(x1-x2) > 2 then
			if x1 < border_left then
				if x2 < border_left then return end
				y1 = y1 - ((y2-y1)/(x2-x1))*(x1-border_left)
				x1 = border_left
			elseif x2 < border_left then
				y2 = y1 - ((y2-y1)/(x2-x1))*(x1-border_left)
				x2 = border_left
			end
			if x1 > border_right then
				if x2 > border_right then return end
				y1 = y1 - ((y2-y1)/(x2-x1))*(x1-border_right)
				x1 = border_right
			elseif x2 > border_right then
				y2 = y1 - ((y2-y1)/(x2-x1))*(x1-border_right)
				x2 = border_right
			end
		else
			if x1 < border_left or x1 > border_right or x2 < border_left or x2 > border_right then return end
		end
		
		if math.abs(y1-y2) > 2 then
			local intercept_top = x1 - ((x2-x1)/(y2-y1))*(y1-border_top)
			local intercept_bottom = x1 - ((x2-x1)/(y2-y1))*(y1-border_bottom)
			if y1 < border_top then
				if y2 < border_top then return end
				x1 = x1 - ((x2-x1)/(y2-y1))*(y1-border_top)
				y1 = border_top
			elseif y2 < border_top then
				x2 = x1 - ((x2-x1)/(y2-y1))*(y1-border_top)
				y2 = border_top
			end
			if y1 > border_bottom then
				if y2 > border_bottom then return end
				x1 = x1 - ((x2-x1)/(y2-y1))*(y1-border_bottom)
				y1 = border_bottom
			elseif y2 > border_bottom then
				x2 = x1 - ((x2-x1)/(y2-y1))*(y1-border_bottom)
				y2 = border_bottom
			end
		else
			if y1 < border_top or y1 > border_bottom or y2 < border_top or y2 > border_bottom then return end
		end
		
		gui.drawLine(x1, y1, x2, y2, drawColor)
	end

	-- The unoptimized functions are what these functions
	-- looked like before I optimized them. They should not
	-- be used, but if changes must be made to the
	-- rendering system, these are probably easier to read
	-- and update.
	function drawLine_world_unoptimized (x1, y1, z1, x2, y2, z2)
		local relativeX1 = x1 - cameraX
		local relativeY1 = y1 - cameraY
		local relativeX2 = x2 - cameraX
		local relativeY2 = y2 - cameraY
		
		local rotatedX1 = math.cos(-cameraYaw) * relativeX1 - math.sin(-cameraYaw) * relativeY1
		local rotatedZ1 = z1 - cameraZ
		local rotatedX2 = math.cos(-cameraYaw) * relativeX2 - math.sin(-cameraYaw) * relativeY2
		local rotatedZ2 = z2 - cameraZ

		local pitchedX1 = math.cos(cameraPitch) * rotatedX1 - math.sin(cameraPitch) * rotatedZ1
		local pitchedY1 = math.sin(-cameraYaw) * relativeX1 + math.cos(-cameraYaw) * relativeY1
		local pitchedZ1 = math.sin(cameraPitch) * rotatedX1 + math.cos(cameraPitch) * rotatedZ1
		local pitchedX2 = math.cos(cameraPitch) * rotatedX2 - math.sin(cameraPitch) * rotatedZ2
		local pitchedY2 = math.sin(-cameraYaw) * relativeX2 + math.cos(-cameraYaw) * relativeY2
		local pitchedZ2 = math.sin(cameraPitch) * rotatedX2 + math.cos(cameraPitch) * rotatedZ2
		
		local oneBehindCamera = false
		
		if pitchedX1 < nearClip then
			pitchedY1 = pitchedY1 + (((pitchedY2)-(pitchedY1))/(pitchedX2-pitchedX1))*(nearClip-pitchedX1)
			pitchedZ1 = pitchedZ1 + (((pitchedZ2)-(pitchedZ1))/(pitchedX2-pitchedX1))*(nearClip-pitchedX1)
			pitchedX1 = nearClip
			oneBehindCamera = true
		end
		
		if pitchedX2 < nearClip then
			if oneBehindCamera then return end
			pitchedY2 = pitchedY2 + (((pitchedY1)-(pitchedY2))/(pitchedX1-pitchedX2))*(nearClip-pitchedX2)
			pitchedZ2 = pitchedZ2 + (((pitchedZ1)-(pitchedZ2))/(pitchedX1-pitchedX2))*(nearClip-pitchedX2)
			pitchedX2 = nearClip
		end
		
		--viewport should range from -1 to 1
		local viewportX1 = (pitchedY1 / pitchedX1) * FOVx
		local viewportY1  = (pitchedZ1 / pitchedX1) * FOVy
		local viewportX2 = (pitchedY2 / pitchedX2) * FOVx
		local viewportY2  = (pitchedZ2 / pitchedX2)*FOVy
		
		--screen should vary from 0 to width/height (560/240)
		local screenX1 = (viewportX1 * -screen_halfWidth) + screen_halfWidth
		local screenY1 = (viewportY1 * -screen_halfHeight) + screen_halfHeight
		local screenX2 = (viewportX2 * -screen_halfWidth) + screen_halfWidth
		local screenY2 = (viewportY2 * -screen_halfHeight) + screen_halfHeight
		
		drawLine_screen(screenX1, screenY1, screenX2, screenY2)	
		
	end

	function drawLine_screen_unoptimized (x1, y1, x2, y2)
		if x1 == 0 or x2 == 0 then return end
		
		local sameSide = false
		if math.abs(x1-x2) > 0.5 then
			local intercept_left = y1 - ((y2-y1)/((x2-border_left)-(x1-border_left)))*(x1-border_left)
			local intercept_right = y1 - ((y2-y1)/((x2-border_right)-(x1-border_right)))*(x1-border_right)
			if x1 < border_left then
				x1 = border_left
				y1 = intercept_left
				sameSide = true
			end
			if x2 < border_left then
				x2 = border_left
				y2 = intercept_left
				if sameSide then return end
			end
			sameSide = false
			if x1 > border_right then
				x1 = border_right
				y1 = intercept_right
				sameSide = true
			end
			if x2 > border_right then
				if sameSide then return end
				x2 = border_right
				y2 = intercept_right
			end
		else
			if x1 < border_left or x1 > border_right or x2 < border_left or x2 > border_right then return end
		end
		
		if math.abs(y1-y2) > 0.5 then
			local intercept_top = x1 - ((x2-x1)/((y2-border_top)-(y1-border_top)))*(y1-border_top)
			local intercept_bottom = x1 - ((x2-x1)/((y2-border_bottom)-(y1-border_bottom)))*(y1-border_bottom)
			sameSide = false
			if y1 < border_top then
				y1 = border_top
				x1 = intercept_top
				sameSide = true
			end
			if y2 < border_top then
				y2 = border_top
				x2 = intercept_top
				if sameSide then return end
			end
			sameSide = false
			if y1 > border_bottom then
				y1 = border_bottom
				x1 = intercept_bottom
				sameSide = true
			end
			if y2 > border_bottom then
				if sameSide then return end
				y2 = border_bottom
				x2 = intercept_bottom
			end
		else
			if y1 < border_top or y1 > border_bottom or y2 < border_top or y2 > border_bottom then return end
		end
		
		gui.drawLine(x1, y1, x2, y2, drawColor)
	end
	
	function getCameraValues()
		--Handle rolling the buffer
		for i=bufferLength,2,-1 do
			cameraX_buffer[i] = cameraX_buffer[i - 1]
			cameraY_buffer[i] = cameraY_buffer[i - 1]
			cameraZ_buffer[i] = cameraZ_buffer[i - 1]
			cameraYaw_buffer[i] = cameraYaw_buffer[i - 1]
			cameraPitch_buffer[i] = cameraPitch_buffer[i - 1]
		end

		--Get camera position
		cameraX_buffer[1] = memory.read_u32_le(0x076DF8)
		cameraY_buffer[1] = memory.read_u32_le(0x076DFC)
		cameraZ_buffer[1] = memory.read_u32_le(0x076E00)
			
		--Get camera rotation
		cameraYaw_buffer[1] = math.atan2(memory.read_s16_le(0x076DD4), memory.read_s16_le(0x076DD0))
		
		cameraPitch_buffer[1] = math.asin(memory.read_s16_le(0x076DDE) / 4096)
		upsideDownDetector = memory.read_s16_le(0x076E1E)
		if upsideDownDetector > 1024 and upsideDownDetector < 2000 then
			cameraPitch_buffer[1] = math.pi - cameraPitch_buffer[1]
		end
		
		--Update camera variables
		bufferIndex = bufferIndex + 1
		if bufferIndex > bufferLength then
			bufferIndex = bufferLength
		end
		
		cameraX = cameraX_buffer[bufferIndex]
		cameraY = cameraY_buffer[bufferIndex]
		cameraZ = cameraZ_buffer[bufferIndex]
		cameraYaw = cameraYaw_buffer[bufferIndex]
		cameraPitch = cameraPitch_buffer[bufferIndex]
		
		cameraPitch_sin = math.sin(cameraPitch)
		cameraPitch_cos = math.cos(cameraPitch)
		cameraYaw_sin = math.sin(-cameraYaw)
		cameraYaw_cos = math.cos(-cameraYaw)
	end
end

scriptRestart = true
getCameraValues()

while true do
	local doRender = scriptRestart
	scriptRestart = false
	
	-- This is reading the lag counter in Spyro the Dragon to know when to render a new frame.
	if memory.read_u32_le(0x075760) % 2 == 0 and lastCameraUpdate ~= emu.framecount() then
		lastCameraUpdate = emu.framecount()
		getCameraValues()
		doRender = true
	end
	
	if doRender then
		gui.clearGraphics()	

		-- Draw things here
		
		--For Example: (This should draw something near Sunny Flight in the Artisan Homeworld)
		drawLine_world(76864, 50240, 6912, 77312, 49152, 6912)
		drawLine_world(77312, 49152, 6912, 76864, 48064, 6912)
		drawLine_world(76864, 48064, 6912, 75776, 47616, 6912)
		drawLine_world(75776, 47616, 6912, 74688, 48064, 6912)
		drawLine_world(74688, 48064, 6912, 74240, 49152, 6912)
		drawLine_world(74240, 49152, 6912, 74688, 50240, 6912)
		drawLine_world(74688, 50240, 6912, 75776, 50688, 6912)
		drawLine_world(75776, 50688, 6912, 76864, 50240, 6912)
		drawLine_world(76864, 50240, 6912, 75776, 49152, 8992)
		drawLine_world(77312, 49152, 6912, 75776, 49152, 8992)
		drawLine_world(76864, 48064, 6912, 75776, 49152, 8992)
		drawLine_world(75776, 47616, 6912, 75776, 49152, 8992)
		drawLine_world(74688, 48064, 6912, 75776, 49152, 8992)
		drawLine_world(74240, 49152, 6912, 75776, 49152, 8992)
		drawLine_world(74688, 50240, 6912, 75776, 49152, 8992)
		drawLine_world(75776, 50688, 6912, 75776, 49152, 8992)
		drawDiamond(75776, 49152, 8992)
		
	end
	
	emu.yield()
end