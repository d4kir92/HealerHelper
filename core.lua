local AddonName, HealerHelper = ...
local ActionButtonCastType = {
    Cast = 1,
    Channel = 2,
    Empowered = 3,
}

local actionbuttons = {}
local healBars = {}
local HEAHEL_HIDDEN = CreateFrame("Frame", "HEAHEL_HIDDEN")
HEAHEL_HIDDEN:Hide()
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

local unitFrames = {}
function HealerHelper:AddUnitFrame(name)
    local uf = _G[name]
    if uf and unitFrames[uf] == nil then
        unitFrames[uf] = name

        return true
    end

    return false
end

function HealerHelper:UpdateAllowedUnitFrames()
    local c = 0
    for i = 1, 40 do
        if i <= 5 then
            if HealerHelper:AddUnitFrame("CompactPartyFrameMember" .. i) then
                c = c + 1
            end

            if HealerHelper:AddUnitFrame("CompactArenaFrameMember" .. i) then
                c = c + 1
            end

            for x = 1, 5 do
                if HealerHelper:AddUnitFrame("CompactRaidGroup" .. i .. "Member" .. x) then
                    c = c + 1
                end
            end
        end

        if HealerHelper:AddUnitFrame("CompactRaidFrame" .. i) then
            c = c + 1
        end
    end

    return c
end

function HealerHelper:IsAllowed(uf)
    return unitFrames[uf] ~= nil
end

local callbacks = {}
local runAfter = false
function HealerHelper:RunAfterCombat()
    if runAfter then return end
    runAfter = true
    if InCombatLockdown() then
        C_Timer.After(
            0.1,
            function()
                runAfter = false
                HealerHelper:RunAfterCombat()
            end
        )

        return
    end

    for from, tab in pairs(callbacks) do
        local callback = tab.callback
        local args = tab.args
        callback(unpack(args))
    end

    callbacks = {}
    C_Timer.After(
        0.5,
        function()
            runAfter = false
            HealerHelper:RunAfterCombat()
        end
    )
end

HealerHelper:RunAfterCombat()
function HealerHelper:TryRunSecure(callback, frame, from, ...)
    if frame == nil then
        HealerHelper:MSG("[TryRunSecure] Missing frame for args", ...)

        return
    end

    if from == nil then
        HealerHelper:MSG("[TryRunSecure] Missing name for args", ...)

        return
    end

    local args = {...}
    if InCombatLockdown() and frame:IsProtected() then
        callbacks[from] = {
            callback = callback,
            args = {...}
        }

        return
    end

    callback(unpack(args))
end

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

function HealerHelper:RegisterEvent(frame, event, unit)
    if C_EventUtils.IsEventValid(event) then
        if unit then
            frame:RegisterUnitEvent(event, "player")
        else
            frame:RegisterEvent(event)
        end
    else
        HealerHelper:MSG("Missing event", event, unit)
    end
end

local previousGroupSize = 0
local searchForNew = false
function HealerHelper:CheckForNewFrames(oldc)
    if searchForNew then return end
    searchForNew = true
    if oldc and oldc == 0 then
        HealerHelper:UpdateHealBarsLayout()
    end

    local c = oldc or HealerHelper:UpdateAllowedUnitFrames()
    if c > 0 or (oldc ~= nil and oldc > 0) then
        local i = 0
        for frame, name in pairs(unitFrames) do
            if frame ~= nil and healBars[frame] == nil then
                healBars[frame] = true
                HealerHelper:AddIcons(frame)
                HealerHelper:AddTexts(frame)
                HealerHelper:AddHealbar(frame)
                i = i + 1
                if i >= 15 then break end
            end
        end

        C_Timer.After(
            0.0,
            function()
                searchForNew = false
                if oldc then
                    HealerHelper:CheckForNewFrames(oldc - i)
                else
                    HealerHelper:CheckForNewFrames(c - i)
                end
            end
        )
    else
        C_Timer.After(
            1,
            function()
                searchForNew = false
                HealerHelper:CheckForNewFrames()
            end
        )
    end
end

