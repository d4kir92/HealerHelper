local AddonName, HealerHelper = ...
local DEBUG = false
local MAXROW = 5
local MAX = 10
local ActionButtonCastType = {
    Cast = 1,
    Channel = 2,
    Empowered = 3,
}

local actionbuttons = {}
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

function HealerHelper:DoAfterCombat(callback, from, ...)
    local args = {...}
    if InCombatLockdown() then
        C_Timer.After(
            0.3,
            function()
                HealerHelper:DoAfterCombat(callback, from, unpack(args))
            end
        )

        return
    end

    callback(unpack(args))
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
                if frame ~= nil and healBars[frame] == nil then
                    healBars[frame] = true
                    HealerHelper:AddHealbar(frame)
                    HealerHelper:AddIcons(frame)
                    HealerHelper:AddTexts(frame)
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
                local frame = CompactPartyFrame
                if frame == nil then
                    frame = CompactRaidFrameContainer
                end

                local sw, sh = frame:GetSize()
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
                local max = MAX_RAID_MEMBERS or 40
                for i = 1, max do
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
                local max = MEMBERS_PER_RAID_GROUP or 5
                for i = 1, max do
                    local frame = _G["CompactPartyFrameMember" .. i]
                    if frame == nil then
                        frame = _G["CompactRaidFrame" .. i]
                    end

                    if frame then
                        UpdateFramePosition(frame, i)
                    else
                        break
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

        HealerHelper:MSG(string.format("LOADED v%s", "0.4.9"))
    end
)

function HealerHelper:SetSpellForBtn(b, i)
    HealerHelper:DoAfterCombat(
        function(btn, id)
            btn:SetAttribute("type1", "spell")
            btn:SetAttribute("spell1", id)
            btn.spellId = id
            btn.action = 1
            local _, _, iconTexture = HealerHelper:GetSpellInfo(id)
            btn.icon:SetTexture(iconTexture)
        end, "SetSpellForBtn", b, i
    )
end

function HealerHelper:SetSpell(btn, id, i)
    actionbuttons[i] = actionbuttons[i] or {}
    if not tContains(actionbuttons[i], btn) then
        tinsert(actionbuttons[i], btn)
    end

    for x, v in pairs(actionbuttons[i]) do
        HealerHelper:SetSpellForBtn(v, id)
    end
end

function HealerHelper:ClearSpellForBtn(b)
    HealerHelper:DoAfterCombat(
        function(btn)
            btn:SetAttribute("type1", nil)
            btn:SetAttribute("spell1", nil)
            btn.spellId = nil
            btn.action = 1
            btn.icon:SetTexture(nil)
        end, "ClearSpellForBtn", b
    )
end

function HealerHelper:ClearSpell(btn, i)
    actionbuttons[i] = actionbuttons[i] or {}
    if not tContains(actionbuttons[i], btn) then
        tinsert(actionbuttons[i], btn)
    end

    for x, v in pairs(actionbuttons[i]) do
        HealerHelper:ClearSpellForBtn(v)
    end
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

function HealerHelper:GetDispellableDebuffsCount(unit)
    if unit == nil then return 0 end
    local dispellableCount = 0
    if AuraUtil.ForEachAura then
        AuraUtil.ForEachAura(
            unit,
            "HARMFUL",
            nil,
            function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
                -- AFFIX
                if spellId == 440313 then
                    dispellableCount = dispellableCount + 1
                elseif debuffType == "Magic" or debuffType == "Curse" or debuffType == "Poison" or debuffType == "Disease" then
                    dispellableCount = dispellableCount + 1
                end

                return false
            end
        )
    else
        for i = 1, 99 do
            local _, _, _, debuffType, _, _, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
            -- AFFIX
            if spellId == 440313 then
                dispellableCount = dispellableCount + 1
            elseif debuffType == "Magic" or debuffType == "Curse" or debuffType == "Poison" or debuffType == "Disease" then
                dispellableCount = dispellableCount + 1
            end
        end
    end

    return dispellableCount
end

