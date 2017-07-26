local menubar = {}
menubar.height = 19

function menubar:draw()
    if imgui.BeginMainMenuBar() then
        if imgui.BeginMenu("File") then
            if imgui.MenuItem("Open") then
                interface:open()
            end
            if imgui.MenuItem("Save") then
                interface:save()
            end
            if imgui.MenuItem("Quit") then
                love.quit()
            end
            imgui.EndMenu()
        end
        if imgui.BeginMenu("View") then
            local change, value

            -- Spritesheet Scale
            change, value = imgui.InputInt("Spritesheet Scale", math.floor(interface.spritesheet.scale*100+0.5), 10)
            if value >= 10 then
                interface.spritesheet.scale = value/100
            end
            if change then
                interface.spritesheet:updateCanvas()
            end

            -- Timeline Autoscale
            change, interface.timeline.autoScale = imgui.Checkbox("Autoscale Timeline", interface.timeline.autoScale)
            if change then
                interface.timeline:updateCanvas()
            end

            -- Preview Autoscale
            change, interface.preview.autoScale = imgui.Checkbox("Autoscale Preview", interface.preview.autoScale)

            imgui.EndMenu()
        end
    end
    imgui.EndMainMenuBar()
end

return menubar
