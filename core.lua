local AddonName, HealerHelper = ...
local DEBUG = false
local ActionButtonCastType = {
    Cast = 1,
    Channel = 2,
    Empowered = 3,
}

local actionbuttons = {}
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
    end
end

function HealerHelper:UpdateAllowedUnitFrames()
    for i = 1, 40 do
        if i <= 5 then
            HealerHelper:AddUnitFrame("CompactPartyFrameMember" .. i)
            HealerHelper:AddUnitFrame("CompactArenaFrameMember" .. i)
            for x = 1, 5 do
                HealerHelper:AddUnitFrame("CompactRaidGroup" .. i .. "Member" .. x)
            end
        end

        HealerHelper:AddUnitFrame("CompactRaidFrame" .. i)
    end
end

function HealerHelper:IsAllowed(uf)
    return unitFrames[uf] ~= nil
end

local callbacks = {}
function HealerHelper:RunAfterCombat()
    if InCombatLockdown() then
        C_Timer.After(
            0.1,
            function()
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
        0.1,
        function()
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

local ignoreFrames = {}
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
        HEAHELPC["ROWS"] = HEAHELPC["ROWS"] or 2
        HEAHELPC["ACTIONBUTTONPERROW"] = HEAHELPC["ACTIONBUTTONPERROW"] or 5
        HEAHELPC["RROWS"] = HEAHELPC["RROWS"] or 2
        HEAHELPC["RACTIONBUTTONPERROW"] = HEAHELPC["RACTIONBUTTONPERROW"] or 5
        HealerHelper:SetAddonOutput("HealerHelper", "134149")
        HealerHelper:InitSettings()
        local healBars = {}
        hooksecurefunc(
            "CompactUnitFrame_SetUpFrame",
            function(frame, func)
                if ignoreFrames[frame] then return end
                if frame ~= nil and healBars[frame] == nil then
                    HealerHelper:UpdateAllowedUnitFrames()
                    if HealerHelper:IsAllowed(frame) then
                        healBars[frame] = true
                        HealerHelper:AddHealbar(frame)
                        HealerHelper:AddIcons(frame)
                        HealerHelper:AddTexts(frame)
                        HealerHelper:UpdateStates()
                    else
                        ignoreFrames[frame] = true
                    end
                end
            end
        )

        local function UpdateFramePosition(frame, i, group)
            if InCombatLockdown() then
                C_Timer.After(
                    0.3,
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

            HealerHelper:UpdateStates()
            test = false
        end

        hooksecurefunc(
            "CompactUnitFrame_UpdateAll",
            function()
                HealerHelper:UpdateHealBarsLayout()
            end
        )

        HealerHelper:MSG(string.format("LOADED v%s", "0.6.0"))
    end
)

function HealerHelper:SetSpellForBtn(b, i)
    if b == nil then return end
    HealerHelper:TryRunSecure(
        function(btn, id)
            btn:SetAttribute("type1", "spell")
            btn:SetAttribute("spell1", id)
            btn.spellID = id
            btn.action = nil
            local _, _, iconTexture = HealerHelper:GetSpellInfo(id)
            if btn.icon then
                btn.icon:SetTexture(iconTexture)
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
            btn:SetAttribute("type1", nil)
            btn:SetAttribute("spell1", nil)
            btn.spellID = nil
            btn.action = nil
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

function HealerHelper:RegisterEvent(frame, event, unit)
    if C_EventUtils.IsEventValid(event) then
        if unit then
            frame:RegisterUnitEvent(event, "player")
        else
            frame:RegisterEvent(event)
        end
    end
end

function HealerHelper:UpdateStates()
    for i, btns in pairs(actionbuttons) do
        for x, btn in pairs(btns) do
            if not InCombatLockdown() then
                if i <= HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5) * HealerHelper:GetOptionValue("ROWS", 2) then
                    btn:SetAttribute("HEAHEL_ignore", false)
                    btn:SetParent(btn:GetAttribute("HEAHEL_bar"))
                    if btn:GetAttribute("ACTIONBUTTONPERROW") ~= HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5) then
                        btn:SetAttribute("ACTIONBUTTONPERROW", HealerHelper:GetOptionValue("ACTIONBUTTONPERROW", 5))
                        btn:SetAttribute("HEAHEL_changed", true)
                    end

                    if btn:GetAttribute("ROWS") ~= HealerHelper:GetOptionValue("ROWS", 5) then
                        btn:SetAttribute("ROWS", HealerHelper:GetOptionValue("ROWS", 2))
                        btn:SetAttribute("HEAHEL_changed", true)
                    end
                else
                    btn:SetAttribute("HEAHEL_ignore", true)
                    btn:SetParent(HEAHEL_HIDDEN)
                end
            end
        end
    end
