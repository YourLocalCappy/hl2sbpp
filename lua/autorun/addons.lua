-- Automatic Addons (with addon.txt)

AddonLoader = AddonLoader or {}
AddonLoader.Loaded = AddonLoader.Loaded or {}

local function Log(msg)
    print("[AddonLoader] " .. tostring(msg))
end

-- Avoids errors due to command names
local function SanitizeCommandName(name)
    name = string.lower(name or "addon")
    name = name:gsub("%s+", "_")
    name = name:gsub("[^a-z0-9_]", "")
    return "addon_" .. name
end

local function ParseAddonTXT(text)
    local main = {}
    local extras = {}

    local function parseBlock(block)
        local t = {}
        for line in block:gmatch("[^\r\n]+") do
            local key, value = line:match("^%s*([%w_]+)%s*=%s*(.+)$")
            if key and value then
                value = value:match('^"(.*)"$') or value
                if value == "true" then value = true end
                if value == "false" then value = false end
                t[key] = value
            end
        end
        return t
    end

    for block in text:gmatch("ExtraButtons%s*=%s*%b{}") do
        local inside = block:match("{(.*)}")
        if inside then
            table.insert(extras, parseBlock(inside))
        end
        text = text:gsub(block, "")
    end

    main = parseBlock(text)

    return {
        Main = main,
        Extras = extras
    }
end

local function CreateButton(meta) -- here we set the button stuff
    local name     = meta.Name or "Unnamed Button"
    local cmdText  = meta.Command or ""
    local tab      = meta.Tab or "Addons"
    local category = meta.Category or "Addons"
    local icon     = meta.Icon or ""

    if cmdText == "" then return end

    local cmd = SanitizeCommandName(name)

    if concommand and concommand.Create then
        concommand.Create(cmd, function()
            if engine and engine.ClientCmd_Unrestricted then
                engine.ClientCmd_Unrestricted(cmdText)
            else
                Log("can't create cmd!")
            end
        end)
    end

    if smlib and smlib.CreateButtonInHeader then
        smlib.CreateButtonInHeader(true, tab, name, icon, "", cmd, category)
    end

    Log("Button created: " .. name)
end

function AddonLoader.LoadAddonFolder(folder)
    local addonPath = folder .. "/addon.txt"

    if not file.Exists(addonPath, "MOD") then return end
    if AddonLoader.Loaded[addonPath] then return end

    local content = file.Read(addonPath)
    if not content then
        Log("Failed to read: " .. addonPath)
        return
    end

    local parsed = ParseAddonTXT(content)
    local meta = parsed.Main
    local extras = parsed.Extras

    Log("Loaded addon: " .. (meta.Name or "Unnamed Addon"))
    Log("  Desc: " .. (meta.Description or "No description"))
    Log("  Version: " .. (meta.Version or "?"))
    Log("  Author: " .. (meta.Author or "Unknown"))

    if meta.ShowInSpawnmenu == true then
        CreateButton(meta)
    end

    for _, btn in ipairs(extras or {}) do
        CreateButton(btn)
    end

    AddonLoader.Loaded[addonPath] = true
end

function AddonLoader.Scan()
    local folders, _ = file.Find("addons/*", "MOD")

    if not folders or #folders == 0 then
        Log("No folders found inside addons")
        return
    end

    for _, folder in ipairs(folders) do
        local full = "addons/" .. folder

        if file.IsDir(full, "MOD") then
            AddonLoader.LoadAddonFolder(full)
        end
    end
end

-- Now we scan the addons
AddonLoader.Scan()
