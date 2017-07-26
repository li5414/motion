local lfs = require("lfs")

local dialog = {}
dialog.savDir = love.filesystem.getSaveDirectory()..'/'
dialog.dirImage = love.graphics.newImage('resources/dir.png')
dialog.fileImage = love.graphics.newImage('resources/file.png')
dialog.path = path or lfs.currentdir()

function dialog.new(mode, ...)
    local args = {...}
    local fileCallback, cancelCallback, path, defaultFilename, saveFile
    if mode == 'open' then
        fileCallback = args[1]
        cancelCallback = args[2]
        path = args[3]
    elseif mode == 'save' then
        saveFile = args[1]
        defaultFilename = args[2]
        successCallback = args[3]
        cancelCallback = args[4]
        path = args[5]
    end

    local self = {}
    setmetatable(self, {__index=dialog})

    self.files = {}
    self.fileCallback = fileCallback
    self.cancelCallback = cancelCallback
    self.saveFilename = defaultFilename or 'untitled'
    self.saveFile = saveFile
    self.view = 'list'
    self.mode = mode
    self.previewCanvas = nil
    self.previewImage = nil
    self.selectedTime = 0
    self.windowSizeSet = false
    self.columnWidthSet = false
    self.close = false
    self._pathbar = {}
    self._pathbar.viewButtonWidth = 0
    self.gridTileWidth = 64
    self.gridTileHeight = 64
    self.gridPadding = 8

    self:_updateFiles()
    love.filesystem.createDirectory('.imguitmp')

    return self
end

function dialog:draw()
    -- Create filedialog
    imgui.OpenPopup("File Chooser Dialog")

    -- Set dialog size
    if not self.defaultSizeSet then
        imgui.SetNextWindowSize(500, 300)
        self.defaultSizeSet = true
    end
    if imgui.BeginPopupModal("File Chooser Dialog") then
        self:_drawPathbar()
        if self.view == 'list' then
            self:_drawListView()
        elseif self.view == 'grid' then
            -- WORK IN PROGRESS
            -- TODO
            -- self:_drawGridView()
        end
        self:_drawButtons()

        imgui.EndPopup()
    end

    if not self.close then
        return self
    else
        self._cleanup()
    end
end

