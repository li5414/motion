local toolbar = {}

function toolbar:draw()
    imgui.PushStyleVar("WindowPadding", 0, 0)
    imgui.PushStyleVar("ItemSpacing", 0, 8)
    imgui.BeginChild("Toolbar", 0, 0, false, "NoScrollbar")
    imgui.Button("L", 24, 24)
    if imgui.IsItemClicked() then
        interface.timeline:move('left')
    end
    imgui.Button("R", 24, 24)
    if imgui.IsItemClicked() then
        interface.timeline:move('right')
    end
    imgui.Button("X", 24, 24)
    if imgui.IsItemClicked() then
        interface.timeline:remove()
    end
    imgui.EndChild()
    imgui.PopStyleVar()
    imgui.PopStyleVar()
end

return toolbar
