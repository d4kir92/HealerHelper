local _, HealerHelper = ...
local MAXROW = 5
local MAX = 10
local LAYOUT = "BOTTOM" -- "BOTTOM", "RIGHT"
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
        HEAHEL = HEAHEL or {}
        HealerHelper:SetAddonOutput("HealerHelper", "134149")
        HealerHelper:SetVersion("HealerHelper", "134149", 0.1)
        local healBars = {}
        hooksecurefunc(
            "CompactUnitFrame_SetUpFrame",
            function(frame, func)
                if frame and frame:GetName() and healBars[frame] == nil then
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
    local _, _, iconTexture = HealerHelper:GetSpellInfo(id)
    btn.icon:SetTexture(iconTexture)
end

function HealerHelper:ClearSpell(btn)
    btn:SetAttribute("type1", nil)
    btn:SetAttribute("spell1", nil)
    btn.spellID = nil
    btn.heahel_icon = nil
    btn.icon:SetTexture(nil)
end

function HealerHelper:HandleBtn(unitFrame, btn, i)
    local btnsLength = btn:GetWidth() * MAXROW
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

function HealerHelper:AddActionButton(frame, bar, i)
    local name = frame:GetName()
    local customButton = CreateFrame("CheckButton", name .. "_HealerHelper_" .. i, frame, "SecureActionButtonTemplate, ActionButtonTemplate")
    customButton:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    customButton:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
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
        function(sel, event, val)
            if event == "UNIT_SPELLCAST_START" then
                sel:PlaySpellCastAnim(ActionButtonCastType.Cast)
            else
            end
        end
    )

    --[[customButton:SetAttribute("type", "spell")
    customButton:SetAttribute("action", nil)
    customButton:SetAttribute("action1", nil)]]
    customButton:RegisterForClicks("AnyUp", "AnyDown")
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

    customButton:SetAttribute("unit", frame.displayedUnit)
    HealerHelper:SetSpell(customButton, HEAHEL["spell" .. i])
    HealerHelper:HandleBtn(frame, customButton, i)
    local function OnReceiveDrag(sel)
        local cursorType, _, _, spellID = GetCursorInfo()
        if cursorType and cursorType == "spell" then
            HealerHelper:SetSpell(sel, spellID)
            HEAHEL["spell" .. i] = spellID
            ClearCursor()
        end
    end

    customButton:RegisterForDrag("LeftButton")
    customButton:RegisterForClicks("AnyUp", "AnyDown")
    customButton:SetScript("OnReceiveDrag", OnReceiveDrag)
    customButton:SetScript(
        "OnDragStart",
        function(sel)
            if not Settings.GetValue("lockActionBars") or IsModifiedClick("PICKUPACTION") then
                local spellName = sel:GetAttribute("spell1")
                if spellName then
                    C_Spell.PickupSpell(spellName)
                    HealerHelper:ClearSpell(sel)
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
