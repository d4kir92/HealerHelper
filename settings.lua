local _, HealerHelper = ...
HealerHelper.DEBUG = false
local heahel_settings = nil
function HealerHelper:ToggleSettings()
    if heahel_settings:IsShown() then
        heahel_settings:Hide()
    else
        heahel_settings:Show()
    end
end

function HealerHelper:InitSettings()
    HealerHelper:SetVersion(134149, "0.7.46")
    heahel_settings = HealerHelper:CreateFrame(
        {
            ["name"] = "HealerHelper",
            ["pTab"] = {"CENTER"},
            ["sw"] = 520,
            ["sh"] = 520,
            ["title"] = format("|T134149:16:16:0:0|t H|cff3FC7EBealer|rH|cff3FC7EBelper|r v|cff3FC7EB%s", HealerHelper:GetVersion())
        }
    )

    heahel_settings.SF = CreateFrame("ScrollFrame", "heahel_settings_SF", heahel_settings, "UIPanelScrollFrameTemplate")
    heahel_settings.SF:SetPoint("TOPLEFT", heahel_settings, 10, -26)
    heahel_settings.SF:SetPoint("BOTTOMRIGHT", heahel_settings, -32, 8)
    heahel_settings.SC = CreateFrame("Frame", "heahel_settings_SC", heahel_settings.SF)
    heahel_settings.SC:SetSize(heahel_settings.SF:GetSize())
    heahel_settings.SC:SetPoint("TOPLEFT", heahel_settings.SF, "TOPLEFT", 0, 0)
    heahel_settings.SF:SetScrollChild(heahel_settings.SC)
    local y = 0
    HealerHelper:SetAppendY(y)
    HealerHelper:SetAppendParent(heahel_settings.SC)
    HealerHelper:SetAppendTab(HEAHELPC)
    HealerHelper:AppendCategory("GENERAL")
    HealerHelper:AppendCheckbox(
        "MMBTN",
        HealerHelper:GetWoWBuild() ~= "RETAIL",
        function(sel, val)
            if val then
                HealerHelper:ShowMMBtn("HealerHelper")
            else
                HealerHelper:HideMMBtn("HealerHelper")
            end
        end
    )

    HealerHelper:AppendCategory("PARTY")
    HealerHelper:AppendCheckbox(
        "LEVE",
        true,
        function()
            HealerHelper:UpdateLevels()
        end
    )

    HealerHelper:AppendCheckbox(
        "FLAG",
        true,
        function()
            HealerHelper:UpdateFlagStatus()
        end
    )

    HealerHelper:AppendSlider(
        "FLAGSCALE",
        1,
        0.6,
        2,
        0.1,
        1,
        function()
            HealerHelper:UpdateFlagStatus()
        end
    )

    HealerHelper:AppendDropdown(
        "LAYOUT",
        "BOTTOM",
        {
            ["BOTTOM"] = "BOTTOM",
            ["RIGHT"] = "RIGHT",
            ["LEFT"] = "LEFT",
        },
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "ACTIONBUTTONPERROW",
        5,
        2,
        6,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "ROWS",
        2,
        1,
        3,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "OFFSET",
        2,
        0,
        20,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "GAPX",
        6,
        0,
        20,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "GAPY",
        6,
        0,
        20,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendCategory("RAID")
    HealerHelper:AppendCheckbox("RLEVE", true)
    HealerHelper:AppendCheckbox("RFLAG", true)
    HealerHelper:AppendSlider(
        "RFLAGSCALE",
        1,
        0.6,
        2,
        0.1,
        1,
        function()
            HealerHelper:UpdateFlagStatus()
        end
    )

    HealerHelper:AppendDropdown(
        "RLAYOUT",
        "BOTTOM",
        {
            ["BOTTOM"] = "BOTTOM",
            ["RIGHT"] = "RIGHT",
            ["LEFT"] = "LEFT",
        },
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "RACTIONBUTTONPERROW",
        5,
        2,
        6,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "RROWS",
        2,
        1,
        3,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "ROFFSET",
        2,
        0,
        20,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "RGAPX",
        6,
        0,
        20,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AppendSlider(
        "RGAPY",
        6,
        0,
        20,
        1,
        0,
        function()
            HealerHelper:UpdateHealBarsLayout()
        end
    )

    HealerHelper:AddSlash("healerhelper", HealerHelper.ToggleSettings)
    HealerHelper:AddSlash("heahel", HealerHelper.ToggleSettings)
    HealerHelper:CreateMinimapButton(
        {
            ["name"] = "HealerHelper",
            ["icon"] = 134149,
            ["dbtab"] = HEAHELPC,
            ["vTT"] = {{"|T134149:16:16:0:0|t H|cff3FC7EBealer|rH|cff3FC7EBelper|r", "v|cff3FC7EB" .. HealerHelper:GetVersion()}, {HealerHelper:Trans("LID_LEFTCLICK"), HealerHelper:Trans("LID_OPENSETTINGS")}, {HealerHelper:Trans("LID_RIGHTCLICK"), HealerHelper:Trans("LID_HIDEMINIMAPBUTTON")}},
            ["funcL"] = function()
                HealerHelper:ToggleSettings()
            end,
            ["funcR"] = function()
                HealerHelper:HideMMBtn("HealerHelper")
            end,
            ["dbkey"] = "MMBTN"
        }
    )
end
