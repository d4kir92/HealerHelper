local AddonName, HealerHelper = ...
local MAXROW = 5
local MAX = 10
local ActionButtonCastType = {
    Cast = 1,
    Channel = 2,
    Empowered = 3,
}

local healerHelper = CreateFrame("Frame")
healerHelper:RegisterEvent("ADDON_LOADED")
healerHelper:SetScript(
    "OnEvent",
    function(sel, event, addonName)
        if addonName ~= AddonName then return end
        HEAHELPC = HEAHELPC or {}
        HEAHELPC["LAYOUT"] = HEAHELPC["LAYOUT"] or "BOTTOM"
        HEAHELPC["GAP"] = HEAHELPC["GAP"] or 6
        HEAHELPC["OFFSET"] = HEAHELPC["OFFSET"] or 2
        HEAHELPC["RLAYOUT"] = HEAHELPC["RLAYOUT"] or "BOTTOM"
        HEAHELPC["RGAP"] = HEAHELPC["RGAP"] or 6
        HEAHELPC["ROFFSET"] = HEAHELPC["ROFFSET"] or 2
        HealerHelper:SetAddonOutput("HealerHelper", "134149")
        HealerHelper:InitSettings()
        local healBars = {}
        hooksecurefunc(
            "CompactUnitFrame_SetUpFrame",
            function(frame, func)
                if frame and frame.GetName and healBars[frame] == nil then
                    healBars[frame] = true
                    HealerHelper:AddHealbar(frame)
                end
            end
        )

        local function FindDirection()
            if CompactPartyFrame then
                local sw, sh = CompactPartyFrame:GetSize()
                if sw > sh then
                    return "RIGHT"
                else
                    return "DOWN"
                end
            elseif CompactRaidFrame then
                local sw, sh = CompactRaidFrame:GetSize()
                if sw > sh then
                    return "RIGHT"
                else
                    return "DOWN"
                end
            else
                HealerHelper:MSG("[FindDirection] FAILED")
            end

            return "FAILED"
        end

        local function UpdateFramePosition(frame, i)
            if frame:GetName() and string.match(frame:GetName(), "CompactPartyFrameMember") then
                local bar = _G["HealerHelper_BAR_" .. frame:GetName()]
                if bar then
                    if HEAHELPC["LAYOUT"] == "BOTTOM" then
                        if bar then
                            bar:ClearAllPoints()
                            bar:SetPoint("TOP", frame, "BOTTOM", 0, -HEAHELPC["OFFSET"])
                        end
                    elseif HEAHELPC["LAYOUT"] == "RIGHT" then
                        if bar then
                            bar:ClearAllPoints()
                            bar:SetPoint("LEFT", frame, "RIGHT", HEAHELPC["OFFSET"], 0)
                        end
                    else
                        HealerHelper:MSG("MISSING LAYOUT", HEAHELPC["LAYOUT"])
                    end

                    local direction = FindDirection()
                    local spacingY = 0
                    local spacingX = 0
                    if i > 1 then
                        local previousFrame = _G["CompactPartyFrameMember" .. (i - 1)]
                        if previousFrame then
                            frame:ClearAllPoints()
                            if direction == "DOWN" then
                                if HEAHELPC["LAYOUT"] == "RIGHT" and direction == "DOWN" then
                                    spacingY = HEAHELPC["GAP"]
                                elseif HEAHELPC["LAYOUT"] == "BOTTOM" and direction == "DOWN" then
                                    spacingY = bar:GetHeight() * bar:GetScale() + HEAHELPC["GAP"] + HEAHELPC["OFFSET"]
                                end

                                frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -spacingY)
                            else
                                if HEAHELPC["LAYOUT"] == "RIGHT" and direction == "RIGHT" then
                                    spacingX = bar:GetWidth() * bar:GetScale() + HEAHELPC["GAP"] + HEAHELPC["OFFSET"]
                                elseif HEAHELPC["LAYOUT"] == "BOTTOM" and direction == "RIGHT" then
                                    spacingX = HEAHELPC["GAP"]
                                end

                                frame:SetPoint("LEFT", previousFrame, "RIGHT", spacingX, 0)
                            end
                        end
                    end
                end
            end
        end

        local test = false
        function HealerHelper:UpdateHealBarsLayout()
            if test then return end
            test = true
            for i = 1, MEMBERS_PER_RAID_GROUP do
                local frame = _G["CompactPartyFrameMember" .. i]
                if frame then
                    UpdateFramePosition(frame, i)
                end
            end

            test = false
        end

        hooksecurefunc(
            "CompactUnitFrame_UpdateAll",
            function()
                HealerHelper:UpdateHealBarsLayout()
            end
        )

        HealerHelper:MSG(string.format("LOADED v%s", "0.3.0"))
    end
)

function HealerHelper:SetSpell(btn, id)
    btn:SetAttribute("type1", "spell")
    btn:SetAttribute("spell1", id)
    btn.spellID = id
    btn.action = nil
    local _, _, iconTexture = HealerHelper:GetSpellInfo(id)
    btn.icon:SetTexture(iconTexture)
end

function HealerHelper:ClearSpell(btn)
    btn:SetAttribute("type1", nil)
    btn:SetAttribute("spell1", nil)
    btn.spellID = nil
    btn.action = 1
    btn.icon:SetTexture(nil)
end

function HealerHelper:HandleBtn(bar, btn, i)
    if not InCombatLockdown() then
        btn:ClearAllPoints()
        if i > MAXROW then
            btn:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1 - MAXROW) * btn:GetWidth(), -btn:GetHeight())
        else
            btn:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1) * btn:GetWidth(), 0)
        end
    end
