-- Example configuration values for the `config` table at the top of init.lua.
-- Keep the executable path aligned with your Resolve installation.
local config = {
    resolveAppName = "DaVinci Resolve",
    pythonPath = "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Resources/ResolvePython/ResolvePython",
    pythonPathExtra = nil, -- Optional directory containing DaVinciResolveScript.py
    alertDuration = 2,
    requireResolveFrontmost = true,
    bindings = {
        { modifiers = {}, key = "F2", page = "edit", preset = "EditPreset", label = "Edit" },
        { modifiers = {}, key = "F3", page = "color", preset = "ColorPreset", label = "Color" },
        -- Example custom binding:
        -- { modifiers = { "ctrl", "alt" }, key = "1", page = "cut", preset = "My Cut Preset", label = "Cut" },
    },
}

return config
