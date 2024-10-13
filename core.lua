local AddonName, HealerHelper = ...
local MAXROW = 5
local MAX = 10
local ActionButtonCastType = {
    Cast = 1,
    Channel = 2,
    Empowered = 3,
}

function HealerHelper:DoAfterCombat(callback, from, ...)
    local args = {...}
    if InCombatLockdown() then
        C_Timer.After(
            0.1,
            function()
                HealerHelper:DoAfterCombat(callback, from, unpack(args))
            end
        )

        return
    end

    callback(unpack(args))
end

function HealerHelper:GetOptionValue(name)
    HEAHELPC = HEAHELPC or {}
    if IsInRaid() then return HEAHELPC["R" .. name] end

    return HEAHELPC[name]
end

function HealerHelper:SetOptionValue(name, val)
    HEAHELPC = HEAHELPC or {}
    if IsInRaid() then
        HEAHELPC["R" .. name] = val

        return
    end

    HEAHELPC[name] = val
end

local healerHelper = CreateFrame("Frame")
healerHelper:RegisterEvent("ADDON_LOADED")
healerHelper:SetScript(
    "OnEvent",
    function(sel, event, addonName)
        if addonName ~= AddonName then return end
        HEAHELPC = HEAHELPC or {}
        HEAHELPC["LAYOUT"] = HEAHELPC["LAYOUT"] or "BOTTOM"
        HEAHELPC["GAPX"] = HEAHELPC["GAPX"] or 6
        HEAHELPC["GAPY"] = HEAHELPC["GAPY"] or 6
        HEAHELPC["OFFSET"] = HEAHELPC["OFFSET"] or 2
        HEAHELPC["RLAYOUT"] = HEAHELPC["RLAYOUT"] or "BOTTOM"
        HEAHELPC["RGAPX"] = HEAHELPC["RGAPX"] or 4
        HEAHELPC["RGAPY"] = HEAHELPC["RGAPY"] or 4
        HEAHELPC["ROFFSET"] = HEAHELPC["ROFFSET"] or 0
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
            if IsInRaid() then
                if CompactRaidFrameContainer.flowOrientation == "vertical" then
                    return "DOWN"
                else
                    return "RIGHT"
                end
            elseif IsInGroup() then
                local sw, sh = CompactPartyFrame:GetSize()
                if sw > sh then
                    return "RIGHT"
                else
                    return "DOWN"
                end
            end

            return "FAILED"
        end

        local function UpdateFramePosition(frame, i, group)
            if InCombatLockdown() then
                C_Timer.After(
                    0.1,
                    function()
                        UpdateFramePosition(frame, i, group)
                    end
                )

                return
            end

            if frame:GetName() and (string.match(frame:GetName(), "CompactRaidFrame") or string.match(frame:GetName(), "CompactPartyFrameMember") or string.match(frame:GetName(), "CompactRaidGroup")) then
                local bar = _G["HealerHelper_BAR_" .. frame:GetName()]
                if bar then
                    if HealerHelper:GetOptionValue("LAYOUT") == "BOTTOM" then
                        if bar then
                            bar:ClearAllPoints()
                            bar:SetPoint("TOP", frame, "BOTTOM", 0, -HealerHelper:GetOptionValue("OFFSET"))
                        end
                    elseif HealerHelper:GetOptionValue("LAYOUT") == "RIGHT" then
                        if bar then
                            bar:ClearAllPoints()
                            bar:SetPoint("LEFT", frame, "RIGHT", HealerHelper:GetOptionValue("OFFSET"), 0)
                        end
                    else
                        HealerHelper:MSG("MISSING LAYOUT", HealerHelper:GetOptionValue("LAYOUT"))
                    end

                    local direction = FindDirection()
                    local spacingY = 0
                    local spacingX = 0
                    local y = i % 5
                    if y == 0 then
                        y = 5
                    end

                    local previousFrame = nil
                    if string.match(frame:GetName(), "CompactPartyFrameMember") then
                        previousFrame = _G["CompactPartyFrameMember" .. (i - 1)]
                    elseif string.match(frame:GetName(), "CompactRaidFrame") then
                        previousFrame = _G["CompactRaidFrame" .. (i - 1)]
                    elseif string.match(frame:GetName(), "CompactRaidGroup") then
                        previousFrame = _G["CompactRaidGroup" .. group .. "Member" .. (i - 1)]
                    end

                    if y == 1 then
                        previousFrame = _G["CompactRaidFrame" .. (i - 5)]
                        if previousFrame == nil and group ~= nil then
                            previousFrame = _G["CompactRaidGroup" .. (group - 1) .. "Member1"]
                        end

                        if previousFrame then
                            frame:ClearAllPoints()
                            if direction == "DOWN" then
                                if HealerHelper:GetOptionValue("LAYOUT") == "RIGHT" then
                                    frame:SetPoint("LEFT", previousFrame, "RIGHT", bar:GetWidth() + HealerHelper:GetOptionValue("GAPX") + HealerHelper:GetOptionValue("OFFSET"), 0)
                                else
                                    frame:SetPoint("TOP", previousFrame, "TOP", bar:GetWidth() + HealerHelper:GetOptionValue("GAPX") + HealerHelper:GetOptionValue("OFFSET"), 0)
                                end
                            else
                                if HealerHelper:GetOptionValue("LAYOUT") == "RIGHT" then
                                    frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -HealerHelper:GetOptionValue("GAPY"))
                                else
                                    frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -(bar:GetHeight() + HealerHelper:GetOptionValue("GAPY") + HealerHelper:GetOptionValue("OFFSET")))
                                end
                            end
                        end
                    else
                        if previousFrame then
                            frame:ClearAllPoints()
                            if direction == "DOWN" then
                                if HealerHelper:GetOptionValue("LAYOUT") == "RIGHT" and direction == "DOWN" then
                                    spacingY = HealerHelper:GetOptionValue("GAPY")
                                elseif HealerHelper:GetOptionValue("LAYOUT") == "BOTTOM" and direction == "DOWN" then
                                    spacingY = bar:GetHeight() * bar:GetScale() + HealerHelper:GetOptionValue("GAPY") + HealerHelper:GetOptionValue("OFFSET")
                                end

                                frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -spacingY)
                            else
                                if HealerHelper:GetOptionValue("LAYOUT") == "RIGHT" and direction == "RIGHT" then
                                    spacingX = bar:GetWidth() * bar:GetScale() + HealerHelper:GetOptionValue("GAPX") + HealerHelper:GetOptionValue("OFFSET")
                                elseif HealerHelper:GetOptionValue("LAYOUT") == "BOTTOM" and direction == "RIGHT" then
                                    spacingX = HealerHelper:GetOptionValue("GAPX")
                                end

                                frame:SetPoint("LEFT", previousFrame, "RIGHT", spacingX, spacingY)
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
            if IsInRaid() then
                for i = 1, MAX_RAID_MEMBERS do
                    local frame = _G["CompactRaidFrame" .. i]
                    if frame then
                        UpdateFramePosition(frame, i)
                    else
                        local group = math.ceil(i / 5)
                        local member = i % 5
                        if member == 0 then
                            member = 5
                        end

                        local frame2 = _G["CompactRaidGroup" .. group .. "Member" .. member]
                        if frame2 then
                            UpdateFramePosition(frame2, member, group)
                        end
                    end
                end
            else
                for i = 1, MEMBERS_PER_RAID_GROUP do
                    local frame = _G["CompactPartyFrameMember" .. i]
                    if frame then
                        UpdateFramePosition(frame, i)
                    end
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

        HealerHelper:MSG(string.format("LOADED v%s", "0.4.0"))
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
        function(sel, w)
            HealerHelper:DoAfterCombat(
                function(sw)
                    bar:SetSize(sw, sw / MAXROW * 2)
                    local scale = sw / (customButton:GetWidth() * MAXROW)
                    customButton:SetScale(scale)
                    HealerHelper:HandleBtn(bar, customButton, i)
                end, "UnitFrame -> SetWidth", w
            )
        end
    )

    hooksecurefunc(
        frame,
        "SetSize",
        function(sel, w, h)
            HealerHelper:DoAfterCombat(
                function(sw, sh)
                    bar:SetSize(sw, sw / MAXROW * 2)
                    local scale = sw / (customButton:GetWidth() * MAXROW)
                    customButton:SetScale(scale)
                    HealerHelper:HandleBtn(bar, customButton, i)
                end, "UnitFrame -> SetSize", w, h
            )
        end
    )

    if HealerHelper:GetOptionValue("spell" .. i) ~= nil then
        HealerHelper:SetSpell(customButton, HealerHelper:GetOptionValue("spell" .. i))
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
                HealerHelper:SetOptionValue("spell" .. i, spellID)
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
                local spellName = HealerHelper:GetOptionValue("spell" .. i)
                if spellName then
                    HealerHelper:SetOptionValue("spell" .. i, nil)
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
        if DEBUG then
            bar.t = bar:CreateTexture()
            bar.t:SetColorTexture(1, 0, 0)
            bar.t:SetAllPoints(bar)
        end

        for i = 1, MAX do
            HealerHelper:AddActionButton(frame, bar, i)
        end
    end
end
