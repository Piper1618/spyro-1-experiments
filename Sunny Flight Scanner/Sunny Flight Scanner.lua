-- For Spyro the Dragon.
-- This script draws a minimap of the area surrounding
-- the planes in Sunny Flight. It also shows the
-- locations of passing trains, planes, and Spyro. Spyro
-- is drawn with a circle surrounding him. Planes will
-- move if they are inside this circle or if the camera
-- is pointed at them.

-- Tested on USA and PAL versions of Spyro the Dragon.
-- Tested on BizHawk 2.7

-- Load map
if true then
	f = assert(io.open("Sunny Flight Map.obj", "r"))
	verts = {}
	Lines = {}
	local verts = verts
	local Lines = Lines
	local scale = 1000
		
	while true do
		local t = f:read()
		if t == nil then break end
		
		if bizstring.startswith(t, "v ") then
			local list = bizstring.split(t, " ")
			table.insert(verts, {math.floor(tonumber(list[2]) * scale), math.floor(tonumber(list[3]) * scale)})
			
		elseif bizstring.startswith(t, "l ") then
			list = bizstring.split(t, " ")
			local line = {tonumber(list[2]), tonumber(list[3])}
			table.insert(Lines, line)
		end
	end
end

-- Version stuff
if true then
	displayType = emu.getdisplaytype()
	
	memoryAddresses = {
		["NTSC"] = {
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 0,
			[5] = 0,
			pixelRatio = 0.5625,
		},
		["PAL"] = {
			[1] = 0x68C8,
			[2] = 0x68CC,
			[3] = 0x68D4,
			[4] = 0x6990,
			[5] = 0x68D0,
			pixelRatio = 0.6469,
		},
	}
	
	if displayType == "NTSC" then
		m = memoryAddresses["NTSC"]

		border_left = 24
		border_top = 8
	else
		m = memoryAddresses["PAL"]

		border_left = 24
		border_top = 15
	end
end

-- Script startup

scriptRestart = true

-- Main loop
while true do
	
	-- Render a new overlay frame when the script starts.
	-- After that, only do so when the game draws a new image.
	local doRender = scriptRestart
	scriptRestart = false
	
	if memory.read_u32_le(0x075760 + m[2]) % 2 == 0 and lastCameraUpdate ~= emu.framecount() then
		lastCameraUpdate = emu.framecount()
		doRender = true
	end
	
	-- Render a frame for the overlay
	if doRender then
		-- Clear out old graphics.
		gui.clearGraphics()
		
		-- Check we are in Sunny Flight
		if memory.read_u32_le(0x07596C + m[5]) == 15 and bit.band(2 ^ memory.read_u32_le(0x0757D8 + m[2]), 0x9D) > 0 then
			
			-- Functions to convert world coordinates into map coordinates
			local function convertX(x)
				-- return (x - map_xOrigin) / map_scale + (the location of the map origin on the screen)
				return (x - 32000) / 500 + border_left
			end
			local function convertY(y)
				-- y is subtracted from map_yOrigin to flip the map vertically.
				return (170000 - y) * m.pixelRatio / 500 + border_top + ((displayType == "NTSC") and 34 or 42)
			end
			
			-- Function to check if a position is within the map bounds
			local function isOnMap(x, y)
				return y > 70000 and y < 170000 and x > 32000 and x < ((y > 110000) and ((y < 155500) and 108000 or 98000) or 92000)
			end
			
			-- Draw a triangle at the x, y screen coordinates
			local function drawDart(x, y, direction, length, width, lineColor, backColor)
				-- direction is in radians
			
				local pointer = {{length, 0}, {-length * 2 / 3, width}, {-length * 2 / 3, -width}}
				local rotatedPointer = {}
				for i, v in ipairs(pointer) do
					table.insert(rotatedPointer, {
						math.cos(direction) * v[1] + math.sin(direction) * v[2],
						(math.cos(direction) * v[2] - math.sin(direction) * v[1]) * m.pixelRatio,
					})
				end
				gui.drawPolygon(rotatedPointer, x, y, 0, backColor)
				gui.drawPolygon(rotatedPointer, x, y, lineColor, 0)
			end
			
			-- Draw map
			for i, v in ipairs(Lines) do
				gui.drawLine(convertX(verts[v[1]][1]), convertY(verts[v[1]][2]), convertX(verts[v[2]][1]), convertY(verts[v[2]][2], 0xFF000000))
			end
			
			local regionOffset = (displayType == "NTSC") and 0x00 or 0x0994
			
			-- Spyro's coordinates
			local sx = memory.read_u32_le(0x078A58 + m[4])
			local sy = memory.read_u32_le(0x078A5C + m[4])
				
			-- Planes
			for i = 0, 7 do
				if memory.read_s8(0x1756D0 + regionOffset + i * 0x58 + 0x48) >= 0 and memory.read_u32_le(0x1756D0 + regionOffset + i * 0x58 + 0x18) == 0 then
					local px = memory.read_u32_le(0x1756D0 + regionOffset + i * 0x58 + 0x0C)
					local py = memory.read_u32_le(0x1756D0 + regionOffset + i * 0x58 + 0x10)

					local color = (memory.read_s8(0x1756D0 + regionOffset + i * 0x58 + 0x51) > 0 or (math.sqrt((px - sx) ^ 2 + (py - sy) ^ 2) < 0x4000)) and 0xFFFFFFFF or 0xFFFF0000
					drawDart(convertX(px), convertY(py), memory.read_u8(0x1756D0 + regionOffset + i * 0x58 + 0x46) * 2 * math.pi / 256, 8, 4, 0xFF000000, color)
				end
			end
			
			-- Trains
			for i = 11, 0, -1 do -- Counting backwards so the front of each train is drawn last.
				if memory.read_s8(0x175990 + regionOffset + i * 0x58 + 0x48) >= 0 and memory.read_u32_le(0x175990 + regionOffset + i * 0x58 + 0x18) == 0 then
					local tx = memory.read_u32_le(0x175990 + regionOffset + i * 0x58 + 0x0C)
					local ty = memory.read_u32_le(0x175990 + regionOffset + i * 0x58 + 0x10)
					if isOnMap(tx, ty) then
						gui.drawEllipse(convertX(tx)-3, convertY(ty)-2, 6, 4, 0xFF000000, (i % 3 == 0) and 0xFFA0A0A0 or 0xFFA04010)
					end
				end
			end
			
			-- Spyro
			if true then
				if isOnMap(sx, sy) then
					drawDart(convertX(sx), convertY(sy), memory.read_u8(0x078A66 + m[4]) * 2 * math.pi / 256, 5, 8, 0xFF300050, 0xFFB080E0)
					local r = 0x4000
					local x = convertX(sx-r)
					local y = convertY(sy-r)
					local w = convertX(sx+r)-x
					local h = convertY(sy+r)-y
					gui.drawEllipse(x, y, w, h, 0x80300050, 0x00)
				end
			end
			
			--[[ This code draws guide lines that define the border of the map
			local function drawV(x, y1, y2)
				gui.drawLine(convertX(x), convertY(y1), convertX(x), convertY(y2))
			end
			local function drawH(y, x1, x2)
				gui.drawLine(convertX(x1), convertY(y), convertX(x2), convertY(y))
			end
			
			drawH(170000, 0, 108000)
			 drawH(155500, 0, 108000)
			drawH(110000, 0, 108000)
			drawH(70000, 0, 108000)
			drawV(108000, 70000, 170000)
			 drawV(98000, 70000, 170000)
			drawV(92000, 70000, 170000)
			drawV(32000, 70000, 170000)
			--]]
		end
	end
	
	emu.yield()
end