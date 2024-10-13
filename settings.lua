local _, HealerHelper = ...
HealerHelper:AddTrans("enUS", "GENERAL", "General")
HealerHelper:AddTrans("enUS", "MMBTN", "Show Minimapbutton")
HealerHelper:AddTrans("enUS", "PARTY", "Party")
HealerHelper:AddTrans("enUS", "LAYOUT", "Party Layout")
HealerHelper:AddTrans("enUS", "GAPX", "Party Gap X: %s")
HealerHelper:AddTrans("enUS", "GAPY", "Party Gap Y: %s")
HealerHelper:AddTrans("enUS", "OFFSET", "Party Offset: %s")
HealerHelper:AddTrans("enUS", "RAID", "Raid")
HealerHelper:AddTrans("enUS", "RLAYOUT", "Raid Layout")
HealerHelper:AddTrans("enUS", "RGAPX", "Raid Gap X: %s")
HealerHelper:AddTrans("enUS", "RGAPY", "Raid Gap Y: %s")
HealerHelper:AddTrans("enUS", "ROFFSET", "Raid Offset: %s")
local heahel_settings = nil
function HealerHelper:ToggleSettings()
    if heahel_settings:IsShown() then
        heahel_settings:Hide()
    else
        heahel_settings:Show()
    end
end

function HealerHelper:InitSettings()
    HealerHelper:SetVersion("HealerHelper", "134149", "0.4.6")
    heahel_settings = HealerHelper:CreateFrame(
        {
            ["name"] = "HealerHelper",
            ["pTab"] = {"CENTER"},
            ["sw"] = 520,
            ["sh"] = 520,
            ["title"] = format("HealerHelper |T134149:16:16:0:0|t v|cff3FC7EB%s", "0.4.6")
        }
    )

    heahel_settings.SF = CreateFrame("ScrollFrame", "heahel_settings_SF", heahel_settings, "UIPanelScrollFrameTemplate")
    heahel_settings.SF:SetPoint("TOPLEFT", heahel_settings, 8, -26)
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
    HealerHelper:AppendDropdown(
        "LAYOUT",
        "BOTTOM",
        {
            ["BOTTOM"] = "BOTTOM",
            ["RIGHT"] = "RIGHT"
        },
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
    HealerHelper:AppendDropdown(
        "RLAYOUT",
        "BOTTOM",
        {
            ["BOTTOM"] = "BOTTOM",
            ["RIGHT"] = "RIGHT"
        },
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
            ["vTT"] = {{"HealerHelper |T134149:16:16:0:0|t", "v|cff3FC7EB0.4.62"}, {"Leftclick", "Toggle Settings"}},
            ["funcL"] = function()
                HealerHelper:ToggleSettings()
            end,
        }
    )

    if HealerHelper:GV(HEAHELPC, "MMBTN", HealerHelper:GetWoWBuild() ~= "RETAIL") then
        HealerHelper:ShowMMBtn("HealerHelper")
    else
        HealerHelper:HideMMBtn("HealerHelper")
    end
end