function HealerHelper:RegisterEvent(frame, event, unit)
    if C_EventUtils.IsEventValid(event) then
        if unit then
            frame:RegisterUnitEvent(event, "player")
        else
            frame:RegisterEvent(event)
        end
    end
end

function HealerHelper:AddActionButton(frame, bar, i)
    local name = bar:GetName()
    if name == nil then return end
    local customButton = CreateFrame("CheckButton", name .. "_BTN_" .. i, bar, "SecureActionButtonTemplate, ActionButtonTemplate")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_INTERRUPTED", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_SUCCEEDED", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_FAILED", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_START", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_STOP", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_CHANNEL_START", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_CHANNEL_STOP", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_RETICLE_TARGET", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_RETICLE_CLEAR", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_EMPOWER_START", "player")
    HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_EMPOWER_STOP", "player")
    function customButton:ClearReticle()
        if customButton.TargetReticleAnimFrame and customButton.TargetReticleAnimFrame:IsShown() then
            customButton.TargetReticleAnimFrame:Hide()
        end
    end

    function customButton:ClearInterruptDisplay()
        if customButton.InterruptDisplay and customButton.InterruptDisplay:IsShown() then
            customButton.InterruptDisplay:Hide()
        end
    end

    function customButton:PlaySpellCastAnim(actionButtonCastType)
        if customButton.cooldown then
            customButton.cooldown:SetSwipeColor(0, 0, 0, 0)
        end

        customButton.hideCooldownFrame = true
        customButton:ClearInterruptDisplay()
        customButton:ClearReticle()
        if customButton.SpellCastAnimFrame then
            customButton.SpellCastAnimFrame:Setup(actionButtonCastType)
        end

        customButton.actionButtonCastType = actionButtonCastType
    end

    function customButton:StopSpellCastAnim(forceStop, actionButtonCastType)
        customButton:StopTargettingReticleAnim()
        if customButton.actionButtonCastType == actionButtonCastType then
            if customButton.SpellCastAnimFrame then
                if forceStop then
                    customButton.SpellCastAnimFrame:Hide()
                elseif customButton.SpellCastAnimFrame.Fill.CastingAnim:IsPlaying() then
                    customButton.SpellCastAnimFrame:FinishAnimAndPlayBurst()
                end
            end

            customButton.actionButtonCastType = nil
        end
    end

    function customButton:StopTargettingReticleAnim()
        if customButton.TargetReticleAnimFrame and customButton.TargetReticleAnimFrame:IsShown() then
            customButton.TargetReticleAnimFrame:Hide()
        end
    end

    function customButton:PlaySpellInterruptedAnim()
        customButton:StopSpellCastAnim(true, customButton.actionButtonCastType)
        if customButton.InterruptDisplay then
            if customButton.InterruptDisplay:IsShown() then
                customButton.InterruptDisplay:Hide()
            end

            customButton.InterruptDisplay:Show()
        end
    end

    function ActionBarActionButtonMixin:PlayTargettingReticleAnim()
        if customButton.InterruptDisplay and customButton.InterruptDisplay:IsShown() then
            customButton.InterruptDisplay:Hide()
        end

        if customButton.TargetReticleAnimFrame then
            customButton.TargetReticleAnimFrame:Setup()
        end
    end

    customButton:SetScript(
        "OnEvent",
        function(sel, event, ...)
            local spellId = select(3, ...)
            if spellId == customButton.spellId then
                if event == "UNIT_SPELLCAST_INTERRUPTED" then
                    sel:PlaySpellInterruptedAnim()
                elseif event == "UNIT_SPELLCAST_START" then
                    sel:PlaySpellCastAnim(ActionButtonCastType.Cast)
                elseif event == "UNIT_SPELLCAST_STOP" then
                    sel:StopSpellCastAnim(true, ActionButtonCastType.Cast)
                    sel:StopTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
                    sel:StopSpellCastAnim(false, ActionButtonCastType.Cast)
                    sel:StopTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_SENT" or event == "UNIT_SPELLCAST_FAILED" then
                    sel:StopTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
                    sel:PlaySpellCastAnim(ActionButtonCastType.Empowered)
                elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
                    local _, _, _, castComplete = ...
                    local interrupted = not castComplete
                    if interrupted then
                        sel:PlaySpellInterruptedAnim()
                    else
                        sel:StopSpellCastAnim(interrupted, ActionButtonCastType.Empowered)
                    end
                elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
                    sel:PlaySpellCastAnim(ActionButtonCastType.Channel)
                elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
                    sel:StopSpellCastAnim(false, ActionButtonCastType.Channel)
                elseif event == "UNIT_SPELLCAST_RETICLE_TARGET" then
                    sel:PlayTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_RETICLE_CLEAR" then
                    sel:StopTargettingReticleAnim()
                end
            end
        end
    )

    HealerHelper:DoAfterCombat(
        function(btn, parent)
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("action", nil)
            btn:SetAttribute("action1", nil)
            btn:SetAttribute("unit", parent.displayedUnit or parent.unit)
            btn:SetAttribute("ignoreModifiers", "true")
        end, "AddActionButton", customButton, frame
    )

    hooksecurefunc(
        frame,
        "SetAttribute",
        function(sel, key, val)
            if key == "unit" then
                HealerHelper:DoAfterCombat(
                    function(v)
                        customButton:SetAttribute("unit", v)
                    end, "UnitFrame -> SetAttribute", val
                )
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
        HealerHelper:SetSpell(customButton, HealerHelper:GetOptionValue("spell" .. i), i)
    else
        HealerHelper:ClearSpell(customButton, i)
    end

    HealerHelper:HandleBtn(frame, customButton, i)
    customButton:RegisterForDrag("LeftButton")
    customButton:RegisterForClicks("AnyUp", "AnyDown")
    customButton:SetScript(
        "OnReceiveDrag",
        function(sel)
            local cursorType, _, _, spellId = GetCursorInfo()
            if cursorType and cursorType == "spell" then
                HealerHelper:SetOptionValue("spell" .. i, spellId)
                HealerHelper:SetSpell(sel, spellId, i)
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
                    HealerHelper:ClearSpell(sel, i)
                    C_Spell.PickupSpell(spellName)
                end
            end
        end
    )
end

function HealerHelper:AddHealbar(unitFrame)
    if unitFrame == nil then
        HealerHelper:MSG("Error: 'unitFrame' is nil")

        return
    end

    if type(unitFrame) ~= "table" then
        HealerHelper:MSG("Error: 'unitFrame' is not a valid frame object")

        return
    end

    if not unitFrame.GetName or unitFrame:GetName(unitFrame) == nil then return end
    local name = unitFrame:GetName()
    if name ~= nil then
        local bar = CreateFrame("Frame", "HealerHelper_BAR_" .. name, unitFrame)
        bar:SetSize(10, 10)
        bar:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
        if DEBUG then
            bar.t = bar:CreateTexture()
            bar.t:SetColorTexture(1, 0, 0)
            bar.t:SetAllPoints(bar)
        end

        for i = 1, MAX do
            HealerHelper:AddActionButton(unitFrame, bar, i)
        end
    end
end

function HealerHelper:AddDispellBorder(frame)
    local name = frame:GetName()
    if name == nil then return end
    local ActionBarButtonSpellActivationAlert = CreateFrame("Frame", "", frame)
    ActionBarButtonSpellActivationAlert:SetSize(150, 150)
    ActionBarButtonSpellActivationAlert:SetPoint("CENTER")
    local ProcStartFlipbook = ActionBarButtonSpellActivationAlert:CreateTexture(nil, "ARTWORK")
    ProcStartFlipbook:SetAtlas("UI-HUD-ActionBar-Proc-Start-Flipbook")
    ProcStartFlipbook:SetSize(150, 150)
    ProcStartFlipbook:SetPoint("CENTER")
    ProcStartFlipbook:SetAlpha(1)
    local ProcLoopFlipbook = ActionBarButtonSpellActivationAlert:CreateTexture(nil, "ARTWORK")
    ProcLoopFlipbook:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
    ProcLoopFlipbook:SetAllPoints()
    ProcLoopFlipbook:SetAlpha(0)
    local ProcLoop = ProcLoopFlipbook:CreateAnimationGroup()
    ProcLoop:SetLooping("REPEAT")
    local ProcLoopAlpha = ProcLoop:CreateAnimation("Alpha")
    ProcLoopAlpha:SetDuration(0.001)
    ProcLoopAlpha:SetFromAlpha(1)
    ProcLoopAlpha:SetToAlpha(1)
    local ProcLoopFlipAnim = ProcLoop:CreateAnimation("FlipBook")
    ProcLoopFlipAnim:SetDuration(1)
    ProcLoopFlipAnim:SetFlipBookRows(6)
    ProcLoopFlipAnim:SetFlipBookColumns(5)
    ProcLoopFlipAnim:SetFlipBookFrames(30)
    local ProcStartAnim = ProcStartFlipbook:CreateAnimationGroup()
    ProcStartAnim:SetToFinalAlpha(true)
    local ProcStartAlpha = ProcStartAnim:CreateAnimation("Alpha")
    ProcStartAlpha:SetDuration(0.001)
    ProcStartAlpha:SetFromAlpha(1)
    ProcStartAlpha:SetToAlpha(1)
    local ProcStartFlipAnim = ProcStartAnim:CreateAnimation("FlipBook")
    ProcStartFlipAnim:SetDuration(0.7)
    ProcStartFlipAnim:SetFlipBookRows(6)
    ProcStartFlipAnim:SetFlipBookColumns(5)
    ProcStartFlipAnim:SetFlipBookFrames(30)
    local ProcStartFadeOut = ProcStartAnim:CreateAnimation("Alpha")
    ProcStartFadeOut:SetDuration(0.001)
    ProcStartFadeOut:SetOrder(2)
    ProcStartFadeOut:SetFromAlpha(1)
    ProcStartFadeOut:SetToAlpha(0)
    ProcStartAnim:Play()
    ProcLoop:Play()
    local sw, sh = frame:GetSize()
    hooksecurefunc(
        frame,
        "SetSize",
        function(sel, w, h)
            ActionBarButtonSpellActivationAlert:SetSize(w * 1.6, h * 1.6)
        end
    )

    ActionBarButtonSpellActivationAlert:SetSize(sw * 1.6, sh * 1.6)
    ActionBarButtonSpellActivationAlert:Hide()
    local function OnDebuffDispellable()
        local c = HealerHelper:GetDispellableDebuffsCount(frame.unit)
        if ActionBarButtonSpellActivationAlert then
            if c > 0 then
                ActionBarButtonSpellActivationAlert:Show()
            else
                ActionBarButtonSpellActivationAlert:Hide()
            end
        end

        C_Timer.After(
            0.1,
            function()
                OnDebuffDispellable()
            end
        )
    end

    OnDebuffDispellable()

    return ActionBarButtonSpellActivationAlert
end

function HealerHelper:AddIcon(frame, atlas, texture, p1, p2, p3, p4, p5, func)
    local icon = frame:CreateTexture()
    if atlas then
        icon:SetAtlas(atlas)
    elseif texture then
        icon:SetTexture(texture)
    end

    icon:SetSize(16, 16)
    icon:SetPoint(p1, p2, p3, p4, p5)
    local function OnUpdateIcon(parent, ico)
        func(parent, ico)
        C_Timer.After(
            0.1,
            function()
                OnUpdateIcon(parent, ico)
            end
        )
    end

    OnUpdateIcon(frame, icon)
end

function HealerHelper:AddIcons(frame)
    if frame == nil then return end
    local name = frame:GetName()
    if name == nil then return end
    HealerHelper:AddIcon(
        frame,
        "UI-HUD-UnitFrame-Player-Group-LeaderIcon",
        nil,
        "BOTTOM",
        frame,
        "TOP",
        0,
        -5,
        function(parent, icon)
            if parent.unit == nil then return end
            if UnitIsGroupLeader(parent.unit) then
                icon:SetAlpha(1)
            else
                icon:SetAlpha(0)
            end
        end
    )

    HealerHelper:AddIcon(
        frame,
        nil,
        nil,
        "LEFT",
        frame,
        "LEFT",
        4,
        0,
        function(parent, icon)
            if parent.unit == nil then return end
            if GetRaidTargetIndex(parent.unit) then
                icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. GetRaidTargetIndex(parent.unit))
            else
                icon:SetTexture(nil)
            end
        end
    )

    HealerHelper:AddIcon(
        frame,
        nil,
        nil,
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        1,
        -7,
        function(parent, icon)
            if InCombatLockdown() then
                icon:SetTexture(nil)

                return
            end

            if parent.unit == nil then
                icon:SetTexture(nil)

                return
            end

            icon:SetSize(64, 32)
            icon:SetScale(0.34)
            if not UnitIsPlayer(parent.unit) then
                icon:SetTexture("Interface\\Addons\\HealerHelper\\media\\" .. "bot")

                return
            end

            local nam, realmName = UnitName(parent.unit)
            if nam == nil then return end
            if realmName == nil then
                realmName = GetRealmName()
            end

            local lang = nil
            if realmName then
                lang = HealerHelper:GetRealmFlag(realmName)
            end

            if lang then
                icon:SetTexture("Interface\\Addons\\HealerHelper\\media\\" .. lang)
            else
                icon:SetTexture(nil)
            end
        end
    )

    HealerHelper:AddDispellBorder(frame)
