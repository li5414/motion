local imgui
local lfs

local function exists(name)
    if type(name)~="string" then return false end
    return os.rename(name,name) and true or false
end

local function isFile(name)
    if not exists(name) then return false end
    local f = io.open(name)
    if f then
        f:close()
        return true
    end
    return false
end

local function isDir(name)
    return (exists(name) and not isFile(name))
end

-- Get Operating System
local operatingSystem = love.system.getOS()
print("Detected operating system as: "..operatingSystem)

local dirChar = '/'
if operatingSystem == "Windows" then
    dirChar = '\\'
end

-- Export libs to save directory
imgui = love.filesystem.read('libs/imgui.so')
lfs = love.filesystem.read('libs/lfs.so')

if not love.filesystem.isFile('imgui.so') then
    print('Exporting imgui to SaveDirectory')
    love.filesystem.write('imgui.so', imgui)
end

if not love.filesystem.isFile('lfs.so') then
    print('Exporting lfs to SaveDirectory')
    love.filesystem.write('lfs.so', lfs)
end

-- Check if libraries are installed
local sd = love.filesystem.getSaveDirectory()                                   -- Save directory
local ld = sd:sub(0, sd:find(dirChar..'[^'..dirChar..']*$'))                                        -- Love directory

-- imgui
print("Checking love directory for imgui")
if isFile(ld..'imgui.so') then
    print("--imgui found. Checking that it is compatible")
    local file = io.open(ld..'imgui.so')
    local existingImgui = file:read('*all')
    if existingImgui == imgui then
        print('--imgui version found is compatible')
        print('--done')
    else
        print('!!imgui version does not match. Trying anyway, but expect failure')
    end
else
    print("--imgui not found, installing")
    os.rename(sd..'/imgui.so', ld..'imgui.so')
    print('--done')
end

-- lfs
print("Checking love directory for lfs")
if isFile(ld..'lfs.so') then
    print("--lfs found. Checking that it is compatible")
    local file = io.open(ld..'imgui.so')
    local existingImgui = file:read('*all')
    if existingImgui == imgui then
        print('--lfs version found is compatible')
        print('--done')
    else
        print('!!lfs version does not match. Trying anyway, but expect failure')
    end
else
    print('--lfs not found, installing')
    print(sd, ld)
    os.rename(sd..dirChar..'lfs.so', ld..'lfs.so')
    print('--done')
end

-- Write libraries to love directory
local imgui, size = love.filesystem.read('libs/imgui.so')
