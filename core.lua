local AddonName, HealerHelper = ...
local ActionButtonCastType = {
    Cast = 1,
    Channel = 2,
    Empowered = 3,
}

local actionbuttons = {}
local healBars = {}
function HealerHelper:RegisterEvent(frame, event, unit)
    if C_EventUtils.IsEventValid(event) then
        if unit then
            frame:RegisterUnitEvent(event, "player")
        else
            frame:RegisterEvent(event)
        end
    end
end

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
        if i <= 5 and HealerHelper:AddUnitFrame("CompactPartyFrameMember" .. i) then
            c = c + 1
        end

        if i <= 8 then
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
local runAfterCombat = CreateFrame("Frame")
HealerHelper:RegisterEvent(runAfterCombat, "PLAYER_REGEN_ENABLED")
runAfterCombat:SetScript(
    "OnEvent",
    function(sel, event)
        if event == "" then
            for from, tab in pairs(callbacks) do
                local callback = tab.callback
                local args = tab.args
                callback(unpack(args))
            end

            callbacks = {}
        end
    end
)

function HealerHelper:TryRunSecure(callback, frames, from, ...)
    if frames == nil then
        HealerHelper:MSG("[TryRunSecure] Missing frame for args", ...)

        return
    end

    if from == nil then
        HealerHelper:MSG("[TryRunSecure] Missing name for args", ...)

        return
    end

    local args = {...}
    if InCombatLockdown() then
        for i, frame in pairs(frames) do
            if frame:IsProtected() then
                callbacks[from] = {
                    callback = callback,
                    args = {...}
                }

                return
            end
        end
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

local test = false
local currentlyUpdating = {}
local function AddUpdateFramePosition(fra, nr, gro)
    if currentlyUpdating[fra] then return end
    currentlyUpdating[fra] = true
    HealerHelper:TryRunSecure(
        function(frame, i, group)
            local bar = _G["HealerHelper_BAR_" .. frame:GetName()]
            if frame ~= nil and HealerHelper:IsAllowed(frame) and bar then
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
                    else
                        local p1, p2, p3, p4, p5 = frame:GetPoint()
                        frame:ClearAllPoints()
                        frame:SetPoint(p1, p2, p3, p4, p5)
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

            currentlyUpdating[frame] = nil
        end, {fra}, "AddUpdateFramePosition", fra, nr, gro
    )
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

local previousGroupSize = 0
function HealerHelper:CheckForNewFrames()
    local c = HealerHelper:UpdateAllowedUnitFrames()
    if c > 0 then
        for frame, name in pairs(unitFrames) do
            if frame ~= nil and healBars[frame] == nil then
                healBars[frame] = true
                HealerHelper:AddIcons(frame)
                HealerHelper:AddTexts(frame)
                HealerHelper:AddHealbar(frame)
            end
        end
    end
end

function HealerHelper:UpdateStateBtn(i, btn)
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

        if btn:GetAttribute("ROWS") ~= HealerHelper:GetOptionValue("ROWS", 2) then
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

function HealerHelper:UpdateStates()
    for i, btns in pairs(actionbuttons) do
        for x, btn in pairs(btns) do
            if not InCombatLockdown() then
                HealerHelper:UpdateStateBtn(i, btn)
            end
        end
    end
end

function HealerHelper:UpdateRaidTargets()
    for frame, name in pairs(unitFrames) do
        local targetIcon = frame["HH_TargetingIcon"]
        if targetIcon then
            targetIcon.func(frame, targetIcon)
        end
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
            HealerHelper:UpdateRaidTargets()
        elseif event == "GROUP_ROSTER_UPDATE" or event == "UNIT_NAME_UPDATE" or event == "UNIT_CONNECTION" or event == "UNIT_LEVEL" then
            if event == "GROUP_ROSTER_UPDATE" then
                local currentGroupSize = GetNumGroupMembers()
                if currentGroupSize ~= previousGroupSize then
                    previousGroupSize = currentGroupSize
                    HealerHelper:CheckForNewFrames()
                end

                HealerHelper:UpdateRaidTargets()
                HealerHelper:UpdateHealBarsLayout()
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
            HealerHelper:MSG(string.format("LOADED v%s", "0.7.13"))
            C_Timer.After(
                4,
                function()
                    HealerHelper:CheckForNewFrames()
                    HealerHelper:UpdateRaidTargets()
                    HealerHelper:UpdateHealBarsLayout()
                end
            )
        end
    end
)

