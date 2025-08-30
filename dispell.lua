local _, HealerHelper = ...
local spellSeismischesSchmettern = 424888
local debuffSeismischerNachhall = 424889
local dispells = {}
if HealerHelper:GetWoWBuild() == "RETAIL" then
    dispells["DEATHKNIGHT"] = {}
    dispells["DEMONHUNTER"] = {}
    dispells["DRUID"] = {
        [2782] = {"Curse", "Poison"},
        [88423] = {"Curse", "Poison", "Magic*"},
    }

    dispells["EVOKER"] = {
        [360823] = {"Magic", "Poison"},
        [374251] = {"Bleed", "Poison", "Curse", "Disease"},
    }

    dispells["MONK"] = {
        [115450] = {"Magic"},
        [115310] = {"Magic", "Poison", "Disease"},
        [122783] = {"Magic"},
    }

    dispells["PALADIN"] = {
        [213644] = {"Poison", "Disease"},
        [4987] = {"Poison", "Magic", "Disease"},
    }

    dispells["PRIESTER"] = {
        [527] = {"Magic", "Disease"},
        [32375] = {"Magic"},
    }

    dispells["MAGE"] = {
        [475] = {"Curse"},
    }

    dispells["SHAMAN"] = {
        [51886] = {"Curse"},
        [254420] = {"Magic", "Curse"},
        [210263] = {"Magic", "Curse"},
        [77130] = {"Magic", "Curse"},
    }

    dispells["WARRIOR"] = {}
    dispells["HUNTER"] = {}
    dispells["ROGUE"] = {}
    dispells["WARLOCK"] = {}
else
    dispells["DEATHKNIGHT"] = {}
    dispells["DRUID"] = {
        [2782] = {"Curse", "Poison"},
        [88423] = {"Curse", "Poison", "Magic*"},
    }

    dispells["PALADIN"] = {
        [213644] = {"Poison", "Disease"},
        [4987] = {"Poison", "Magic", "Disease"},
    }

    dispells["PRIESTER"] = {
        [527] = {"Magic", "Disease"},
        [32375] = {"Magic"},
    }

    dispells["MAGE"] = {
        [475] = {"Curse"},
    }

    dispells["SHAMAN"] = {
        [51886] = {"Curse"}
    }

    dispells["WARRIOR"] = {}
    dispells["HUNTER"] = {}
    dispells["ROGUE"] = {}
    dispells["WARLOCK"] = {}
end

function HealerHelper:AddDispellBorder(frame)
    local name = frame:GetName()
    if name == nil then return end
    local DebuffBorder = CreateFrame("Frame", "", frame)
    DebuffBorder:SetSize(150, 150)
    DebuffBorder:SetPoint("CENTER")
    local ProcLoopFlipbook = DebuffBorder:CreateTexture(nil, "ARTWORK")
    if HealerHelper:AtlasExists("UI-HUD-ActionBar-Proc-Loop-Flipbook") and ProcLoopFlipbook.SetAtlas then
        ProcLoopFlipbook:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
    else
        ProcLoopFlipbook:SetTexture("UI-HUD-ActionBar-Proc-Loop-Flipbook")
    end

    ProcLoopFlipbook:SetAllPoints()
    ProcLoopFlipbook:SetAlpha(0)
    local ProcLoop = ProcLoopFlipbook:CreateAnimationGroup()
    ProcLoop:SetLooping("REPEAT")
    local ProcLoopAlpha = ProcLoop:CreateAnimation("Alpha")
    ProcLoopAlpha:SetDuration(0.001)
    if ProcLoopAlpha.SetFromAlpha then
        ProcLoopAlpha:SetFromAlpha(1)
    end

    if ProcLoopAlpha.SetToAlpha then
        ProcLoopAlpha:SetToAlpha(1)
    end

    local ProcLoopFlipAnim = ProcLoop:CreateAnimation("FlipBook")
    ProcLoopFlipAnim:SetDuration(1)
    if ProcLoopFlipAnim.SetFlipBookRows then
        ProcLoopFlipAnim:SetFlipBookRows(6)
    end

    if ProcLoopFlipAnim.SetFlipBookColumns then
        ProcLoopFlipAnim:SetFlipBookColumns(5)
    end

    if ProcLoopFlipAnim.SetFlipBookFrames then
        ProcLoopFlipAnim:SetFlipBookFrames(30)
    end

    ProcLoop:Play()
    local sw, sh = frame:GetSize()
    hooksecurefunc(
        frame,
        "SetSize",
        function(sel, w, h)
            DebuffBorder:SetSize(w * 1.56, h * 1.58)
        end
    )

    DebuffBorder:SetSize(sw * 1.56, sh * 1.58)
    DebuffBorder:Hide()
    local function OnDebuffDispellable()
        local c, debuffcolor = HealerHelper:GetDispellableDebuffsCount(frame.unit)
        if DebuffBorder then
            if c > 0 then
                DebuffBorder:Show()
                local r, g, b, a = unpack(debuffcolor)
                ProcLoopFlipbook:SetVertexColor(r, g, b, a)
                if ProcLoopAlpha.SetFromAlpha then
                    ProcLoopAlpha:SetFromAlpha(a)
                end

                if ProcLoopAlpha.SetToAlpha then
                    ProcLoopAlpha:SetToAlpha(a)
                end
            else
                DebuffBorder:Hide()
            end
        end

        local delay = IsInRaid() and 0.25 or 0.01
        C_Timer.After(
            delay,
            function()
                OnDebuffDispellable()
            end
        )
    end

    OnDebuffDispellable()

    return DebuffBorder
