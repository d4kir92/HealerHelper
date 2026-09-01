local _, HealerHelper = ...
HealerHelper.DEBUG = false
local heahel_settings = nil
local DEFAULT_WIDTH = 520
local DEFAULT_HEIGHT = 520
local LAYOUTCHOICES = {
    {
        ["value"] = "BOTTOM",
        ["label"] = "LID_BOTTOM"
    },
    {
        ["value"] = "RIGHT",
        ["label"] = "LID_RIGHT"
    },
    {
        ["value"] = "LEFT",
        ["label"] = "LID_LEFT"
    },
}

function HealerHelper:GetConfig(key, value)
    HEAHELPC = HEAHELPC or {}
    if HEAHELPC[key] == nil then HEAHELPC[key] = value end
    return HEAHELPC[key]
end

function HealerHelper:ToggleSettings()
    if heahel_settings == nil then return end
    heahel_settings:Toggle()
end

local function GetCollapsed(key)
    if key == nil then return nil end
    if type(HEAHELPC) ~= "table" then return nil end
    if type(HEAHELPC["COLLAPSED"]) ~= "table" then return nil end
    return HEAHELPC["COLLAPSED"][key]
end

local function SetCollapsed(key, collapsed)
    if key == nil then return end
    if type(HEAHELPC) ~= "table" then return end
    if type(HEAHELPC["COLLAPSED"]) ~= "table" then HEAHELPC["COLLAPSED"] = {} end
    if collapsed then
        HEAHELPC["COLLAPSED"][key] = true
    else
        HEAHELPC["COLLAPSED"][key] = nil
    end
end

local function AddCategory(key, level, labelKey)
    heahel_settings:AddCategory({
        ["label"] = "LID_" .. (labelKey or key),
        ["key"] = key,
        ["search"] = key,
        ["level"] = level or 1
    })
end

local function AddCheckbox(key, value, func)
    heahel_settings:AddCheckbox({
        ["label"] = "LID_" .. key,
        ["search"] = key,
        ["value"] = HealerHelper:GetConfig(key, value),
        ["func"] = function(newValue)
            HEAHELPC[key] = newValue
            if func then func(newValue) end
        end
    })
end

local function AddSlider(key, value, min, max, step, decimals, func)
    heahel_settings:AddSlider({
        ["label"] = "LID_" .. key,
        ["search"] = key,
        ["value"] = HealerHelper:GetConfig(key, value),
        ["min"] = min,
        ["max"] = max,
        ["step"] = step,
        ["decimals"] = decimals,
        ["func"] = function(newValue)
            HEAHELPC[key] = newValue
            if func then func(newValue) end
        end
    })
end

local function AddDropdown(key, value, choices, func)
    heahel_settings:AddDropdown({
        ["label"] = "LID_" .. key,
        ["search"] = key,
        ["value"] = HealerHelper:GetConfig(key, value),
        ["choices"] = choices,
        ["func"] = function(newValue)
            HEAHELPC[key] = newValue
            if func then func(newValue) end
        end
    })
end

function HealerHelper:InitSettings()
    HealerHelper:SetVersion(134149, "0.8.0")
    HEAHELPC = HEAHELPC or {}
    heahel_settings = HealerHelper:CreateUIWindow({
        ["name"] = "HealerHelperSettings",
        ["pTab"] = {"CENTER"},
        ["width"] = HealerHelper:GetConfig("WINDOWWIDTH", DEFAULT_WIDTH),
        ["height"] = HealerHelper:GetConfig("WINDOWHEIGHT", DEFAULT_HEIGHT),
        ["minWidth"] = 360,
        ["minHeight"] = 240,
        ["onResize"] = function(width, height)
            HEAHELPC["WINDOWWIDTH"] = width
            HEAHELPC["WINDOWHEIGHT"] = height
        end,
        ["getCollapsed"] = function(key) return GetCollapsed(key) end,
        ["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
        ["title"] = format("|T134149:16:16:0:0|t HealerHelper v%s", HealerHelper:GetVersion())
    })

    heahel_settings:SuspendLayout()
    heahel_settings:AddSearch()
    AddCategory("GENERAL")
    AddCheckbox("MMBTN", HealerHelper:GetWoWBuild() ~= "RETAIL", function(value)
        if value then
            HealerHelper:ShowMMBtn("HealerHelper")
        else
            HealerHelper:HideMMBtn("HealerHelper")
        end
    end)

    AddCategory("PARTY")
    AddCategory("PARTYINDICATORS", 2, "CATINDICATORS")
    AddCheckbox("LEVE", true, function() HealerHelper:UpdateLevels() end)
    AddCheckbox("FLAG", true, function() HealerHelper:UpdateFlagStatus() end)
    AddSlider("FLAGSCALE", 1, 0.6, 2, 0.1, 1, function() HealerHelper:UpdateFlagStatus() end)
    AddCategory("PARTYACTIONBAR", 2, "CATACTIONBAR")
    AddDropdown("LAYOUT", "BOTTOM", LAYOUTCHOICES, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("ACTIONBUTTONPERROW", 5, 2, 6, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("ROWS", 2, 1, 3, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("OFFSET", 2, 0, 20, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("GAPX", 6, 0, 20, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("GAPY", 6, 0, 20, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddCategory("RAID")
    AddCategory("RAIDINDICATORS", 2, "CATINDICATORS")
    AddCheckbox("RLEVE", true, function() HealerHelper:UpdateLevels() end)
    AddCheckbox("RFLAG", true, function() HealerHelper:UpdateFlagStatus() end)
    AddSlider("RFLAGSCALE", 1, 0.6, 2, 0.1, 1, function() HealerHelper:UpdateFlagStatus() end)
    AddCategory("RAIDACTIONBAR", 2, "CATACTIONBAR")
    AddDropdown("RLAYOUT", "BOTTOM", LAYOUTCHOICES, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("RACTIONBUTTONPERROW", 5, 2, 6, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("RROWS", 2, 1, 3, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("ROFFSET", 2, 0, 20, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("RGAPX", 6, 0, 20, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    AddSlider("RGAPY", 6, 0, 20, 1, 0, function() HealerHelper:UpdateHealBarsLayout() end)
    heahel_settings:ResumeLayout()
    HealerHelper:AddSlash("healerhelper", HealerHelper.ToggleSettings)
    HealerHelper:AddSlash("heahel", HealerHelper.ToggleSettings)
    HealerHelper:CreateMinimapButton({
        ["name"] = "HealerHelper",
        ["icon"] = 134149,
        ["dbtab"] = HEAHELPC,
        ["vTT"] = {{"|T134149:16:16:0:0|t HealerHelper", "v" .. HealerHelper:GetVersion()}, {HealerHelper:Trans("LID_LEFTCLICK"), HealerHelper:Trans("LID_OPENSETTINGS")}, {HealerHelper:Trans("LID_RIGHTCLICK"), HealerHelper:Trans("LID_HIDEMINIMAPBUTTON")}},
        ["funcL"] = function() HealerHelper:ToggleSettings() end,
        ["funcR"] = function() HealerHelper:HideMMBtn("HealerHelper") end,
        ["dbkey"] = "MMBTN"
    })
end