local healerHelper = CreateFrame("Frame")
HealerHelper:RegisterEvent(healerHelper, "ADDON_LOADED")
HealerHelper:RegisterEvent(healerHelper, "GROUP_ROSTER_UPDATE")
HealerHelper:RegisterEvent(healerHelper, "UNIT_NAME_UPDATE")
HealerHelper:RegisterEvent(healerHelper, "UNIT_CONNECTION")
HealerHelper:RegisterEvent(healerHelper, "UNIT_LEVEL")
HealerHelper:RegisterEvent(healerHelper, "RAID_TARGET_UPDATE")
healerHelper:SetScript(
    "OnEvent",
    function(sel, event, ...)
        if event == "RAID_TARGET_UPDATE" then
            for frame, name in pairs(unitFrames) do
                local targetIcon = frame["HH_TargetingIcon"]
                if targetIcon then
                    targetIcon.func(frame, targetIcon)
                end
            end
        elseif event == "GROUP_ROSTER_UPDATE" or event == "UNIT_NAME_UPDATE" or event == "UNIT_CONNECTION" or event == "UNIT_LEVEL" then
            if event == "GROUP_ROSTER_UPDATE" then
                local currentGroupSize = GetNumGroupMembers()
                if currentGroupSize ~= previousGroupSize then
                    previousGroupSize = currentGroupSize
                    HealerHelper:CheckForNewFrames()
                end
            end

            for frame, name in pairs(unitFrames) do
                local stats = frame["HH_Stats"]
                local level = frame["HH_Level"]
                local leader = frame["HH_Leader"]
                local flag = frame["HH_Flag"]
                if stats then
                    stats.func(frame, stats)
                end

                if level then
                    level.func(frame, level)
                end

                if leader then
                    leader.func(frame, leader)
                end

                if flag then
                    flag.func(frame, flag)
                end
            end
        elseif event == "ADDON_LOADED" then
            if select(1, ...) ~= AddonName then return end
            HEAHELPC = HEAHELPC or {}
            HEAHELPC["LAYOUT"] = HEAHELPC["LAYOUT"] or "BOTTOM"
            HEAHELPC["GAPX"] = HEAHELPC["GAPX"] or 6
            HEAHELPC["GAPY"] = HEAHELPC["GAPY"] or 6
            HEAHELPC["OFFSET"] = HEAHELPC["OFFSET"] or 2
            HEAHELPC["RLAYOUT"] = HEAHELPC["RLAYOUT"] or "BOTTOM"
            HEAHELPC["RGAPX"] = HEAHELPC["RGAPX"] or 4
            HEAHELPC["RGAPY"] = HEAHELPC["RGAPY"] or 4
            HEAHELPC["ROFFSET"] = HEAHELPC["ROFFSET"] or 0
            HEAHELPC["ROWS"] = HEAHELPC["ROWS"] or 2
            HEAHELPC["ACTIONBUTTONPERROW"] = HEAHELPC["ACTIONBUTTONPERROW"] or 5
            HEAHELPC["RROWS"] = HEAHELPC["RROWS"] or 2
            HEAHELPC["RACTIONBUTTONPERROW"] = HEAHELPC["RACTIONBUTTONPERROW"] or 5
            HealerHelper:SetAddonOutput("HealerHelper", "134149")
            HealerHelper:InitSettings()
            HealerHelper:CheckForNewFrames()
            local test = false
            local currentlyUpdating = {}
            local function UpdateFramePosition(frame, i, group)
                if InCombatLockdown() and frame:IsProtected() then
                    C_Timer.After(
                        0.1,
                        function()
                            UpdateFramePosition(frame, i, group)
                        end
                    )

                    return
                end

                if frame ~= nil and HealerHelper:IsAllowed(frame) then
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

                currentlyUpdating[frame] = nil
            end

            local function AddUpdateFramePosition(frame, i, group)
                if currentlyUpdating[frame] then return end
                currentlyUpdating[frame] = true
                UpdateFramePosition(frame, i, group)
            end

            function HealerHelper:UpdateHealBarsLayout()
                if test then return end
                test = true
                if IsInRaid() then
                    local max = MAX_RAID_MEMBERS or 40
                    for i = 1, max do
                        local frame = _G["CompactRaidFrame" .. i]
                        if frame then
                            AddUpdateFramePosition(frame, i)
                        else
                            local group = math.ceil(i / 5)
                            local member = i % 5
                            if member == 0 then
                                member = 5
                            end

                            local frame2 = _G["CompactRaidGroup" .. group .. "Member" .. member]
                            if frame2 then
                                AddUpdateFramePosition(frame2, member, group)
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
                            AddUpdateFramePosition(frame, i)
                        else
                            break
                        end
                    end
                end

                HealerHelper:UpdateStates()
                test = false
            end

            HealerHelper:MSG(string.format("LOADED v%s", "0.7.0"))
        end
    end
)