end

function HealerHelper:CanDispell(debuffType, spellID)
    if spellID == nil then return false end
    local _, className = UnitClass("player")
    for i, tab in pairs(dispells[className]) do
        for id, typ in pairs(tab) do
            if typ == debuffType then
                local hasSpellName = C_Spell.GetSpellInfo(id)
                if hasSpellName and (spellID ~= debuffSeismischerNachhall or HealerHelper:IsBossCastingSpell(spellSeismischesSchmettern)) then return true end
            end
        end
    end

    return false
end

local debuffTypeColors = {
    ["Bleed"] = {1, 0, 0, 0.75},
    ["Curse"] = {0.6, 0, 1, 1},
    ["Disease"] = {0.6, 0.4, 0, 1},
    ["Magic"] = {0.2, 0.5, 1, 1},
    ["Poison"] = {0, 0.6, 0, 1},
}

local affixClasses = {
    ["DRUID"] = true,
    ["EVOKER"] = true,
    ["MAGE"] = true,
    ["SHAMAN"] = true,
    ["PALADIN"] = true,
    ["MONK"] = true,
    ["PRIEST"] = true,
}

local foundDispellable = false
function HealerHelper:FoundDispellable()
    if foundDispellable then return end
    foundDispellable = true
    PlaySound(12889, "Ambience")
    local delay = IsInRaid() and 2.9 or 1.9
    C_Timer.After(
        delay,
        function()
            foundDispellable = false
        end
    )
end

function HealerHelper:GetDebuffTypeColor(debuffType, spellID)
    if spellID == 440313 then
        local _, className = UnitClass("player")
        if affixClasses[className] then
            HealerHelper:FoundDispellable()
        end

        return {0, 0, 0, 0.75}
    end

    if debuffType then
        if HealerHelper:CanDispell(debuffType, spellID) then
            HealerHelper:FoundDispellable()
        end

        return debuffTypeColors[debuffType]
    end

    return {1, 1, 0, 1}
end

local seismischesSchmettern = true
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
local function OnEvent(self, event)
    local _, subEvent, _, _, _, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
    if spellID == spellSeismischesSchmettern then
        if subEvent == "SPELL_CAST_START" then
            seismischesSchmettern = true
        elseif subEvent == "SPELL_CAST_SUCCESS" then
            seismischesSchmettern = false
        end
    end
end

frame:SetScript("OnEvent", OnEvent)
function HealerHelper:IsBossCastingSpell(spellID)
    if spellID == spellSeismischesSchmettern then return seismischesSchmettern end
end
