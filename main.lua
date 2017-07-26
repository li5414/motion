imgui = require('imgui')
imguihelper = require('imguihelper')(imgui)
interface = require('interface')

love.graphics.setDefaultFilter('linear', 'nearest')
love.graphics.setLineStyle('rough')
love.graphics.setLineWidth(1)

DEBUG = true

interface:begin()

function love.update(dt)
    interface:update(dt)
    imgui.NewFrame()
end

function love.draw()
    love.graphics.clear(100, 100, 100, 255)
    interface:draw()
    imgui.Render()
end

function love.quit()
    imgui.ShutDown()
end

function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
    end
end

function love.keypressed(key)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
    end
end

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
    end
end