end

function HealerHelper:AddTextStr(frame, func, ts, p1, p2, p3, p4, p5)
    local t = frame:CreateFontString("_UnitLevel", "OVERLAY", "GameTooltipText")
    local f1, _, f3 = t:GetFont()
    t:SetFont(f1, ts, f3)
    t:SetPoint(p1, p2, p3, p4, p5)
    local function OnTextUpdate(parent, text)
        func(parent, text)
        C_Timer.After(
            0.1,
            function()
                OnTextUpdate(parent, text)
            end
        )
    end

    OnTextUpdate(frame, t)
end

function HealerHelper:AddTexts(frame)
    if frame == nil then return end
    local name = frame:GetName()
    if name == nil then return end
    local healthBar = _G[name .. "HealthBarBackground"]
    if healthBar then
        HealerHelper:AddTextStr(
            frame,
            function(parent, text)
                if InCombatLockdown() then
                    text:SetText("")

                    return
                end

                if parent.unit == nil then
                    text:SetText("")

                    return
                end

                local level = UnitLevel(parent.unit)
                if level == nil then
                    text:SetText("")

                    return
                end

                local t = level
                if UnitEffectiveLevel ~= nil and UnitEffectiveLevel(parent.unit) ~= UnitLevel(parent.unit) then
                    t = UnitEffectiveLevel(parent.unit) .. " (" .. UnitLevel(parent.unit) .. ")"
                end

                local max = 60
                if GetMaxLevelForPlayerExpansion then
                    max = GetMaxLevelForPlayerExpansion()
                end

                if level == max and (UnitEffectiveLevel == nil or UnitEffectiveLevel(parent.unit) == level) then
                    text:SetText("")

                    return
                else
                    text:SetText(t)
                end
            end, 12, "BOTTOM", healthBar, "BOTTOM", 0, 0
        )

        HealerHelper:AddTextStr(
            frame,
            function(parent, text)
                if InCombatLockdown() then
                    text:SetText("")

                    return
                end

                if parent.unit == nil then
                    text:SetText("")

                    return
                end

                if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary and C_PlayerInfo.GetPlayerMythicPlusRatingSummary(parent.unit) then
                    local score = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(parent.unit).currentSeasonScore
                    local max = 60
                    local level = UnitLevel(parent.unit)
                    if level == nil then
                        text:SetText("")

                        return
                    end

                    if GetMaxLevelForPlayerExpansion then
                        max = GetMaxLevelForPlayerExpansion()
                    end

                    if UnitLevel(parent.unit) == max and (UnitEffectiveLevel == nil or UnitEffectiveLevel(parent.unit) == level) then
                        text:SetText("M+: " .. score)
                    end
                end
            end, 12, "BOTTOM", healthBar, "BOTTOM", 0, 0
        )
    end
end
