local spritesheet = {}
spritesheet.canvas = love.graphics.newCanvas()
spritesheet.tiles = {}
spritesheet.scale = 1
spritesheet.selected = nil
spritesheet.selectedTime = 0

function spritesheet:updateCanvas()
    self.canvas = love.graphics.newCanvas(interface.image:getWidth()*self.scale, interface.image:getHeight()*self.scale)
end

function spritesheet:getTiles()
    local width = interface.image:getWidth()
    local height = interface.image:getHeight()
    local tileWidth = interface.properties:getValue('tileWidth')
    local tileHeight = interface.properties:getValue('tileHeight')
    local xOffset = interface.properties:getValue('xOffset')
    local yOffset = interface.properties:getValue('yOffset')
    local xSpacing = interface.properties:getValue('xSpacing')
    local ySpacing = interface.properties:getValue('ySpacing')
    local xTiles = math.floor(width/tileWidth)
    local yTiles = math.floor(height/tileHeight)

    self.tiles = {}

    for y=1, yTiles do
        self.tiles[y] = {}
        for x=1, xTiles do
            self.tiles[y][x] = {}
            self.tiles[y][x].x = xOffset + (x-1)*(tileWidth + xSpacing)
            self.tiles[y][x].y = yOffset + (y-1)*(tileHeight + ySpacing)
        end
    end
end

function spritesheet:draw(childHeight, delta)
    -- Draw spritesheet
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()
    love.graphics.draw(interface.image, 0, 0, 0, self.scale)

    -- Draw grid
    local width = interface.properties:getValue('tileWidth')
    local height = interface.properties:getValue('tileHeight')
    for _, row in ipairs(self.tiles) do
        for _, tile in ipairs(row) do
            love.graphics.rectangle('line', tile.x*self.scale, tile.y*self.scale, width*self.scale, height*self.scale)

            if tile == self.selected then
                love.graphics.setColor(192, 64, 64, 64)
                love.graphics.rectangle('fill', tile.x*self.scale, tile.y*self.scale, width*self.scale, height*self.scale)
                love.graphics.setColor(255, 255, 255, 255)
            end
        end
    end

    love.graphics.setCanvas()

    imgui.BeginChild("Spritesheet", 0, childHeight + delta, true, "HorizontalScrollbar")
    imgui.Image(self.canvas, self.canvas:getWidth(), self.canvas:getHeight())
    if imgui.IsItemClicked() then
        local minX, minY = imgui.GetItemRectMin()
        local absX, absY = imgui.GetMousePos()
        local mouseX = (absX - minX)/self.scale
        local mouseY = (absY - minY)/self.scale
        local tileWidth = interface.properties:getValue('tileWidth')
        local tileHeight = interface.properties:getValue('tileHeight')

        for y, row in ipairs(self.tiles) do
            for x, tile in ipairs(row) do
                if (mouseX >= tile.x) and (mouseX < tile.x + tileWidth)
                and (mouseY >= tile.y) and (mouseY < tile.y + tileHeight) then
                    if (self.selected == tile) and (os.clock() - self.selectedTime) < 0.25 then
                        interface.timeline:addTile({x, y})
                        self.selectedTime = 1/0
                        self.selected = nil
                        goto continue
                    else
                        self.selectedTime = os.clock()
                    end
                    self.selected = tile
                    goto continue
                end
            end
        end
        ::continue::
    end
    imgui.EndChild()
end

return spritesheet
