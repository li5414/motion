local motion = {}

local function newAnimation(file, imageFile)
    local data = require(file)
    local image = love.graphics.newImage(imageFile)

    local animation = {}
    setmetatable(animation, {__index=motion})
    animation.frames = {}
    animation.frameCallbacks = {}
    animation.frameCallbacks['start'] = {}
    animation.frameCallbacks['end'] = {}
    animation.image = image
    animation.curFrame = 1
    animation.frameTime = 1 / data.framerate
    animation.timer = animation.frameTime
    animation.playing = true
    animation.loop = true
    animation.increment = 1
    animation.flipX = false
    animation.flipY = false
    animation.width = data.tileWidth
    animation.height = data.tileHeight

    for _, quadData in ipairs(data.tiles) do
        local quad = love.graphics.newQuad(quadData[1], quadData[2], data.tileWidth, data.tileHeight, image:getWidth(), image:getHeight())
        table.insert(animation.frames, quad)
        table.insert(animation.frameCallbacks, {})
    end

    return animation
end

function motion:update(dt)
	if not self.playing then return end

	self.timer = self.timer - dt
    if self.timer <= 0 then
        if self.increment > 0 then
    		if self.curFrame < #self.frames then
    			self:setFrame(self.curFrame + self.increment)
    		else
    			if self.loop then
    				self:setFrame(1)
    			else
    				self.playing = false
    			end
    		end
    	elseif self.increment < 0 then
            if self.curFrame > 1 then
                self:setFrame(self.curFrame + self.increment)
            else
                if self.loop then
                    self:setFrame(#self.frames)
                else
                    self.playing = false
                end
            end
        end
        self.timer = self.frameTime
    end
end

function motion:draw(x, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.draw(self.image, self.frames[self.curFrame], self:_getDrawArgs(x, y, r, sx, sy, ox, oy, kx, ky))
end

function motion:resume()
	self.playing = true
end

function motion:pause()
	self.playing = false
end

function motion:setFrame(index)
	self.curFrame = index
	for _, callbackTable in ipairs(self.frameCallbacks[index]) do
		local callback = callbackTable[1]
		local args = callbackTable[2]
		return callback(unpack(args))
	end
    if index == 1 then
        if self.increment > 0 then
            for _, callbackTable in ipairs(self.frameCallbacks['start']) do
                local callback = callbackTable[1]
                local args = callbackTable[2]
                return callback(unpack(args))
            end
        elseif self.increment < 0 then
            for _, callbackTable in ipairs(self.frameCallbacks['end']) do
                local callback = callbackTable[1]
                local args = callbackTable[2]
                return callback(unpack(args))
            end
        end
    elseif index == #self.frames then
        if self.increment > 0 then
            for _, callbackTable in ipairs(self.frameCallbacks['end']) do
                local callback = callbackTable[1]
                local args = callbackTable[2]
                return callback(unpack(args))
            end
        elseif self.increment < 0 then
            for _, callbackTable in ipairs(self.frameCallbacks['start']) do
                local callback = callbackTable[1]
                local args = callbackTable[2]
                return callback(unpack(args))
            end
        end
    end
end

function motion:reverse()
	self.increment = -self.increment
end

function motion:addCallback(frame, func, ...)
	local args = {...}
	local callbackTable = {func, args}
	table.insert(self.frameCallbacks[frame], callbackTable)
	return callbackTable
end

function motion:removeCallback(frame, callbackTable)
	for i, item in pairs(self.frameCallbacks) do
		if item == callbackTable then
			table.remove(self.frameCallbacks, i)
			return true
		end
	end

	return false
end

function motion:_getDrawArgs(x, y, r, sx, sy, ox, oy, kx, ky)
	if self.flipX or self.flipY then
		r,sx,sy,ox,oy,kx,ky = r or 0, sx or 1, sy or 1, ox or 0, oy or 0, kx or 0, ky or 0
		local w, h = self.width, self.height

		if self.flipX then
		sx = sx * -1
		ox = w - ox
		kx = kx * -1
		ky = ky * -1
		end

		if self.flipY then
		sy = sy * -1
		oy = h - oy
		kx = kx * -1
		ky = ky * -1
		end
	end
	return x, y, r, sx, sy, ox, oy, kx, ky
end

return newAnimation
