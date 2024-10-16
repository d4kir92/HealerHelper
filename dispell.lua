local _, HealerHelper = ...
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
        [51886] = {"Curse"}
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
                ProcLoopAlpha:SetFromAlpha(a)
                ProcLoopAlpha:SetToAlpha(a)
            else
                DebuffBorder:Hide()
            end
        end

        C_Timer.After(
            0.2,
            function()
                OnDebuffDispellable()
            end
        )
    end

    OnDebuffDispellable()

    return DebuffBorder
end

function HealerHelper:CanDispell(debuffType)
    local _, className = UnitClass("player")
    for i, tab in pairs(dispells[className]) do
        for spellId, typ in pairs(tab) do
            if typ == debuffType then
                local name = C_Spell.GetSpellInfo(spellId)
                if name then return true end
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
    C_Timer.After(
        1.9,
        function()
            foundDispellable = false
        end
    )
end

function HealerHelper:GetDebuffTypeColor(debuffType, spellId)
    if spellId == 440313 then
        local _, className = UnitClass("player")
        if affixClasses[className] then
            HealerHelper:FoundDispellable()
        end

        return {0, 0, 0, 0.75}
    end

    if debuffType then
        if HealerHelper:CanDispell(debuffType) then
            HealerHelper:FoundDispellable()
        end

        return debuffTypeColors[debuffType]
    end

    return {1, 1, 0, 1}
end