function HealerHelper:SetSpellForBtn(b, i)
    if b == nil then return end
    HealerHelper:TryRunSecure(
        function(btn, id)
            local _, _, iconTexture = HealerHelper:GetSpellInfo(id)
            if btn.icon then
                btn.icon:SetTexture(iconTexture)
            end

            btn:SetAttribute("spell", id)
            btn:SetAttribute("type", "spell")
            btn:SetAttribute("type1", "spell")
            btn:SetAttribute("spell1", id)
            if false then
                btn:SetAttribute("action", nil)
                btn:SetAttribute("action1", nil)
                btn:SetAttribute("action2", nil)
            end
        end, {b}, "SetSpellForBtn", b, i
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
            if btn.icon then
                btn.icon:SetTexture(nil)
            end

            btn:SetAttribute("spell", nil)
            btn:SetAttribute("type", nil)
            btn:SetAttribute("type1", nil)
            btn:SetAttribute("spell1", nil)
            if false then
                btn:SetAttribute("action", nil)
                btn:SetAttribute("action1", nil)
                btn:SetAttribute("action2", nil)
            end
        end, {b}, "ClearSpellForBtn", b
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
                elseif debuffType and HealerHelper:CanDispell(debuffType, spellID) then
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
            if spellID == 440313 then
                dispellableCount = dispellableCount + 1
                hasAffix = true
                debuffColor = HealerHelper:GetDebuffTypeColor(debuffType, spellID)
            elseif debuffType and HealerHelper:CanDispell(debuffType, spellID) then
                dispellableCount = dispellableCount + 1
                if not hasAffix then
                    debuffColor = HealerHelper:GetDebuffTypeColor(debuffType, spellID)
                end
            end
        end
    end

    return dispellableCount, debuffColor
end

local function HH_CooldownFrame_Set(cooldownFrame, start, duration, enable, showCooldownFrame)
    if enable and enable ~= 0 and duration > 0 then
        cooldownFrame:SetCooldown(start, duration)
        if showCooldownFrame then
            cooldownFrame:Show()
        end
    else
        cooldownFrame:Hide()
    end
end

local numChargeCooldowns = 0
local function HH_CreateChargeCooldownFrame(parent)
    numChargeCooldowns = numChargeCooldowns + 1
    local cooldown = CreateFrame("Cooldown", "ChargeCooldown" .. numChargeCooldowns, parent, "CooldownFrameTemplate")
    cooldown:SetHideCountdownNumbers(true)
    cooldown:SetDrawSwipe(false)
    local icon = parent.Icon or parent.icon
    cooldown:SetPoint("TOPLEFT", icon, "TOPLEFT", 2, -2)
    cooldown:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
    cooldown:SetFrameLevel(parent:GetFrameLevel())

    return cooldown
end

local function HH_StartChargeCooldown(frame, cooldownFrame, start, duration, chargeStart, chargeDuration, chargeMax, charges)
    cooldownFrame = cooldownFrame or HH_CreateChargeCooldownFrame(frame)
    if charges and charges < chargeMax then
        cooldownFrame:SetCooldown(chargeStart, chargeDuration)
        cooldownFrame:Show()
        if cooldownFrame.chargeText then
            cooldownFrame.chargeText:SetText(charges)
            cooldownFrame.chargeText:Show()
        end
    else
        cooldownFrame:Hide()
    end
end

local function HH_ClearChargeCooldown(frame, cooldownFrame)
    cooldownFrame = cooldownFrame or HH_CreateChargeCooldownFrame(frame)
    cooldownFrame:Hide()
    if cooldownFrame.chargeText then
        cooldownFrame.chargeText:Hide()
    end
end

local defaultCooldownInfo = {
    startTime = 0,
    duration = 0,
    isEnabled = false,
    modRate = 0
}

local defaultChargeInfo = {
    currentCharges = 0,
    maxCharges = 0,
    cooldownStartTime = 0,
    cooldownDuration = 0,
    chargeModRate = 0
}

local function HH_RETAIL_ActionButton_UpdateCooldown(self)
    local locStart, locDuration
    local start, duration, enable, charges, maxCharges, chargeStart, chargeDuration
    local modRate = 1.0
    local chargeModRate = 1.0
    local actionType, actionID = nil
    local auraData = nil
    local passiveCooldownSpellID = nil
    local onEquipPassiveSpellID = nil
    if onEquipPassiveSpellID then
        passiveCooldownSpellID = C_UnitAuras.GetCooldownAuraBySpellID(onEquipPassiveSpellID)
    elseif (actionType and actionType == "spell") and actionID then
        passiveCooldownSpellID = C_UnitAuras.GetCooldownAuraBySpellID(actionID)
    elseif self:GetAttribute("spell") then
        passiveCooldownSpellID = C_UnitAuras.GetCooldownAuraBySpellID(self:GetAttribute("spell"))
    end

    if passiveCooldownSpellID and passiveCooldownSpellID ~= 0 then
        auraData = C_UnitAuras.GetPlayerAuraBySpellID(passiveCooldownSpellID)
    end

    if auraData then
        local currentTime = GetTime()
        local timeUntilExpire = auraData.expirationTime - currentTime
        local howMuchTimeHasPassed = auraData.duration - timeUntilExpire
        locStart = currentTime - howMuchTimeHasPassed
        locDuration = auraData.expirationTime - currentTime
        start = currentTime - howMuchTimeHasPassed
        duration = auraData.duration
        modRate = auraData.timeMod
        charges = auraData.charges
        maxCharges = auraData.maxCharges
        chargeStart = currentTime * 0.001
        chargeDuration = duration * 0.001
        chargeModRate = modRate
        enable = 1
    elseif self:GetAttribute("spell") then
        locStart, locDuration = C_Spell.GetSpellLossOfControlCooldown(self:GetAttribute("spell"))
        local spellCooldownInfo = C_Spell.GetSpellCooldown(self:GetAttribute("spell")) or defaultCooldownInfo
        start, duration, enable, modRate = spellCooldownInfo.startTime, spellCooldownInfo.duration, spellCooldownInfo.isEnabled, spellCooldownInfo.modRate
        local chargeInfo = HealerHelper:GetSpellCharges(self:GetAttribute("spell")) or defaultChargeInfo
        charges, maxCharges, chargeStart, chargeDuration, chargeModRate = chargeInfo.currentCharges, chargeInfo.maxCharges, chargeInfo.cooldownStartTime, chargeInfo.cooldownDuration, chargeInfo.chargeModRate
    end

    if locStart and locDuration and start and duration then
        if (locStart + locDuration) > (start + duration) then
            if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_LOSS_OF_CONTROL then
                self.cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-LoC")
                self.cooldown:SetSwipeColor(0.17, 0, 0)
                self.cooldown:SetHideCountdownNumbers(true)
                self.cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL
            end

            HH_CooldownFrame_Set(self.cooldown, locStart, locDuration, true, true, modRate)
            HH_ClearChargeCooldown(self, self.chargeCooldown)
        else
            if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
                self.cooldown:SetEdgeTexture("Interface\\Cooldown\\UI-HUD-ActionBar-SecondaryCooldown")
                self.cooldown:SetSwipeColor(0, 0, 0)
                self.cooldown:SetHideCountdownNumbers(false)
                self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
            end

            if charges and maxCharges and maxCharges > 1 and charges < maxCharges then
                HH_StartChargeCooldown(self, self.chargeCooldown, chargeStart, chargeDuration, chargeModRate)
            else
                HH_ClearChargeCooldown(self, self.chargeCooldown)
            end

            HH_CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate)
        end
    end