function HealerHelper:SetSpellForBtn(b, i)
    if b == nil then return end
    HealerHelper:TryRunSecure(
        function(btn, id)
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("type1", "spell")
            btn:SetAttribute("spell", id)
            btn:SetAttribute("spell1", id)
            btn:SetAttribute("action", nil)
            btn:SetAttribute("action1", nil)
            btn:SetAttribute("action2", nil)
            if true then
                btn.action = nil
                btn.spellID = id
                local _, _, iconTexture = HealerHelper:GetSpellInfo(id)
                if btn.icon then
                    btn.icon:SetTexture(iconTexture)
                end
            end
        end, b, "SetSpellForBtn", b, i
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
    if b == nil then return end
    HealerHelper:TryRunSecure(
        function(btn)
            btn:SetAttribute("type", nil)
            btn:SetAttribute("type1", nil)
            btn:SetAttribute("spell", nil)
            btn:SetAttribute("spell1", nil)
            btn:SetAttribute("action", nil)
            btn:SetAttribute("action1", nil)
            btn:SetAttribute("action2", nil)
            if true then
                btn.action = nil
                btn.spellID = nil
            end

            if btn.icon then
                btn.icon:SetTexture(nil)
            end
        end, b, "ClearSpellForBtn", b
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

function HealerHelper:GetDispellableDebuffsCount(unit)
    if unit == nil then return 0 end
    local dispellableCount = 0
    local hasAffix = false
    local debuffColor = nil
    if AuraUtil.ForEachAura then
        AuraUtil.ForEachAura(
            unit,
            "HARMFUL",
            nil,
            function(name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
                if spellID == 440313 then
                    dispellableCount = dispellableCount + 1
                    hasAffix = true
                    debuffColor = HealerHelper:GetDebuffTypeColor(debuffType, spellID)
                elseif debuffType and HealerHelper:CanDispell(debuffType) then
                    dispellableCount = dispellableCount + 1
                    if not hasAffix then
                        debuffColor = HealerHelper:GetDebuffTypeColor(debuffType, spellID)
                    end
                end

                return false, nil
            end
        )
    else
        for i = 1, 99 do
            local _, _, _, debuffType, _, _, _, _, _, spellID = UnitAura(unit, i, "HARMFUL")
            -- AFFIX
            if spellID == 440313 then
                dispellableCount = dispellableCount + 1
                hasAffix = true
                debuffColor = HealerHelper:GetDebuffTypeColor(debuffType, spellID)
            elseif debuffType and HealerHelper:CanDispell(debuffType) then
                dispellableCount = dispellableCount + 1
                if not hasAffix then
                    debuffColor = HealerHelper:GetDebuffTypeColor(debuffType, spellID)
                end
            end
        end
    end

    return dispellableCount, debuffColor
end

function HealerHelper:UpdateStates()
    for i, btns in pairs(actionbuttons) do
        for x, btn in pairs(btns) do
            if not InCombatLockdown() then
                if i <= HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5) * HealerHelper:GetOptionValue("ROWS", 2) then
                    if btn:GetParent() ~= btn:GetAttribute("HEAHEL_bar") then
                        btn:SetAttribute("HEAHEL_ignore", false)
                        btn:Show()
                        btn:SetParent(btn:GetAttribute("HEAHEL_bar"))
                    end

                    if btn:GetAttribute("ACTIONBUTTONPERROW") ~= HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5) then
                        btn:SetAttribute("ACTIONBUTTONPERROW", HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5))
                        btn:SetAttribute("HEAHEL_changed", true)
                    end

                    if btn:GetAttribute("ROWS") ~= HealerHelper:GetOptionValue("ROWS", 5) then
                        btn:SetAttribute("ROWS", HealerHelper:GetOptionValue("ROWS", 2))
                        btn:SetAttribute("HEAHEL_changed", true)
                    end
                else
                    if btn:GetParent() ~= HEAHEL_HIDDEN then
                        btn:SetAttribute("HEAHEL_ignore", true)
                        btn:Hide()
                        btn:SetParent(HEAHEL_HIDDEN)
                    end
                end
            end
        end
    end
end

