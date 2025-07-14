local _, addonTable = ...
local DeathKnight = addonTable.DeathKnight
local MaxDps = _G.MaxDps
if not MaxDps then return end
local setSpell

local UnitPower = UnitPower
local UnitHealth = UnitHealth
local UnitAura = C_UnitAuras.GetAuraDataByIndex
local UnitAuraByName = C_UnitAuras.GetAuraDataBySpellName
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax
local SpellHaste
local SpellCrit
local GetSpellInfo = C_Spell.GetSpellInfo
local GetSpellCooldown = C_Spell.GetSpellCooldown
local GetSpellCount = C_Spell.GetSpellCastCount

local ManaPT = Enum.PowerType.Mana
local RagePT = Enum.PowerType.Rage
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower

local fd
local ttd
local timeShift
local gcd
local cooldown
local buff
local debuff
local talents
local targets
local targetHP
local targetmaxHP
local targethealthPerc
local curentHP
local maxHP
local healthPerc
local timeInCombat
local className, classFilename, classId = UnitClass('player')
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Runes
local RunicPower
local RunicPowerMax
local RunicPowerDeficit

local Blood = {}

function Blood:precombat()
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end

local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HornofWinter, false)
    MaxDps:GlowCooldown(classtable.DeathandDecay, false)
end

function Blood:single()
    -- Single Target Priority
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (Runes > 0) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (debuff[classtable.FrostFeverDeBuff].remains <3 or debuff[classtable.BloodPlagueDeBuff].remains <3) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.RuneStrike, 'RuneStrike')) and (RunicPower >= RunicPowerMax - 20) and cooldown[classtable.RuneStrike].ready then
        if not setSpell then setSpell = classtable.RuneStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.DeathRuneBuff].up and healthPerc < 80) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (buff[classtable.BloodRuneBuff].up or targethealthPerc < 35) and cooldown[classtable.HeartStrike].ready then
        if not setSpell then setSpell = classtable.HeartStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (buff[classtable.CrimsonScourgeBuff].up and debuff[classtable.FrostFeverDeBuff].remains >15) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (buff[classtable.CrimsonScourgeBuff].up and debuff[classtable.FrostFeverDeBuff].remains <15) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end

function Blood:aoe()
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (debuff[classtable.FrostFeverDeBuff].remains <3 or debuff[classtable.BloodPlagueDeBuff].remains <3) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.Pestilence, 'Pestilence')) and cooldown[classtable.Pestilence].ready then
        if not setSpell then setSpell = classtable.Pestilence end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (buff[classtable.CrimsonScourgeBuff].up) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (Runes > 0) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.RuneStrike, 'RuneStrike')) and (RunicPower >= RunicPowerMax - 20) and cooldown[classtable.RuneStrike].ready then
        if not setSpell then setSpell = classtable.RuneStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end

function Blood:callaction()
    if targets > 1 then
        Blood:aoe()
    end
    Blood:single()
end

function DeathKnight:Blood()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Runes = UnitPower('player', RunesPT)
    RunicPower = UnitPower('player', RunicPowerPT)
    RunicPowerMax = UnitPowerMax('player', RunicPowerPT)
    RunicPowerDeficit = RunicPowerMax - RunicPower
    classtable = MaxDps.SpellTable

    classtable.DeathStrike = 49998
    classtable.Outbreak = 77575
    classtable.RuneStrike = 56815
    classtable.HeartStrike = 55050
    classtable.DeathandDecay = 43265
    classtable.BloodBoil = 50842
    classtable.HornofWinter = 57330
    classtable.Pestilence = 50842
    classtable.FrostFeverDeBuff = 55095
    classtable.BloodPlagueDeBuff = 55078
    classtable.CrimsonScourgeBuff = 81141
    classtable.DeathRuneBuff = 54637
    classtable.BloodRuneBuff = 54638

    setSpell = nil
    ClearCDs()

    Blood:precombat()
    Blood:callaction()
    if setSpell then return setSpell end
end