local imguihelper = {}

function imguihelper.DragHSeparator(name, height, delta, padding)
    local change

    imgui.PushStyleVar("ItemSpacing", 0, 0)
        local done = false
        imgui.InvisibleButton(name.."_hseparator", -1, padding)
        if imgui.IsItemActive() then
            change = true
            _, delta = imgui.GetMouseDragDelta()
            done = true
        end
        imgui.Text(name)
        imgui.SameLine()
        imgui.InvisibleButton(name.."_hseparator2", -1, 13)
        if imgui.IsItemActive() then
            change = true
            _, delta = imgui.GetMouseDragDelta()
            done = true
        end

        if not done then
            height = height + delta
            delta = 0
        end
    imgui.PopStyleVar()

    return change, height, delta
end

function imguihelper.DragVSeparator(name, width, delta, padding)
    local change

    imgui.PushStyleVar("ItemSpacing", 0, 0)
        imgui.SameLine()
        imgui.InvisibleButton(name.."_vseparator", padding, -1)
        if imgui.IsItemActive() then
            change = true
            delta = imgui.GetMouseDragDelta()
        else
            width = width + delta
            delta = 0
        end
        imgui.SameLine()
    imgui.PopStyleVar()

    return change, width, delta
end

return function(imgui)
    for name, value in pairs(imguihelper) do
        imgui[name] = value
    end
end