end

local function HH_ActionButton_UpdateCooldown(self)
    local start, duration, enable, charges, maxCharges, chargeStart, chargeDuration
    local modRate = 1.0
    local chargeModRate = 1.0
    if self:GetAttribute("spell") then
        start, duration, enable, modRate = GetSpellCooldown(self:GetAttribute("spell"))
        charges, maxCharges, chargeStart, chargeDuration, chargeModRate = HealerHelper:GetSpellCharges(self:GetAttribute("spell"))
    end

    if self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL then
        self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge")
        self.cooldown:SetSwipeColor(0, 0, 0)
        self.cooldown:SetHideCountdownNumbers(false)
        self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
    end

    if charges and maxCharges and maxCharges > 1 and charges < maxCharges then
        HH_StartChargeCooldown(self, self.chargeCooldown, chargeStart, chargeDuration, chargeModRate)
    else
        HH_ClearChargeCooldown(self, self.chargeCooldown)
    end

    HH_CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate)
end

function HealerHelper:SetupGlow(button)
    if not button.glow then
        local glow = button:CreateTexture(nil, "OVERLAY")
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        glow:SetBlendMode("ADD")
        glow:SetPoint("CENTER", button, "CENTER", 0, 0)
        glow:SetWidth(button:GetWidth() * 1.7)
        glow:SetHeight(button:GetHeight() * 1.7)
        local animationGroup = glow:CreateAnimationGroup()
        local fadeOut = animationGroup:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0.5)
        fadeOut:SetDuration(0.6)
        fadeOut:SetSmoothing("IN_OUT")
        fadeOut:SetOrder(1)
        local fadeIn = animationGroup:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0.5)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.6)
        fadeIn:SetSmoothing("IN_OUT")
        fadeIn:SetOrder(2)
        animationGroup:SetLooping("REPEAT")
        animationGroup:Play()
        button.glow = glow
        button.animationGroup = animationGroup
    end
