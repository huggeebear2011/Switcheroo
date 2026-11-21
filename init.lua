-- Switcheroo: configurable DaVinci Resolve page and keyboard preset switching.
-- Copy this file to ~/.hammerspoon/init.lua, then edit the configuration below.

local config = {
    resolveAppName = "DaVinci Resolve",
    pythonPath = "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Resources/ResolvePython/ResolvePython",
    -- Optional: set this if DaVinciResolveScript cannot be imported automatically.
    pythonPathExtra = nil,
    alertDuration = 2,
    requireResolveFrontmost = true,
    bindings = {
        { modifiers = {}, key = "F2", page = "edit", preset = "EditPreset", label = "Edit" },
        { modifiers = {}, key = "F3", page = "color", preset = "ColorPreset", label = "Color" },
    },
}

local function fail(message)
    error("Switcheroo configuration error: " .. message, 0)
end

local function nonEmptyString(value, path)
    if type(value) ~= "string" or value:match("^%s*$") then
        fail(path .. " must be a non-empty string")
    end
end

local function validate()
    if type(hs) ~= "table" or type(hs.hotkey) ~= "table" or type(hs.task) ~= "table" then
        fail("Hammerspoon APIs are unavailable")
    end
    if type(config) ~= "table" then fail("config must be a table") end
    nonEmptyString(config.resolveAppName, "resolveAppName")
    nonEmptyString(config.pythonPath, "pythonPath")
    if config.pythonPathExtra ~= nil then nonEmptyString(config.pythonPathExtra, "pythonPathExtra") end
    if type(config.alertDuration) ~= "number" or config.alertDuration <= 0 then fail("alertDuration must be a positive number") end
    if type(config.requireResolveFrontmost) ~= "boolean" then fail("requireResolveFrontmost must be true or false") end
    if type(config.bindings) ~= "table" or #config.bindings == 0 then fail("bindings must contain at least one binding") end
    local seen = {}
    for i, binding in ipairs(config.bindings) do
        local p = "bindings[" .. i .. "]"
        if type(binding) ~= "table" then fail(p .. " must be a table") end
        if type(binding.modifiers) ~= "table" then fail(p .. ".modifiers must be a table") end
        nonEmptyString(binding.key, p .. ".key")
        nonEmptyString(binding.page, p .. ".page")
        nonEmptyString(binding.preset, p .. ".preset")
        if binding.label ~= nil then nonEmptyString(binding.label, p .. ".label") end
        local mods = {}
        for _, mod in ipairs(binding.modifiers) do
            if type(mod) ~= "string" or not ({ cmd=true, alt=true, ctrl=true, shift=true, fn=true })[mod] then
                fail(p .. ".modifiers contains an unsupported modifier")
            end
            mods[#mods + 1] = mod
        end
        table.sort(mods)
        local signature = table.concat(mods, "+") .. ":" .. binding.key:lower()
        if seen[signature] then fail("duplicate shortcut: " .. signature) end
        seen[signature] = true
    end
end

local ok, validationError = pcall(validate)
if not ok then
    hs.alert.show(tostring(validationError), 5)
    error(validationError, 0)
end

local busy = false
local hotkeys = {}
local appWatcher
local activeTask

local function alert(message)
    hs.alert.show(message, config.alertDuration)
end

local function resolveApplication()
    return hs.application.get(config.resolveAppName)
end

local function resolveIsFrontmost()
    local app = resolveApplication()
    local frontmost = hs.application.frontmostApplication()
    return app ~= nil and frontmost ~= nil and app:pid() == frontmost:pid()
end

local function updateHotkeys()
    local enabled = not busy and (not config.requireResolveFrontmost or resolveIsFrontmost())
    for _, hotkey in ipairs(hotkeys) do
        if enabled then hotkey:enable() else hotkey:disable() end
    end
end

local pythonCode = [=[
import json, os, sys
payload = json.loads(sys.argv[1])
extra = payload.get("pythonPathExtra")
if extra:
    sys.path.insert(0, extra)
try:
    import DaVinciResolveScript as dvr
except Exception as exc:
    raise RuntimeError("Could not import DaVinciResolveScript: " + str(exc))
resolve = dvr.scriptapp("Resolve")
if not resolve:
    raise RuntimeError("Could not connect to DaVinci Resolve. Enable external scripting access in Resolve preferences.")
try:
    preset_ok = resolve.LoadKeyboardPreset(payload["preset"])
    page_ok = resolve.OpenPage(payload["page"])
    active_preset = resolve.GetCurrentKeyboardPreset()
except Exception as exc:
    raise RuntimeError("Resolve scripting API call failed: " + str(exc))
if not preset_ok:
    raise RuntimeError("Resolve rejected keyboard preset: " + payload["preset"])
if not page_ok:
    raise RuntimeError("Resolve rejected page: " + payload["page"])
if active_preset != payload["preset"]:
    raise RuntimeError("Preset verification failed; active preset is " + str(active_preset))
print("OK: " + payload["preset"] + " / " + payload["page"])
]=]

local function switch(binding)
    if busy then return end
    if config.requireResolveFrontmost and not resolveIsFrontmost() then return end
    if not resolveApplication() then
        alert("DaVinci Resolve is not running")
        return
    end

    busy = true
    updateHotkeys()
    local payload = {
        preset = binding.preset,
        page = binding.page,
        pythonPathExtra = config.pythonPathExtra,
    }
    local encoded = hs.json.encode(payload)
    if type(encoded) ~= "string" then
        busy = false
        updateHotkeys()
        alert("Could not encode API request")
        return
    end
    local created, taskOrError = pcall(hs.task.new, config.pythonPath, function(exitCode, stdOut, stdErr)
        busy = false
        activeTask = nil
        updateHotkeys()
        if exitCode == 0 then
            alert((binding.label or binding.page) .. " page · " .. binding.preset)
        else
            local detail = (stdErr and stdErr ~= "" and stdErr) or (stdOut and stdOut ~= "" and stdOut) or "Unknown error"
            alert("Resolve API error: " .. detail)
            print("Switcheroo API output:", stdOut or "")
            print("Switcheroo API error:", stdErr or "")
        end
    end, { "-c", pythonCode, encoded })
    if not created or not taskOrError then
        busy = false
        activeTask = nil
        updateHotkeys()
        alert("Could not create the Resolve Python task: " .. tostring(taskOrError or "unknown error"))
        return
    end

    activeTask = taskOrError
    local started, startResult = pcall(function() return activeTask:start() end)
    if not started or not startResult then
        busy = false
        activeTask = nil
        updateHotkeys()
        alert("Could not start the configured Resolve Python runtime: " .. tostring(startResult or "unknown error"))
    end
end

for _, binding in ipairs(config.bindings) do
    local hotkey = hs.hotkey.bind(binding.modifiers, binding.key, function() switch(binding) end)
    if not hotkey then fail("Hammerspoon could not bind shortcut " .. binding.key) end
    hotkeys[#hotkeys + 1] = hotkey
end

appWatcher = hs.application.watcher.new(function() updateHotkeys() end)
appWatcher:start()
updateHotkeys()
alert("Switcheroo shortcuts loaded")