local registered = {}
function HealerHelper:AddActionButton(frame, bar, i)
    local name = bar:GetName()
    if name == nil then return end
    local customButton = CreateFrame("CheckButton", name .. "_BTN_" .. i, bar, "HealerHelperActionButtonTemplate")
    registered[customButton] = false
    function customButton:UpdateCount()
        local text = self.Count
        if self:GetAttribute("spell") == nil then
            text:SetText("")

            return
        end

        local info = C_Spell.GetSpellCharges(self:GetAttribute("spell"))
        if info and info.currentCharges ~= nil and info.maxCharges ~= nil then
            if info.maxCharges > 1 then
                text:SetText(info.currentCharges)
            else
                text:SetText("")
            end
        elseif C_Spell.GetSpellCastCount(self:GetAttribute("spell")) > 0 then
            text:SetText(C_Spell.GetSpellCastCount(self:GetAttribute("spell")))
        else
            text:SetText("")
        end
    end

    function customButton:RegisterEvents()
        registered[customButton] = true
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
        HealerHelper:RegisterEvent(customButton, "UNIT_SPELLCAST_SENT")
        HealerHelper:RegisterEvent(customButton, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
        HealerHelper:RegisterEvent(customButton, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
        HealerHelper:RegisterEvent(customButton, "SPELL_UPDATE_ICON")
        HealerHelper:RegisterEvent(customButton, "SPELL_UPDATE_CHARGES")
        HealerHelper:RegisterEvent(customButton, "ACTIONBAR_UPDATE_STATE")
        HealerHelper:RegisterEvent(customButton, "ACTIONBAR_UPDATE_COOLDOWN")
    end

    if registered[customButton] == false then
        customButton:RegisterEvents()
    end

    hooksecurefunc(
        customButton,
        "SetParent",
        function(sel, pa)
            if pa == bar then
                if registered[customButton] == false then
                    customButton:RegisterEvents()
                end
            else
                if registered[customButton] == true then
                    customButton:UnregisterAllEvents()
                end
            end
        end
    )

    function customButton:PlaySpellCastAnim(actionButtonCastType)
        self.cooldown:SetSwipeColor(0, 0, 0, 0)
        self.hideCooldownFrame = true
        self:ClearInterruptDisplay()
        self:ClearReticle()
        self.SpellCastAnimFrame:Setup(actionButtonCastType)
        self.actionButtonCastType = actionButtonCastType
    end

    function customButton:ClearReticle()
        if self.TargetReticleAnimFrame:IsShown() then
            self.TargetReticleAnimFrame:Hide()
        end
    end

    function customButton:ClearInterruptDisplay()
        if self.InterruptDisplay:IsShown() then
            self.InterruptDisplay:Hide()
        end
    end

    function customButton:PlayTargettingReticleAnim()
        if self.InterruptDisplay:IsShown() then
            self.InterruptDisplay:Hide()
        end

        self.TargetReticleAnimFrame:Setup()
    end

    function customButton:StopTargettingReticleAnim()
        if self.TargetReticleAnimFrame:IsShown() then
            self.TargetReticleAnimFrame:Hide()
        end
    end

    function customButton:StopSpellCastAnim(forceStop, actionButtonCastType)
        self:StopTargettingReticleAnim()
        if self.actionButtonCastType == actionButtonCastType then
            if forceStop then
                self.SpellCastAnimFrame:Hide()
            elseif self.SpellCastAnimFrame.Fill.CastingAnim:IsPlaying() then
                self.SpellCastAnimFrame:FinishAnimAndPlayBurst()
            end

            self.actionButtonCastType = nil
        end
    end

    function customButton:PlaySpellInterruptedAnim()
        self:StopSpellCastAnim(true, self.actionButtonCastType)
        --Hide if it's already showing to clear the anim. 
        if self.InterruptDisplay:IsShown() then
            self.InterruptDisplay:Hide()
        end

        self.InterruptDisplay:Show()
    end

    customButton:SetScript("OnLoad", function(sel) end)
    customButton:SetScript("OnShow", function(sel) end)
    customButton:SetScript("OnHide", function(sel) end)
    customButton:SetScript("OnEnter", function(sel) end)
    customButton:SetScript("OnLeave", function(sel) end)
    customButton:SetScript(
        "OnEvent",
        function(sel, event, ...)
            local spellID = select(3, ...)
            if spellID == customButton:GetAttribute("spell") or spellID == nil then
                if event == "ACTIONBAR_UPDATE_COOLDOWN" then
                    if customButton:GetAttribute("spell") then
                        ActionButton_UpdateCooldown(customButton)
                    end
                elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
                    spellID = select(1, ...)
                    if (spellID == customButton:GetAttribute("spell") or (spellID == 462603 and customButton:GetAttribute("spell") == 73920)) and ActionButton_ShowOverlayGlow then
                        ActionButton_ShowOverlayGlow(sel)
                    end
                elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
                    spellID = select(1, ...)
                    if (spellID == customButton:GetAttribute("spell") or (spellID == 462603 and customButton:GetAttribute("spell") == 73920)) and ActionButton_HideOverlayGlow then
                        ActionButton_HideOverlayGlow(sel)
                    end
                elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
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
                elseif event == "SPELL_UPDATE_ICON" then
                    local _, _, iconTexture = HealerHelper:GetSpellInfo(customButton:GetAttribute("spell"))
                    if customButton.icon then
                        customButton.icon:SetTexture(iconTexture)
                    end
                elseif event == "SPELL_UPDATE_CHARGES" then
                    customButton:UpdateCount()
                elseif event == "ACTIONBAR_UPDATE_STATE" then
                    customButton:UpdateCount()
                end
            end
        end
    )

    if customButton then
        HealerHelper:TryRunSecure(
            function(btn, parent)
                btn:SetAttribute("type", "spell")
                btn:SetAttribute("action", nil)
                btn:SetAttribute("action1", nil)
                btn:SetAttribute("action2", nil)
                btn:SetAttribute("ignoreModifiers", "true")
            end, customButton, "AddActionButton", customButton, frame
        )
    end

    if true then
        HealerHelper:TryRunSecure(
            function(btn, parent)
                btn:SetAttribute("ACTIONBUTTONPERROW", HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5))
                btn:SetAttribute("ROWS", HealerHelper:GetOptionValue("ROWS", 2))
                btn:SetAttribute("HEAHEL_bar", bar)
                btn:SetFrameRef("unitFrame", parent)
                btn:SetFrameRef("bar", bar)
                btn:SetAttribute("i", i)
                btn:SetFrameRef("HEAHEL_HIDDEN", parent)
                btn:SetAttribute("_onattributechanged", [[
                    if name == "state-unit" then                       
                        local unitFrame = self:GetFrameRef("unitFrame")
                        if unitFrame then
                            local unit = unitFrame:GetAttribute("unit")
                            self:SetAttribute("unit", unit)
                        end
                    end
                ]])
                RegisterStateDriver(btn, "unit", "[combat] none; [nocombat] party1")
                local ACTIONBUTTONPERROW = HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5)
                local ROWS = HealerHelper:GetOptionValue("ROWS", 5)
                local sw = parent:GetWidth()
                bar:SetWidth(sw)
                bar:SetHeight(sw / ACTIONBUTTONPERROW * ROWS)
                local scale = sw / (btn:GetWidth() * ACTIONBUTTONPERROW)
                btn:SetScale(scale)
                local row = math.floor((i - 1) / ACTIONBUTTONPERROW)
                local col = (i - 1) % ACTIONBUTTONPERROW
                local xOffset = col * btn:GetWidth()
                local yOffset = row * -btn:GetHeight()
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", bar, "TOPLEFT", xOffset, yOffset)
            end, customButton, "SecureActionButtons", customButton, frame
        )
    end

    if HealerHelper:GetOptionValue("spell" .. i) ~= nil then
        HealerHelper:SetSpell(customButton, HealerHelper:GetOptionValue("spell" .. i), i)
    else
        HealerHelper:ClearSpell(customButton, i)
    end

    customButton:RegisterForDrag("LeftButton")
    customButton:RegisterForClicks("AnyUp", "AnyDown")
    customButton:SetScript(
        "OnReceiveDrag",
        function(sel)
            local cursorType, _, _, spellID = GetCursorInfo()
            if cursorType and cursorType == "spell" then
                HealerHelper:SetOptionValue("spell" .. i, spellID)
                HealerHelper:SetSpell(sel, spellID, i)
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

    local textureScale = 0.048
    if customButton.NormalTexture then
        customButton.NormalTexture:SetScale(textureScale)
    end

    if customButton.HighlightTexture then
        customButton.HighlightTexture:SetScale(textureScale)
    end

    if customButton.CheckedTexture then
        customButton.CheckedTexture:SetScale(textureScale)
    end

    if customButton.PushedTexture then
        customButton.PushedTexture:SetScale(textureScale)
    end

    if customButton.SpellCastAnimFrame then
        customButton.SpellCastAnimFrame:SetScale(textureScale - 0.002)
    end

    if customButton.InterruptDisplay then
        customButton.InterruptDisplay:SetScale(textureScale - 0.002)
    end

    if customButton.InterruptDisplay then
        customButton.InterruptDisplay:SetScale(textureScale)
    end

    if customButton.SlotArt then
        customButton.SlotArt:SetScale(textureScale)
    end

    if customButton.SlotBackground then
        customButton.SlotBackground:SetScale(textureScale)
    end

    if customButton.Name then
        customButton.Name:SetScale(textureScale)
    end

    if customButton.IconMask then
        customButton.IconMask:SetScale(textureScale)
    end

    if customButton.TargetReticleAnimFrame then
        customButton.TargetReticleAnimFrame:SetScale(textureScale)
    end

    local cooldown = _G[customButton:GetName() .. "Cooldown"]
    if cooldown then
        cooldown:SetScale(textureScale)
    end

    if ActionButton_SetupOverlayGlow then
        ActionButton_SetupOverlayGlow(customButton)
    end

    if customButton.SpellActivationAlert and customButton.SpellActivationAlert.ProcLoopFlipbook then
        customButton.SpellActivationAlert.ProcLoopFlipbook:SetScale(textureScale)
        customButton.SpellActivationAlert.ProcStartFlipbook:SetScale(textureScale)
    end

    if customButton.Count then
        customButton.Count:SetScale(0.06)
        HealerHelper:TryRunSecure(
            function(btn)
                btn.Count:ClearAllPoints()
                btn.Count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            end, customButton, "Charges Reposition", customButton
        )
    end

    C_Timer.After(
        0,
        function()
            customButton:UpdateCount()
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

    local name = unitFrame:GetName()
    if name ~= nil then
        local bar = CreateFrame("Frame", "HealerHelper_BAR_" .. name, unitFrame, "SecureHandlerAttributeTemplate")
        bar:SetSize(10, 10)
        bar:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
        if HealerHelper.DEBUG then
            bar.t = bar:CreateTexture()
            bar.t:SetColorTexture(1, 0, 0)
            bar.t:SetAllPoints(bar)
        end

        for i = 1, 24 do
            HealerHelper:AddActionButton(unitFrame, bar, i)
        end
    end
end

function HealerHelper:AddIcon(frame, name, atlas, texture, p1, p2, p3, p4, p5, func)
    frame[name] = frame:CreateTexture(frame:GetName() .. "." .. name)
    local icon = frame[name]
    if atlas then
        icon:SetAtlas(atlas)
    elseif texture then
        icon:SetTexture(texture)
    end

    icon:SetSize(16, 16)
    icon:SetPoint(p1, p2, p3, p4, p5)
    icon.func = func
    func(frame, icon)
end

function HealerHelper:AddIcons(frame)
    if frame == nil then return end
    local name = frame:GetName()
    if name == nil then return end
    HealerHelper:AddIcon(
        frame,
        "HH_Leader",
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
        end, 0.5, 1.5
    )

    HealerHelper:AddIcon(
        frame,
        "HH_TargetingIcon",
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
        end, 0.2, 0.4
    )

    HealerHelper:AddIcon(
        frame,
        "HH_Flag",
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
        end, 1, 2
    )

    HealerHelper:AddDispellBorder(frame)
end

function HealerHelper:AddTextStr(frame, name, func, ts, p1, p2, p3, p4, p5)
    frame[name] = frame:CreateFontString(frame:GetName() .. "." .. name, "OVERLAY", "GameTooltipText")
    local t = frame[name]
    local f1, _, f3 = t:GetFont()
    t:SetFont(f1, ts, f3)
    t:SetPoint(p1, p2, p3, p4, p5)
    t.func = func
    func(frame, t)
end

function HealerHelper:AddTexts(frame)
    if frame == nil then return end
    local name = frame:GetName()
    if name == nil then return end
    local healthBar = _G[name .. "HealthBarBackground"]
    if healthBar then
        HealerHelper:AddTextStr(
            frame,
            "HH_Level",
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
            end, 12, "BOTTOM", healthBar, "BOTTOM", 0, 0, 1, 2
        )

        HealerHelper:AddTextStr(
            frame,
            "HH_Stats",
            function(parent, text)
                if IsInRaid() then
                    text:SetText("")

                    return
                end

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
                    else
                        text:SetText("")
                    end
                else
                    text:SetText("")
                end
            end, 12, "BOTTOM", healthBar, "BOTTOM", 0, 0, 1, 2
        )
    end
end