end

function HealerHelper:Glow(button)
    HealerHelper:SetupGlow(button)
    button.glow:Show()
end

function HealerHelper:Unglow(button)
    HealerHelper:SetupGlow(button)
    button.glow:Hide()
end

local registered = {}
function HealerHelper:AddActionButton(frame, bar, i)
    local name = bar:GetName()
    if name == nil then return end
    local customButton = CreateFrame("CheckButton", name .. "_BTN_" .. i, bar, "HealerHelperActionButtonTemplate")
    customButton:UnregisterAllEvents()
    local customButtonEvents = CreateFrame("Frame", name .. "Events_BTN_" .. i)
    if customButton.Count == nil then
        customButton.Count = customButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        customButton.Count:SetPoint("BOTTOMRIGHT", customButton, "BOTTOMRIGHT", -2, 2)
        customButton.Count:SetTextColor(1, 1, 1, 1)
    end

    if customButton.cooldown == nil then
        customButton.cooldown = CreateFrame("Cooldown", nil, customButton, "CooldownFrameTemplate")
        customButton.cooldown:SetAllPoints(customButton)
    end

    customButton:SetAttribute("HEAHEL_bar", bar)
    HealerHelper:UpdateStateBtn(i, customButton)
    registered[customButton] = false
    function customButton:RegisterEvents()
        registered[customButton] = true
        customButton:UnregisterAllEvents()
        customButtonEvents:UnregisterAllEvents()
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_INTERRUPTED", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_SUCCEEDED", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_FAILED", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_START", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_STOP", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_CHANNEL_START", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_CHANNEL_STOP", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_RETICLE_TARGET", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_RETICLE_CLEAR", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_EMPOWER_START", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_EMPOWER_STOP", "player")
        HealerHelper:RegisterEvent(customButtonEvents, "UNIT_SPELLCAST_SENT")
        HealerHelper:RegisterEvent(customButtonEvents, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
        HealerHelper:RegisterEvent(customButtonEvents, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
        HealerHelper:RegisterEvent(customButtonEvents, "SPELL_UPDATE_ICON")
        HealerHelper:RegisterEvent(customButtonEvents, "SPELL_UPDATE_CHARGES")
        HealerHelper:RegisterEvent(customButtonEvents, "ACTIONBAR_UPDATE_STATE")
        HealerHelper:RegisterEvent(customButtonEvents, "ACTIONBAR_UPDATE_COOLDOWN")
    end

    if customButton.SpellCastAnimFrame then
        customButton.SpellCastAnimFrame:SetScript("OnHide", function() end)
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
                    customButtonEvents:UnregisterAllEvents()
                end
            end
        end
    )

    function customButton:UpdateCount()
        if self.Count == nil then return end
        local text = self.Count
        if self:GetAttribute("spell") == nil then
            text:SetText("")

            return
        end

        local info = HealerHelper:GetSpellCharges(self:GetAttribute("spell"))
        if info and info.currentCharges ~= nil and info.maxCharges ~= nil then
            if info.maxCharges > 1 then
                text:SetText(info.currentCharges)
            else
                text:SetText("")
            end
        elseif HealerHelper:GetSpellCastCount(self:GetAttribute("spell")) and HealerHelper:GetSpellCastCount(self:GetAttribute("spell")) > 0 then
            text:SetText(HealerHelper:GetSpellCastCount(self:GetAttribute("spell")))
        else
            text:SetText("")
        end
    end

    function customButton:PlaySpellCastAnim(actionButtonCastType)
        if self.cooldown then
            self.cooldown:SetSwipeColor(0, 0, 0, 0)
        end

        self.hideCooldownFrame = true
        self:ClearInterruptDisplay()
        self:ClearReticle()
        if self.SpellCastAnimFrame then
            self.SpellCastAnimFrame:Setup(actionButtonCastType)
        end

        self.actionButtonCastType = actionButtonCastType
    end

    function customButton:ClearReticle()
        if self.TargetReticleAnimFrame and self.TargetReticleAnimFrame:IsShown() then
            self.TargetReticleAnimFrame:Hide()
        end
    end

    function customButton:ClearInterruptDisplay()
        if self.InterruptDisplay and self.InterruptDisplay:IsShown() then
            self.InterruptDisplay:Hide()
        end
    end

    function customButton:PlayTargettingReticleAnim()
        if self.InterruptDisplay and self.InterruptDisplay:IsShown() then
            self.InterruptDisplay:Hide()
        end

        if self.TargetReticleAnimFrame then
            self.TargetReticleAnimFrame:Setup()
        end
    end

    function customButton:StopTargettingReticleAnim()
        if self.TargetReticleAnimFrame and self.TargetReticleAnimFrame:IsShown() then
            self.TargetReticleAnimFrame:Hide()
        end
    end

    function customButton:StopSpellCastAnim(forceStop, actionButtonCastType)
        self:StopTargettingReticleAnim()
        if self.actionButtonCastType == actionButtonCastType then
            if self.SpellCastAnimFrame then
                if forceStop then
                    self.SpellCastAnimFrame:Hide()
                elseif self.SpellCastAnimFrame.Fill.CastingAnim:IsPlaying() then
                    self.SpellCastAnimFrame:FinishAnimAndPlayBurst()
                end
            end

            self.actionButtonCastType = nil
        end
    end

    function customButton:PlaySpellInterruptedAnim()
        self:StopSpellCastAnim(true, self.actionButtonCastType)
        if self.InterruptDisplay and self.InterruptDisplay:IsShown() then
            self.InterruptDisplay:Hide()
        end

        if self.InterruptDisplay then
            self.InterruptDisplay:Show()
        end
    end

    customButton:SetScript("OnLoad", function(sel) end)
    customButton:SetScript("OnShow", function(sel) end)
    customButton:SetScript("OnHide", function(sel) end)
    customButton:SetScript("OnEnter", function(sel) end)
    customButton:SetScript("OnLeave", function(sel) end)
    customButtonEvents:SetScript(
        "OnEvent",
        function(sel, event, ...)
            if not frame:IsShown() or not customButton:IsShown() then return end
            if frame:GetParent() and not frame:GetParent():IsShown() then return end
            local spellID = select(3, ...)
            if spellID == customButton:GetAttribute("spell") or spellID == nil then
                if event == "ACTIONBAR_UPDATE_COOLDOWN" then
                    if customButton:GetAttribute("spell") then
                        if HealerHelper:GetWoWBuild() == "RETAIL" then
                            HH_RETAIL_ActionButton_UpdateCooldown(customButton)
                        else
                            HH_ActionButton_UpdateCooldown(customButton)
                        end
                    end
                elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
                    spellID = select(1, ...)
                    if (spellID == customButton:GetAttribute("spell") or (spellID == 462603 and customButton:GetAttribute("spell") == 73920)) and ActionButton_ShowOverlayGlow then
                        HealerHelper:Glow(customButton)
                    end
                elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
                    spellID = select(1, ...)
                    if (spellID == customButton:GetAttribute("spell") or (spellID == 462603 and customButton:GetAttribute("spell") == 73920)) and ActionButton_HideOverlayGlow then
                        HealerHelper:Unglow(customButton)
                    end
                elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
                    customButton:PlaySpellInterruptedAnim()
                elseif event == "UNIT_SPELLCAST_START" then
                    customButton:PlaySpellCastAnim(ActionButtonCastType.Cast)
                elseif event == "UNIT_SPELLCAST_STOP" then
                    customButton:StopSpellCastAnim(true, ActionButtonCastType.Cast)
                    customButton:StopTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
                    customButton:StopSpellCastAnim(false, ActionButtonCastType.Cast)
                    customButton:StopTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_SENT" or event == "UNIT_SPELLCAST_FAILED" then
                    customButton:StopTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_EMPOWER_START" then
                    customButton:PlaySpellCastAnim(ActionButtonCastType.Empowered)
                elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
                    local _, _, _, castComplete = ...
                    local interrupted = not castComplete
                    if interrupted then
                        customButton:PlaySpellInterruptedAnim()
                    else
                        customButton:StopSpellCastAnim(interrupted, ActionButtonCastType.Empowered)
                    end
                elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
                    customButton:PlaySpellCastAnim(ActionButtonCastType.Channel)
                elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
                    customButton:StopSpellCastAnim(false, ActionButtonCastType.Channel)
                elseif event == "UNIT_SPELLCAST_RETICLE_TARGET" then
                    customButton:PlayTargettingReticleAnim()
                elseif event == "UNIT_SPELLCAST_RETICLE_CLEAR" then
                    customButton:StopTargettingReticleAnim()
                elseif event == "SPELL_UPDATE_CHARGES" then
                    customButton:UpdateCount()
                elseif event == "ACTIONBAR_UPDATE_STATE" then
                    customButton:UpdateCount()
                elseif event == "SPELL_UPDATE_ICON" then
                    local _, _, iconTexture = HealerHelper:GetSpellInfo(customButton:GetAttribute("spell"))
                    if customButton.icon then
                        customButton.icon:SetTexture(iconTexture)
                    end
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
            end, {customButton}, "AddActionButton", customButton, frame
        )
    end

    HealerHelper:TryRunSecure(
        function(btn, parent)
            btn:SetAttribute("ACTIONBUTTONPERROW", HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5))
            btn:SetAttribute("ROWS", HealerHelper:GetOptionValue("ROWS", 2))
            btn:SetAttribute("HEAHEL_bar", bar)
            if btn.SetFrameRef then
                btn:SetFrameRef("unitFrame", parent)
                btn:SetFrameRef("bar", bar)
                btn:SetFrameRef("HEAHEL_HIDDEN", parent)
            else
                HealerHelper:MSG("MISSING SetFrameRef")
            end

            btn:SetAttribute("i", i)
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
            frame:HookScript(
                "OnAttributeChanged",
                function(sel, nam, valu)
                    if sel == nil then return end
                    if InCombatLockdown() and sel:IsProtected() then return false end
                    if nam == "unit" then
                        customButton:SetAttribute("unit", valu)
                    end
                end
            )
        end, {customButton, frame, bar}, "SecureActionButtons", customButton, frame
    )

    local function UpdateDesign(sel)
        if InCombatLockdown() and bar:IsProtected() then return end
        local ACTIONBUTTONPERROW = HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5)
        local ROWS = HealerHelper:GetOptionValue("ROWS", 2)
        local sw = sel:GetWidth()
        bar:SetWidth(sw)
        bar:SetHeight(sw / ACTIONBUTTONPERROW * ROWS)
        local scale = sw / (customButton:GetWidth() * ACTIONBUTTONPERROW)
        local row = math.floor((i - 1) / ACTIONBUTTONPERROW)
        local col = (i - 1) % ACTIONBUTTONPERROW
        local xOffset = col * customButton:GetWidth()
        local yOffset = row * -customButton:GetHeight()
        if InCombatLockdown() and customButton:IsProtected() then return end
        customButton:SetScale(scale)
        customButton:ClearAllPoints()
        customButton:SetPoint("TOPLEFT", bar, "TOPLEFT", xOffset, yOffset)
    end

    UpdateDesign(frame)
    hooksecurefunc(
        frame,
        "SetPoint",
        function(sel)
            UpdateDesign(sel)
        end
    )

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
    if HealerHelper:GetWoWBuild() ~= "RETAIL" then
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
                end, {customButton}, "Charges Reposition", customButton
            )
        end
    end

    customButton:UpdateCount()
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
        local setP = false
        hooksecurefunc(
            unitFrame,
            "SetPoint",
            function()
                if setP then return end
                setP = true
                HealerHelper:UpdateHealBarsLayout()
                setP = false
            end
        )

        local bar = CreateFrame("Frame", "HealerHelper_BAR_" .. name, unitFrame, "SecureHandlerAttributeTemplate")
        bar:SetSize(10, 10)
        if HealerHelper:GetOptionValue("LAYOUT") == "BOTTOM" then
            if bar then
                bar:ClearAllPoints()
                bar:SetPoint("TOP", unitFrame, "BOTTOM", 0, -HealerHelper:GetOptionValue("OFFSET"))
            end
        elseif HealerHelper:GetOptionValue("LAYOUT") == "RIGHT" then
            if bar then
                bar:ClearAllPoints()
                bar:SetPoint("LEFT", unitFrame, "RIGHT", HealerHelper:GetOptionValue("OFFSET"), 0)
            end
        else
            HealerHelper:MSG("MISSING LAYOUT", HealerHelper:GetOptionValue("LAYOUT"))
        end

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
        -2,
        -8,
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
            end, 12, "BOTTOM", healthBar, "BOTTOM", 0, 2
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
            end, 12, "BOTTOM", healthBar, "BOTTOM", 0, 2
        )
    end
end
