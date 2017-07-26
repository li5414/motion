local interface = {}
-- Widgets
interface.menubar = require('widgets/menubar')
interface.properties = require('widgets/properties')
interface.preview = require('widgets/preview')
interface.spritesheet = require('widgets/spritesheet')
interface.timeline = require('widgets/timeline')
interface.toolbar = require('widgets/toolbar')
interface.Filedialog = require('widgets/imguiFile')

-- Layout
interface.propertiesHeight = -200
interface.propertiesDelta = 0
interface.spritesheetHeight = -150
interface.spritesheetDelta = 0
interface.sidebarWidth = 200
interface.sidebarDelta = 0
interface.timelineWidth = -32
interface.image = love.graphics.newImage(love.image.newImageData(1, 1))

function interface:begin()
    interface.spritesheet:updateCanvas()
    interface.timeline:updateCanvas()
end

function interface:open()
    self.filedialog = interface.Filedialog.new('open', self.openCallback)
end

function interface:save()
    print(#self.timeline.quadData)
    local name = self.properties:getValue('name')
    local tileWidth = self.properties:getValue('tileWidth')
    local tileHeight = self.properties:getValue('tileHeight')
    local framerate = self.properties:getValue('framerate')

    local lines = {}
    table.insert(lines, 'local animation = {}')
    table.insert(lines, "animation.name = "..name)
    table.insert(lines, "animation.tileWidth = "..tileWidth)
    table.insert(lines, "animation.tileHeight = "..tileHeight)
    table.insert(lines, "animation.framerate = "..framerate)
    table.insert(lines, "animation.tiles = {")
    for _, quadData in ipairs(self.timeline.quadData) do
        table.insert(lines, '\t{ '..quadData[1]..', '..quadData[2]..' },')
    end
    table.insert(lines, "}")
    table.insert(lines, "return animation")

    local file = io.open(name..'.lua', 'w')
    for _, line in ipairs(lines) do
        file:write(line..'\n')
    end
    file:close()

    self.filedialog = interface.Filedialog.new('save', name..'.lua', name..'.lua')
end

function interface.openCallback(file)
    success, image = pcall(love.graphics.newImage, file)
    if success then
        interface.image = image
        interface.spritesheet:updateCanvas()
        interface.spritesheet:getTiles()
        interface.preview:updateCanvas()
    end
end

function interface:update(dt)
    self.preview:update(dt)
end

function interface:draw()
    self.menubar:draw()
    if self.filedialog then
        self.filedialog = self.filedialog:draw()
    end

    imgui.SetNextWindowPos(0, 19)
    imgui.SetNextWindowSize(love.graphics.getWidth(), love.graphics.getHeight() - 19)
    imgui.PushStyleVar("WindowRounding", 0)
        imgui.Begin("Canvas", showCanvas, {"NoResize", "NoTitleBar", "NoScrollbar"})

        -- Sidebar
        imgui.BeginChild('Sidebar', self.sidebarWidth + self.sidebarDelta, 0, false)
            imgui.Text("Properties")
            self.properties:draw(self.sidebarWidth, self.sidebarDelta, self.propertiesHeight, self.propertiesDelta)
            local change
            change, self.propertiesHeight, self.propertiesDelta = imgui.DragHSeparator('Preview', self.propertiesHeight, self.propertiesDelta, 2)
            if change then
                self.preview:updateCanvas()
            end
            self.preview:draw(self.sidebarWidth, self.sidebarDelta)
        imgui.EndChild()

        local change
        change, self.sidebarWidth, self.sidebarDelta = imgui.DragVSeparator('MainSeparator', self.sidebarWidth, self.sidebarDelta, 12)
        if change then
            self.preview:updateCanvas()
            self.timeline:updateCanvas()
        end

        -- Main Window
        imgui.BeginGroup()
            imgui.Text('Spritesheet')
            self.spritesheet:draw(self.spritesheetHeight, self.spritesheetDelta)
            local change
            change, self.spritesheetHeight, self.spritesheetDelta = imgui.DragHSeparator('Timeline', self.spritesheetHeight, self.spritesheetDelta, 2)
            if change then
                self.timeline:updateCanvas()
            end
            imgui.BeginGroup()
            self.timeline:draw(self.timelineWidth)
            imgui.SameLine()
            self.toolbar:draw()
            imgui.EndGroup()
        imgui.EndGroup()
        imgui.End()
    imgui.PopStyleVar()
end

return interface
