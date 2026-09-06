-- Utility function for segmented string processing
function convertSegmentedString(segments)
    if type(segments) == "table" then
        return table.concat(segments, "")
    end
    return tostring(segments)
end

function save_debug_screen(screen)
    local folder = "debug_screens"
    
    -- Ensure directory exists
    os.execute("mkdir -p " .. folder)

    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filepath = convertSegmentedString({folder, "/debug_screen_", timestamp, ".png"})

    -- Save screen via AnkuLua API
    if screen and type(screen.save) == "function" then
        screen:save(filepath)
    else
        saveImage(filepath)
    end

    print("💾 Saved screen to " .. filepath)
end