end

function HealerHelper:AddActionButton(frame, bar, i)
    local name = bar.GetName and bar:GetName() or nil
    if name == nil then return end
    local customButton = CreateFrame("CheckButton", name .. "_BTN_" .. i, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
    customButton:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    customButton:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    customButton:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    function customButton:ClearReticle()
        if customButton.TargetReticleAnimFrame:IsShown() then
            customButton.TargetReticleAnimFrame:Hide()
        end
    end

    function customButton:ClearInterruptDisplay()
        if customButton.InterruptDisplay:IsShown() then
            customButton.InterruptDisplay:Hide()
        end
    end

    function customButton:PlaySpellCastAnim(actionButtonCastType)
        customButton.cooldown:SetSwipeColor(0, 0, 0, 0)
        customButton.hideCooldownFrame = true
        customButton:ClearInterruptDisplay()
        customButton:ClearReticle()
        customButton.SpellCastAnimFrame:Setup(actionButtonCastType)
        customButton.actionButtonCastType = actionButtonCastType
    end

    function customButton:StopSpellCastAnim(forceStop, actionButtonCastType)
        customButton:StopTargettingReticleAnim()
        if customButton.actionButtonCastType == actionButtonCastType then
            if forceStop then
                customButton.SpellCastAnimFrame:Hide()
            elseif customButton.SpellCastAnimFrame.Fill.CastingAnim:IsPlaying() then
                customButton.SpellCastAnimFrame:FinishAnimAndPlayBurst()
            end

            customButton.actionButtonCastType = nil
        end
    end

    function customButton:StopTargettingReticleAnim()
        if customButton.TargetReticleAnimFrame:IsShown() then
            customButton.TargetReticleAnimFrame:Hide()
        end
    end

    customButton:SetScript(
        "OnEvent",
        function(sel, event, val, guid, spellID)
            if spellID == customButton.spellID then
                if event == "UNIT_SPELLCAST_START" then
                    sel:PlaySpellCastAnim(ActionButtonCastType.Cast)
                elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
                    sel:PlaySpellCastAnim(ActionButtonCastType.Empowered)
                elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
                    sel:StopSpellCastAnim(false, ActionButtonCastType.Cast)
                    sel:StopTargettingReticleAnim()
                end
            end
        end
    )

    if not InCombatLockdown() then
        customButton:SetAttribute("type", "spell")
        customButton:SetAttribute("action", nil)
        customButton:SetAttribute("action1", nil)
        customButton:SetAttribute("unit", frame.displayedUnit or frame.unit)
        customButton:SetAttribute("ignoreModifiers", "true")
    else
        HealerHelper:MSG("[Failed] In Combat")
    end

    hooksecurefunc(
        frame,
        "SetAttribute",
        function(sel, key, val)
            if key == "unit" then
                customButton:SetAttribute("unit", val)
            end
        end
    )

    hooksecurefunc(
        frame,
        "SetWidth",
        function(sel, sw)
            bar:SetSize(sw, sw / MAXROW * 2)
            local scale = sw / (customButton:GetWidth() * MAXROW)
            customButton:SetScale(scale)
            HealerHelper:HandleBtn(bar, customButton, i)
        end
    )

    hooksecurefunc(
        frame,
        "SetSize",
        function(sel, sw, sh)
            bar:SetSize(sw, sw / MAXROW * 2)
            local scale = sw / (customButton:GetWidth() * MAXROW)
            customButton:SetScale(scale)
            HealerHelper:HandleBtn(bar, customButton, i)
        end
    )

    if HEAHELPC["spell" .. i] ~= nil then
        HealerHelper:SetSpell(customButton, HEAHELPC["spell" .. i])
    else
        HealerHelper:ClearSpell(customButton)
    end

    HealerHelper:HandleBtn(frame, customButton, i)
    customButton:RegisterForDrag("LeftButton")
    customButton:RegisterForClicks("AnyUp", "AnyDown")
    customButton:SetScript(
        "OnReceiveDrag",
        function(sel)
            local cursorType, _, _, spellID = GetCursorInfo()
            if cursorType and cursorType == "spell" then
                HEAHELPC["spell" .. i] = spellID
                HealerHelper:SetSpell(sel, spellID)
                ClearCursor()
            end
        end
    )

    customButton:SetScript(
        "OnDragStart",
        function(sel)
            if InCombatLockdown() then
                HealerHelper:MSG("[OnDragStart] You are in Combat")

                return
            end

            if not Settings.GetValue("lockActionBars") or IsModifiedClick("PICKUPACTION") then
                local spellName = HEAHELPC["spell" .. i]
                if spellName then
                    HEAHELPC["spell" .. i] = nil
                    HealerHelper:ClearSpell(sel)
                    C_Spell.PickupSpell(spellName)
                end
            end
        end
    )
end

function HealerHelper:AddHealbar(frame)
    if frame and frame:GetName() ~= nil then
        local bar = CreateFrame("Frame", "HealerHelper_BAR_" .. frame:GetName(), frame)
        bar:SetSize(10, 10)
        bar:SetPoint("CENTER", frame, "CENTER", 0, 0)
        --[[ bar.t = bar:CreateTexture()
        bar.t:SetColorTexture(1, 0, 0)
        bar.t:SetAllPoints(bar)]]
        for i = 1, MAX do
            HealerHelper:AddActionButton(frame, bar, i)
        end
    end
end
