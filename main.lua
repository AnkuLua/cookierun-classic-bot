-- special requirement for AnkuLua environment settings
package.path = package.path .. ";" .. scriptPath() .. "?.lua"

setImagePath(scriptPath() .. "templates")
local dimension = 720
Settings:setCompareDimension(false, dimension)
Settings:setScriptDimension(false, dimension)
type = typeOf
--
local _original_print = print

-- Helper to convert arguments or segmented strings to printable string format
function convertSegmentedString(val)
    if type(val) == "table" then
        local items = {}
        for i, v in ipairs(val) do
            table.insert(items, convertSegmentedString(v))
        end
        return "{" .. table.concat(items, ", ") .. "}"
    end
    return tostring(val)
end

-- Override global print with timestamp logging
local statusReg = Region(0, 0, 1280, 100)
function print(...)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local args = { ... }
    local formattedArgs = {}

    for i, arg in ipairs(args) do
        table.insert(formattedArgs, convertSegmentedString(arg))
    end

    _original_print("[" .. timestamp .. "]", unpack(formattedArgs))
    if (type(unpack(formattedArgs)) == "string") then
        statusReg:highlight(unpack(formattedArgs), 1)
    end
end

-- Entry point execution (requires bot.lua in the same directory)
local bot = require("bot")
if type(bot) == "table" and bot.main then
    bot.main()
elseif type(main) == "function" then
    main()
end