end

function HealerHelper:AddActionButton(frame, bar, i)
    local name = bar:GetName()
    if name == nil then return end
    local customButton = CreateFrame("CheckButton", name .. "_BTN_" .. i, bar, "HealerHelperActionButtonTemplate")
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
    HealerHelper:RegisterEvent(customButton, "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
    HealerHelper:RegisterEvent(customButton, "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
    HealerHelper:RegisterEvent(customButton, "SPELL_UPDATE_ICON")
    function customButton:UpdateCount()
        local text = self.Count
        if self.spellID == nil then
            text:SetText("")

            return
        end

        local info = C_Spell.GetSpellCharges(self.spellID)
        if info and info.currentCharges ~= nil and info.maxCharges ~= nil then
            if info.maxCharges > 1 then
                text:SetText(info.currentCharges)
            else
                text:SetText("")
            end
        elseif C_Spell.GetSpellCastCount(self.spellID) > 0 then
            text:SetText(C_Spell.GetSpellCastCount(self.spellID))
        else
            text:SetText("")
        end
    end

    customButton:HookScript(
        "OnUpdate",
        function(sel)
            if sel.spellID then
                local _, _, iconTexture = HealerHelper:GetSpellInfo(sel.spellID)
                if sel.icon then
                    sel.icon:SetTexture(iconTexture)
                end

                ActionButton_UpdateCooldown(sel)
            end

            sel:UpdateCount()
        end
    )

    customButton:SetScript(
        "OnEvent",
        function(sel, event, ...)
            local spellID = select(3, ...)
            if spellID == customButton.spellID or spellID == nil then
                if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
                    spellID = select(1, ...)
                    if spellID == customButton.spellID or (spellID == 462603 and customButton.spellID == 73920) then
                        ActionButton_ShowOverlayGlow(sel)
                    end
                elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
                    spellID = select(1, ...)
                    if spellID == customButton.spellID or (spellID == 462603 and customButton.spellID == 73920) then
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
                btn:SetAttribute("ignoreModifiers", "true")
            end, customButton, "AddActionButton", customButton, frame
        )
    end

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
                if self:GetAttribute("HEAHEL_ignore") then
                    return
                end
            
                if name == "state-unit" then
                    local unitFrame = self:GetFrameRef("unitFrame")
                    if unitFrame then
                        local unit = unitFrame:GetAttribute("unit")
                        self:SetAttribute("unit", unit)
                    end
                elseif name == "statehidden" then  
                    local unitFrame = self:GetFrameRef("unitFrame")                
                    if unitFrame and unitFrame:IsShown() then
                        local i = self:GetAttribute("i")
                        local p1, p2, p3, p4, p5 = unitFrame:GetPoint()
                        local sw = unitFrame:GetWidth()
                        local sh = unitFrame:GetHeight()                     
                        if self:GetAttribute("HEAHEL_changed") or sw ~= unitFrame:GetAttribute(i .. "sw") or sh ~= unitFrame:GetAttribute(i .. "sh") or p1 ~= unitFrame:GetAttribute(i .. "p1") or p2 ~= unitFrame:GetAttribute(i .. "p2") or p3 ~= unitFrame:GetAttribute(i .. "p3") or p4 ~= unitFrame:GetAttribute(i .. "p4") or p5 ~= unitFrame:GetAttribute(i .. "p5") then
                            self:SetAttribute("HEAHEL_changed", false)
                            unitFrame:SetAttribute(i .. "sw", sw)
                            unitFrame:SetAttribute(i .. "sh", sh)

                            unitFrame:SetAttribute(i .. "p1", p1)
                            unitFrame:SetAttribute(i .. "p2", p2)
                            unitFrame:SetAttribute(i .. "p3", p3)
                            unitFrame:SetAttribute(i .. "p4", p4)
                            unitFrame:SetAttribute(i .. "p5", p5)
                            
                            local bar = self:GetFrameRef("bar")
                            local ACTIONBUTTONPERROW = self:GetAttribute("ACTIONBUTTONPERROW")
                            local ROWS = self:GetAttribute("ROWS")

                            local sw, sh = unitFrame:GetWidth(), unitFrame:GetHeight()
                            bar:SetWidth(sw)
                            bar:SetHeight(sw / ACTIONBUTTONPERROW * ROWS)
                            local scale = sw / (self:GetWidth() * ACTIONBUTTONPERROW)
                            self:SetScale(scale)
                            local row = math.floor((i - 1) / ACTIONBUTTONPERROW)
                            local col = (i - 1) % ACTIONBUTTONPERROW
                            local xOffset = col * self:GetWidth()
                            local yOffset = row * -self:GetHeight()
                            self:ClearAllPoints()
                            self:SetPoint("TOPLEFT", bar, "TOPLEFT", xOffset, yOffset)
                        end
                    end
                end
            ]])
            --[[
             if i > ACTIONBUTTONPERROW then
                        self:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1 - ACTIONBUTTONPERROW) * self:GetWidth(), -self:GetHeight())
                    else
                        self:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1) * self:GetWidth(), 0)
                    end
            ]]
            RegisterStateDriver(btn, "unit", "[combat] none; [nocombat] party1")
            RegisterStateDriver(btn, "visibility", "show;hide")
        end, customButton, "SecureActionButtons", customButton, frame
    )

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

    if HealerHelper:GetOptionValue("spell" .. i) ~= nil then
        HealerHelper:SetSpell(customButton, HealerHelper:GetOptionValue("spell" .. i), i)
    else
        HealerHelper:ClearSpell(customButton, i)
    end

    customButton:UpdateCount()
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
        if DEBUG then
            bar.t = bar:CreateTexture()
            bar.t:SetColorTexture(1, 0, 0)
            bar.t:SetAllPoints(bar)
        end

        for i = 1, 100 do
            HealerHelper:AddActionButton(unitFrame, bar, i)
        end
    end
