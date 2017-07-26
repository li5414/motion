local properties = {}
properties.dataName = {
    'name',
    'framerate',
    'tileWidth',
    'tileHeight',
    'xOffset',
    'yOffset',
    'xSpacing',
    'ySpacing',
}
properties.dataValue = {
    'Untitled',
    20,
    16,
    16,
    0,
    0,
    0,
    0,
}

properties.dataMinimum = {
    nil,
    1,
    1,
    1,
    0,
    0,
    0,
    0,
}

function properties:getValue(name)
    for i, n in ipairs(self.dataName) do
        if n == name then
            return self.dataValue[i]
        end
    end
    error('Unknown property ['..name..']')
end

function properties:draw(width, deltaWidth, height, deltaHeight)
    imgui.BeginChild("Properties", width + deltaWidth, height + deltaHeight, true)
        for i in ipairs(self.dataValue) do
            local t = type(self.dataValue[i])
            local change, value
            if t == 'string' then
                local change, value = imgui.InputText(self.dataName[i], self.dataValue[i], 64)
                self.dataValue[i] = value
            elseif t == 'number' then -- TODO FIXME HACK GROSS IMGUI DOESNT WORK
                change, value = imgui.InputInt(self.dataName[i], self.dataValue[i], 1)
                if change then
                    if value < self.dataValue[i] then
                        self.dataValue[i] = math.max(self.dataValue[i] - 1, self.dataMinimum[i])
                    else
                        self.dataValue[i] = self.dataValue[i] + 1
                    end
                end
            elseif t == 'boolean' then
                change, self.dataValue[i] = imgui.Checkbox(self.dataName[i], self.dataValue[i])
            end
            if change then
                interface.spritesheet:getTiles(interface.image)
                interface.timeline:updateQuads()
                interface.timeline:updateCanvas()
            end
        end
    imgui.EndChild()
end

return properties