function dialog:_drawPathbar()
    imgui.BeginChild("Pathbar", imgui.GetContentRegionMax()-self._pathbar.viewButtonWidth-10, imgui.GetItemsLineHeightWithSpacing())
        local dirs = {'/', unpack(self:_splitString(dialog.path, '/'))}
        for i, name in ipairs(dirs) do
            if imgui.Button(name) then
                self:_gotoParentDir(#dirs - i)
            end
            imgui.SameLine()
        end
    imgui.EndChild()
    imgui.SameLine(imgui.GetContentRegionMax()-self._pathbar.viewButtonWidth)
    if imgui.Button("View") then
        if self.view == 'grid' then
            self.view = 'list'
        else
            self.view = 'grid'
        end
    end
    self._pathbar.viewButtonWidth = imgui.GetItemRectSize()
    if self.mode == 'save' then
        _, self.saveFilename = imgui.InputText("File Name", self.saveFilename, 64)
    end
end

function dialog:_drawListView()
    -- Draw list view
    imgui.BeginChild("ListView", 0, -imgui.GetItemsLineHeightWithSpacing())
    imgui.Columns(3, nil, true)                                             -- Begin columns for file browser
    if not self.columnWidthSet then
        imgui.NextColumn()                                                  -- Move to Size column
        imgui.SetColumnOffset(-1, 170)                                      -- Set offset for Size column
        imgui.NextColumn()                                                  -- Move to Modified column
        imgui.SetColumnOffset(-1, 240)                                      -- Set offset for Modified column
        imgui.NextColumn()                                                  -- Return to Name column
    end
    imgui.Separator()

    -- Table Header
    imgui.Text("Name")
    imgui.NextColumn()
    imgui.Text("Size")
    imgui.NextColumn()
    imgui.Text("Modified")
    imgui.NextColumn()
    imgui.Separator()

    if not self.columnWidthSet then
        imgui.NextColumn()                                                  -- Move to Size column
        imgui.SetColumnOffset(-1, 170)                                      -- Set offset for Size column
        imgui.NextColumn()                                                  -- Move to Modified column
        imgui.SetColumnOffset(-1, 240)                                      -- Set offset for Modified column
        imgui.NextColumn()                                                  -- Return to Name column
        self.columnWidthSet = true
    end
    -- List files
    for i, file in ipairs(self.files) do
        -- Name
        if imgui.Selectable(file.name, self.selected == i, "DontClosePopups") then
            self:_fileClicked(i, file)
        end
        imgui.NextColumn()

        -- Size
        if file.attributes.mode ~= 'directory' then
            local divisor
            local suffix

            if file.attributes.size > 1073741824 then
                divisor = 1073741824
                suffix = 'GB'
            elseif file.attributes.size > 1048576 then
                divisor = 1048576
                suffix = 'MB'
            elseif file.attributes.size > 1024 then
                divisor = 1024
                suffix = 'KB'
            else
                divisor = 1
                suffix = 'B'
            end

            local size = tostring(file.attributes.size/divisor)
            local str = string.format("%.1f", size)..suffix
            imgui.Text(str)
        end
        imgui.NextColumn()

        -- Modified Date
        local date = os.date("*t", file.attributes.modification)
        imgui.Text(date.year..'-'..date.month..'-'..date.day)
        imgui.NextColumn()
    end

    imgui.Columns(1)
    imgui.EndChild()
end

function dialog:_drawGridView()
    imgui.BeginChild("GridView", 0, -imgui.GetItemsLineHeightWithSpacing())
    local regionWidth = imgui.GetContentRegionMax()
    local tileX = math.floor(regionWidth / self.gridTileWidth)
    if tileX < 1 then tileX = 1 end
    local tileY = math.ceil( #self.files/tileX )
    if tileY < 1 then tileY = 1 end
    local canvasWidth = tileX * self.gridTileWidth + (self.gridPadding * (tileX))
    local canvasHeight = tileY * self.gridTileHeight

    local canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
    love.graphics.setCanvas(canvas)
    for i, file in ipairs(self.files) do
        local x = (i-1)*self.gridTileWidth - math.floor((i-1)/tileX)*(self.gridTileWidth*tileX) + (self.gridTileWidth/2) + (self.gridPadding * ( (i-1) - math.floor((i-1)/tileX)*tileX ))
        local y = math.floor((i-1)/tileX)*self.gridTileHeight
        ox = file.image:getWidth()/2
        local sx = self.gridTileWidth / file.image:getWidth()
        local sy = self.gridTileHeight / file.image:getHeight()
        local s
        if sx < sy then
            s = sx
        else
            s = sy
        end
        love.graphics.draw(file.image, x, y, 0, s, s, ox)
    end

    imgui.Image(canvas, canvas:getWidth(), canvas:getHeight())
    imgui.EndChild()
end

function dialog:_drawButtons()
    if imgui.Button("Close") then
        if self.cancelCallback then
            self.cancelCallback()
        end
        self.close = true
    end
    imgui.SameLine()
    if self.mode == 'open' then
        if imgui.Button("Open") then
            if self.fileCallback then
                self.fileCallback(self:_getLink(self.selected))
            end
            self.close = true
        end
    elseif self.mode == 'save' then
        if imgui.Button('Save') then
            self:_saveFile()
            self.close = true
        end
    end
end

function dialog:_drawConfirm()
    -- TODO
end

function dialog:_updateFiles()
    self._cleanup()
    self.selected = nil
    self.files = {}
    for name in lfs.dir(dialog.path) do
        local file = {}
        file.name = name
        file.attributes = lfs.attributes(dialog.path..'/'..name)
        if file.name ~= "."
        and file.name ~= ".."
        and not string.match(file.name, '^%.') then
            table.insert(self.files, file)
        end
    end
    self:_sortFiles()

    -- Load thumbnails
    for i, file in ipairs(self.files) do
        local link = self:_getLink(i)
        if file.attributes.mode == 'directory' then
            file.image = self.dirImage
        else
            if file.name:match('.png$')
            or file.name:match('.jpg$')
            or file.name:match('.jpeg$')
            or file.name:match('.bmp$') then
                local success, image = pcall(love.graphics.newImage, link)
                if success then
                    file.image = image
                end
            else
                file.image = self.fileImage
            end
        end
    end
end

function dialog:_getLink(index)
    local clock = os.clock()
    lfs.link(dialog.path..'/'..self.files[index].name, love.filesystem.getSaveDirectory()..'/'..clock)
    self.files[index].link = clock

    return clock
end

function dialog:_fileClicked(i, name)
    -- Detect double click
    if (self.selected == i) and (os.clock() - self.selectedTime) < 0.25 then
        if self.files[i].attributes.mode == 'directory' then
            dialog.path = dialog.path..'/'..self.files[i].name
            self.tmpPath = dialog.path
            self:_updateFiles()
        elseif self.files[i].attributes.mode == 'file' then
            if self.mode == 'open' then
                if self.fileCallback then
                    self.fileCallback(self.files[i].link)
                end
                self.close = true
            elseif self.mode == 'save' then
                print("ARE YOU SURE YOU WANT TO OVERWRITE???!?!??!??!??!") -- TODO
            end
        end
    else
        self.selected = i
    end
    if self.files[i] and self.files[i].attributes.mode == 'file' then
        self.saveFilename = self.files[i].name
    end
    self.selectedTime = os.clock()
end

function dialog:_saveFile()
    local tmpFile = lfs.currentdir()..'/'..self.saveFile
    local newFile = dialog.path..'/'..self.saveFilename
    os.rename(tmpFile, newFile)
end

function dialog:_splitString(string, char)
    local strings = {}
    for substring in string.gmatch(string, '[^'..char..']+') do
        table.insert(strings, substring)
    end

    return strings
end

function dialog:_sortFiles()
    local files = {}
    local directories = {}

    for _, file in ipairs(self.files) do
        if file.attributes.mode == 'file' then
            table.insert(files, file)
        elseif file.attributes.mode == 'directory' then
            table.insert(directories, file)
        end
    end

    table.sort(files, self._sortByName)
    table.sort(directories, self._sortByName)

    self.files = {}
    for _, file in ipairs(directories) do
        table.insert(self.files, file)
    end
    for _, file in ipairs(files) do
        table.insert(self.files, file)
    end
end

function dialog._sortByName(a, b)
    return string.lower(a.name) < string.lower(b.name)
end

function dialog:_gotoParentDir(n)
    for i=1, n do
        local index = dialog.path:find('/[^/]*$')
        if index ~= 1 then
            dialog.path = dialog.path:sub(0, index-1)
        else
            dialog.path = '/'
        end

        self.tmpPath = dialog.path
        self:_updateFiles()
    end
end

-- Clean up tmp directory
function dialog._cleanup()
    for name in lfs.dir(love.filesystem.getSaveDirectory()) do
        local path = love.filesystem.getSaveDirectory()..'/'..name
        os.remove(path)
    end
end

return dialog
