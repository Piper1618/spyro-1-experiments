
print([[
Press R3 to enter and exit free camera mode
Move camera with the right stick.
Hold L2 to move camera vertically.
Hold R2 to pan camera.
Hold L2 + R2 to move camera very quickly.
]])

inputs = require("libs.inputs")

cameraSpeed = 100
cameraRotSpeed = 0.04
while true do
	-- This is reading the lag counter in Spyro the Dragon
	if memory.read_u32_le(0x075760) % 2 == 0 and lastCameraUpdate ~= emu.framecount() then
		lastCameraUpdate = emu.framecount()
		
		inputs:update()
		
		if inputs.R3.press then
			if memory.read_u32_le(0x037CFC) == 0 then
				-- unlock the camera
				memory.write_u32_le(0x037CFC, 0x0C00D7ED)
			else
				-- lock the camera
				memory.write_u32_le(0x037CFC, 0)
				
				-- Record initial values for camera position and orintation
				cameraPitch = bit.lshift(memory.read_u16_le(0x076E1E), 4)
				if cameraPitch >= 0x8000 then cameraPitch = -0x10000 + cameraPitch end
				cameraPitch = cameraPitch / 0x4000 / 2 * math.pi
				
				cameraYaw = memory.read_u16_le(0x076E20) / 0x1000 * 2 * math.pi
				
				cameraX = memory.read_u32_le(0x076DF8)
				cameraY = memory.read_u32_le(0x076DFC)
				cameraZ = memory.read_u32_le(0x076E00)
			end
		end
		
		if memory.read_u32_le(0x037CFC) == 0 then
			-- Get right stick inputs, scaled to [-1, 1]
			rsx = (inputs.rightStick_x.value - 128) / 128
			rsy = -((inputs.rightStick_y.value - 128) / 128)
			-- Enforce dead zone
			if rsx * rsx + rsy * rsy < 0.1 ^ 2 then rsx = 0 rsy = 0 end
			
			if inputs.L2.value then
				if inputs.R2.value then
					-- L2 and R2 both held
					-- Same as "Neither held", but faster
					cameraX = cameraX + (math.cos(cameraYaw) * rsy + math.sin(cameraYaw) * rsx) * cameraSpeed * 8
					cameraY = cameraY + (-math.cos(cameraYaw) * rsx + math.sin(cameraYaw) * rsy) * cameraSpeed * 8
				else
					-- L2 held
					-- Camera moves vertically
					cameraZ = cameraZ + rsy * cameraSpeed
					cameraX = cameraX + (math.sin(cameraYaw) * rsx) * cameraSpeed
					cameraY = cameraY + (-math.cos(cameraYaw) * rsx) * cameraSpeed
				end
			elseif inputs.R2.value then
				-- R2 held
				-- Camera can pan
				cameraPitch = cameraPitch - rsy * cameraRotSpeed
				cameraYaw = cameraYaw - rsx * cameraRotSpeed
				
				local cp = math.floor(cameraPitch * 2 / math.pi * 0x4000 + 0.5)
				if cp < 0 then cp = 0x10000 + cp end
				memory.write_u16_le(0x076E1E, math.floor(cp / 16))
				
				memory.write_u16_le(0x076E20, math.floor(cameraYaw / 2 / math.pi * 0x1000 + 0.5) % 0x1000)
			else
				-- Neither held
				-- Move camera on a horizontal plane
				cameraX = cameraX + (math.cos(cameraYaw) * rsy + math.sin(cameraYaw) * rsx) * cameraSpeed
				cameraY = cameraY + (-math.cos(cameraYaw) * rsx + math.sin(cameraYaw) * rsy) * cameraSpeed
			end
			
			-- Write updated camera position back into game memory.
			memory.write_u32_le(0x076DF8, math.floor(cameraX))
			memory.write_u32_le(0x076DFC, math.floor(cameraY))
			memory.write_u32_le(0x076E00, math.floor(cameraZ))
		end
	end
	emu.yield()
end