end

function HealerHelper:AddIcon(frame, atlas, texture, p1, p2, p3, p4, p5, func, updateDelay, updateDelayRaid)
    if updateDelay == nil then
        HealerHelper:MSG("[AddIcon] Missing updateDelay")

        return
    end

    if updateDelayRaid == nil then
        HealerHelper:MSG("[AddIcon] Missing updateDelayRaid")

        return
    end

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
        local delay = updateDelay
        if IsInRaid() then
            delay = updateDelayRaid
        end

        C_Timer.After(
            delay,
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
        end, 0.5, 1.5
    )

    local oldRaidTarget = nil
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
            if oldRaidTarget ~= GetRaidTargetIndex(parent.unit) then
                oldRaidTarget = GetRaidTargetIndex(parent.unit)
                if GetRaidTargetIndex(parent.unit) then
                    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. GetRaidTargetIndex(parent.unit))
                else
                    icon:SetTexture(nil)
                end
            end
        end, 0.2, 0.4
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
        end, 1, 2
    )

    HealerHelper:AddDispellBorder(frame)
end

function HealerHelper:AddTextStr(frame, func, ts, p1, p2, p3, p4, p5, updateDelay, updateDelayRaid)
    if updateDelay == nil then
        HealerHelper:MSG("[AddTextStr] Missing updateDelay")

        return
    end

    if updateDelayRaid == nil then
        HealerHelper:MSG("[AddTextStr] Missing updateDelayRaid")

        return
    end

    local t = frame:CreateFontString("_UnitLevel", "OVERLAY", "GameTooltipText")
    local f1, _, f3 = t:GetFont()
    t:SetFont(f1, ts, f3)
    t:SetPoint(p1, p2, p3, p4, p5)
    local function OnTextUpdate(parent, text)
        func(parent, text)
        local delay = updateDelay
        if IsInRaid() then
            delay = updateDelayRaid
        end

        C_Timer.After(
            delay,
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
            end, 12, "BOTTOM", healthBar, "BOTTOM", 0, 0, 1, 2
        )

        HealerHelper:AddTextStr(
            frame,
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
