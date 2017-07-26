local timeline = {}
timeline.canvas = love.graphics.newCanvas(1, 1)
timeline.tiles = {}
timeline.quads = {}
timeline.quadData = {}
timeline.scale = 1
timeline.padding = 8
timeline.height = 150
timeline.selected = nil
timeline.autoScale = true

function timeline:addTile(tile)
    table.insert(self.tiles, tile)
    local quad, quadData = self:newQuad(tile)
    table.insert(self.quads, quad)
    table.insert(self.quadData, quadData)
    self:updateCanvas()
end

function timeline:updateQuads()
    self.quads = {}
    self.quadData = {}
    for _, tile in ipairs(self.tiles) do
        local quad, quadData = self:newQuad(tile)
        table.insert(self.quads, quad)
        if quadData then
            table.insert(self.quadData, quadData)
        end
    end
end

function timeline:updateCanvas()
    local tileWidth = interface.properties:getValue('tileWidth')
    local tileHeight = interface.properties:getValue('tileHeight')

    if self.autoScale then
        self.scale = (self.height / tileHeight)*0.9
    else
        self.scale = 1
    end
    if #self.quads >= 1 then
        local width = #self.quads*tileWidth*self.scale + (#self.quads)*self.padding
        if width < self.width then
            width = self.width+20 -- UGLY: This causes the horizontal scrollbar to always show. imgui AlwaysHorizontalScrollbar is not working
        end
        self.canvas = love.graphics.newCanvas(width, self.height)
    end
end

function timeline:newQuad(tilePosition)
    local tileWidth = interface.properties:getValue('tileWidth')
    local tileHeight = interface.properties:getValue('tileHeight')
    local x = tilePosition[1]
    local y = tilePosition[2]

    if interface.spritesheet.tiles[y] and interface.spritesheet.tiles[y][x] then
        local tile = interface.spritesheet.tiles[y][x]
        local quadData = {tile.x, tile.y}
        local quad = love.graphics.newQuad(tile.x, tile.y, tileWidth, tileHeight, interface.image:getWidth(), interface.image:getHeight())
        return quad, quadData
    else
        return "missingTile", nil
    end
end

function timeline:move(dir)
    if self.selected then
        if dir == 'left' then
            for i=1, #self.quads do
                if self.quads[i] == self.selected then
                    self.quads[i] = self.quads[i-1]
                    self.quads[i-1] = self.selected
                    return true
                end
            end
        elseif dir == 'right' then
            for i=1, #self.quads do
                if self.quads[i] == self.selected then
                    self.quads[i] = self.quads[i+1]
                    self.quads[i+1] = self.selected
                    return true
                end
            end
        end
    end
end

function timeline:remove(dir)
    if self.selected then
        for i, quad in ipairs(self.quads) do
            if quad == self.selected then
                table.remove(self.quads, i)
                table.remove(self.tiles, i)
                if self.quads[i] then
                    self.selected = self.quads[i]
                elseif #self.quads >= 1 then
                    self.selected = self.quads[i-1]
                end

                return
            end
        end
    end
end

function timeline:draw(childWidth)
    local tileWidth = interface.properties:getValue('tileWidth')
    local tileHeight = interface.properties:getValue('tileHeight')
    local y = (self.height / 2) - (tileHeight*self.scale / 2)

    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    for i, quad in ipairs(self.quads) do
        if quad == "missingTile" then
            self.drawMissingTile((i-1)*(self.scale*tileWidth + self.padding), y, tileWidth*self.scale, tileHeight*self.scale)
        else
            love.graphics.draw(interface.image, quad, (i-1)*(self.scale*tileWidth + self.padding), y, 0, self.scale, self.scale)
        end
        if quad == self.selected then
            love.graphics.setColor(255, 92, 92, 92)
            love.graphics.rectangle('fill', (i-1)*(self.scale*tileWidth + self.padding), y, tileWidth*self.scale, tileHeight*self.scale)
            love.graphics.setColor(255, 255, 255, 255)
        end
    end
    love.graphics.setCanvas()

    imgui.PushStyleVar("WindowPadding", 8, 0)
    imgui.BeginChild("Timeline", childWidth, 0, true, "HorizontalScrollbar")
        self.width, self.height = imgui.GetContentRegionMax()
        imgui.Image(self.canvas, self.canvas:getWidth(), self.canvas:getHeight())
        if imgui.IsItemClicked() then
            local minX, minY = imgui.GetItemRectMin()
            local absX, absY = imgui.GetMousePos()
            local x = (absX - minX)--/self.scale
            local y = (absY - minY)/self.scale
            local tileWidth = interface.properties:getValue('tileWidth')
            local tileHeight = interface.properties:getValue('tileHeight')

            for i, quad in ipairs(self.quads) do
                local qx1 = (i-1)*(self.scale*tileWidth + self.padding) - self.padding/2
                local qx2 = qx1 + tileWidth*self.scale + self.padding/2
                if (x >= qx1) and (x < qx2) then
                    self.selected = quad
                end
            end
        end
    imgui.EndChild()
    imgui.PopStyleVar()
end

function timeline.drawMissingTile(x, y, w, h)
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle('fill', x, y, w, h)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.rectangle('line', x, y, w, h)
    love.graphics.line(x, y, x+w, y+h)
end

return timeline
