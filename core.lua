local _, HealerHelper = ...
local MAXROW = 5
local MAX = 10
local LAYOUT = "RIGHT" -- "BOTTOM", "RIGHT"
local ActionButtonCastType = {
    Cast = 1,
    Channel = 2,
    Empowered = 3,
}

local healerHelper = CreateFrame("Frame")
healerHelper:RegisterEvent("PLAYER_LOGIN")
healerHelper:SetScript(
    "OnEvent",
    function(sel, ...)
        HEAHELPC = HEAHELPC or {}
        HealerHelper:SetAddonOutput("HealerHelper", "134149")
        HealerHelper:SetVersion("HealerHelper", "134149", 0.1)
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

        HealerHelper:MSG(string.format("LOADED v%s", 0.1))
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

function HealerHelper:HandleBtn(unitFrame, btn, i)
    local btnsLength = btn:GetWidth() * MAXROW
    if not InCombatLockdown() then
        btn:SetScale(unitFrame:GetWidth() / btnsLength)
        btn:ClearAllPoints()
        if LAYOUT == "RIGHT" then
            if i > MAXROW then
                btn:SetPoint("TOPLEFT", unitFrame, "TOPRIGHT", (i - 1 - MAXROW) * btn:GetWidth(), -btn:GetHeight())
            else
                btn:SetPoint("TOPLEFT", unitFrame, "TOPRIGHT", (i - 1) * btn:GetWidth(), 0)
            end
        elseif LAYOUT == "BOTTOM" then
            if i > MAXROW then
                btn:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", (i - 1 - MAXROW) * btn:GetWidth(), -btn:GetHeight())
            else
                btn:SetPoint("TOPLEFT", unitFrame, "BOTTOMLEFT", (i - 1) * btn:GetWidth(), 0)
            end
        else
            HealerHelper:MSG("Missing Layout", LAYOUT)
        end
    end
end

function HealerHelper:AddActionButton(frame, bar, i)
    local name = frame.GetName and frame:GetName() or nil
    if name == nil then return end
    local customButton = CreateFrame("CheckButton", name .. "_HealerHelper_" .. i, frame, "SecureActionButtonTemplate, ActionButtonTemplate")
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
        function()
            HealerHelper:HandleBtn(frame, customButton, i)
        end
    )

    hooksecurefunc(
        frame,
        "SetSize",
        function()
            HealerHelper:HandleBtn(frame, customButton, i)
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
                    print(spellName)
                    C_Spell.PickupSpell(spellName)
                end
            end
        end
    )
end

function HealerHelper:AddHealbar(frame)
    for i = 1, MAX do
        HealerHelper:AddActionButton(frame, bar, i)
    end
end
