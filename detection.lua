-- Required configuration variables should be defined in your config module

local templateCache = {}

-- Utility to process/convert segmented string paths or template name inputs
function convertSegmentedString(str)
    if type(str) == "table" then
        local converted = {}
        for k, v in pairs(str) do
            converted[k] = convertSegmentedString(v)
        end
        return converted
    end
    return tostring(str)
end

local function getPattern(filename)
    filename = convertSegmentedString(filename)
    if not templateCache[filename] then
        templateCache[filename] = Pattern(filename):similar(MATCH_THRESHOLD)
    end
    return templateCache[filename]
end

local function parseRegion(regArray)
    if not regArray then return nil end
    local x1, y1, x2, y2 = regArray[1], regArray[2], regArray[3], regArray[4]
    return Region(x1, y1, x2 - x1, y2 - y1)
end

function load_templates()
    for _, template_files in pairs(STAGE_TEMPLATES) do
        for _, filename in ipairs(template_files) do
            getPattern(filename)
        end
    end
    for _, template_files in ipairs(BOOST_TEMPLATES) do
        for _, filename in ipairs(template_files) do
            getPattern(filename)
        end
    end
end

function detect_templates(template_files, region)
    local searchReg = parseRegion(region) or getAppUsableScreenArea()
    local matches = {}

    snapshot()
    for _, filename in ipairs(template_files) do
        local pat = getPattern(filename)
        local match = searchReg:exists(pat)
        if match then
            table.insert(matches, {
                x = match:getX(),
                y = match:getY(),
                w = match:getW(),
                h = match:getH()
            })
        end
    end
    usePreviousSnap(false)
    return matches
end

function detect_stage(stage_names, exclude)
    if not stage_names then
        stage_names = {}
        for k in pairs(STAGE_TEMPLATES) do
            table.insert(stage_names, k)
        end
    end

    local excludeSet = {}
    if exclude then
        for _, name in ipairs(exclude) do
            excludeSet[name] = true
        end
    end

    for _, stage_name in ipairs(stage_names) do
        if not excludeSet[stage_name] then
            local template_files = STAGE_TEMPLATES[stage_name]
            local searchReg = parseRegion(STAGE_REGIONS[stage_name]) or getAppUsableScreenArea()
            
            if template_files then
                snapshot()
                for _, filename in ipairs(template_files) do
                    local pat = getPattern(filename)
                    if searchReg:exists(pat) then
                        usePreviousSnap(false)
                        return stage_name
                    end
                end
            end
            usePreviousSnap(false)
        end
    end
    return nil
end

function detect_anti_bot_odd_cards()
    local card_coords = {
        ANTI_BOT_CARD_POS_1,
        ANTI_BOT_CARD_POS_2,
        ANTI_BOT_CARD_POS_3,
        ANTI_BOT_CARD_POS_4,
        ANTI_BOT_CARD_POS_5,
        ANTI_BOT_CARD_POS_6,
    }

    local cardRegions = {}
    for i, pos in ipairs(card_coords) do
        cardRegions[i] = Region(pos[1], pos[2], ANTI_BOT_CARD_WIDTH, ANTI_BOT_CARD_HEIGHT)
    end

    local n = #cardRegions
    local sim = {}
    for i = 1, n do
        sim[i] = {}
        for j = 1, n do sim[i][j] = 0 end
    end

    -- Compare regions using dynamic screen snapshots
    usePreviousSnap(false)
    for i = 1, n do
        local snapshotPath = string.format("temp_card_%d.png", i)
        cardRegions[i]:save(snapshotPath)
        
        for j = 1, n do
            if i ~= j then
                local match = cardRegions[j]:exists(Pattern(snapshotPath):similar(0.5), 1)
                sim[i][j] = match and match:getScore() or 0.0
            end
        end
    end

    local avg_sim = {}
    print("Analyzing card similarity...")
    for i = 1, n do
        local sum = 0
        for j = 1, n do
            if i ~= j then sum = sum + sim[i][j] end
        end
        avg_sim[i] = { index = i - 1, score = sum / (n - 1) }
        print(string.format("  Card %d: similarity score %.2f", i, avg_sim[i].score))
    end

    table.sort(avg_sim, function(a, b) return a.score < b.score end)
    return { avg_sim[1].index, avg_sim[2].index }
end

return {
    detect_stage = detect_stage,
    load_templates = load_templates,
    detect_anti_bot_odd_cards = detect_anti_bot_odd_cards
}