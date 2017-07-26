local preview = {}
preview.canvas = love.graphics.newCanvas()
preview.framerate = 30
preview.time = 1/preview.framerate
preview.currFrame = 1
preview.width = 1
preview.height = 1
preview.scale = 1
preview.autoScale = true

function preview:update(dt)
    local tileWidth = interface.properties:getValue('tileWidth')
    local tileHeight = interface.properties:getValue('tileHeight')

    self.framerate = interface.properties:getValue('framerate')

    if #interface.timeline.quads >= 1 then
        self.time = self.time - dt
    end
    if self.time <= 0 then
        self.currFrame = self.currFrame + 1
        self.time = 1/self.framerate
    end
    if self.currFrame > #interface.timeline.quads then
        self.currFrame = 1
    end
    if self.autoScale then
        if (self.width / tileWidth) > (self.height / tileHeight) then
            self.scale = self.height / tileHeight
        else
            self.scale = self.width / tileWidth
        end
    else
        self.scale = 1
    end
end

function preview:updateCanvas(image)
    self.canvas = love.graphics.newCanvas(self.width, self.height)
end

function preview:draw(width, delta)
    local quad = interface.timeline.quads[self.currFrame]
    local tileWidth = interface.properties:getValue('tileWidth')
    local tileHeight = interface.properties:getValue('tileHeight')

    if quad and quad ~= "missingTile" then
        local x = (self.width / 2) - (tileWidth*self.scale / 2)
        local y = (self.height / 2) - (tileHeight*self.scale / 2)
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()
        love.graphics.draw(interface.image, quad, x, y, 0, self.scale, self.scale)
        love.graphics.setCanvas()
    end

    imgui.PushStyleVar("WindowPadding", 0, 0)
    imgui.BeginChild("Preview", width + delta, 0, true, "NoScrollbar")
        self.width, self.height = imgui.GetContentRegionMax()
        imgui.Image(self.canvas, self.width, self.height)
    imgui.EndChild()
    imgui.PopStyleVar()
end

return preview
