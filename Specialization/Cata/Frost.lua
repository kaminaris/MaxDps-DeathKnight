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
local FocusPT = Enum.PowerType.Focus
local EnergyPT = Enum.PowerType.Energy
local ComboPointsPT = Enum.PowerType.ComboPoints
local RunesPT = Enum.PowerType.Runes
local RunicPowerPT = Enum.PowerType.RunicPower
local SoulShardsPT = Enum.PowerType.SoulShards
local LunarPowerPT = Enum.PowerType.LunarPower
local HolyPowerPT = Enum.PowerType.HolyPower
local MaelstromPT = Enum.PowerType.Maelstrom
local ChiPT = Enum.PowerType.Chi
local InsanityPT = Enum.PowerType.Insanity
local ArcaneChargesPT = Enum.PowerType.ArcaneCharges
local FuryPT = Enum.PowerType.Fury
local PainPT = Enum.PowerType.Pain
local EssencePT = Enum.PowerType.Essence
local RuneBloodPT = Enum.PowerType.RuneBlood
local RuneFrostPT = Enum.PowerType.RuneFrost
local RuneUnholyPT = Enum.PowerType.RuneUnholy

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
local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
local classtable
local LibRangeCheck = LibStub('LibRangeCheck-3.0', true)

local Runes
local RuneBlood
local RuneFrost
local RuneUnholy
local RunicPower
local RunicPowerMax
local RunicPowerDeficit

local Frost = {}



local function twoh_check()
   local leftwep = GetInventoryItemLink('player',16)
   local leftwepSubType = leftwep and select(13, C_Item.GetItemInfo(leftwep))
   local rightwep = GetInventoryItemLink('player',17)
   local rightwepSubType = rightwep and select(13, C_Item.GetItemInfo(rightwep))
   if leftwepSubType == (1 or 5 or 6 or 8) then
      return true
   end
end


local function wep_rune_check(type)
    local MHitemLink=GetInventoryItemLink('player',16)
    local OHitemLink=GetInventoryItemLink('player',17)
    if MHitemLink ~= nil then
        local _,_,enchant=strsplit(':',MHitemLink)
        if enchant ~= nil and enchant ~= '' then
            if enchant == '3368' then
                MHenchant = 'Rune of the Fallen Crusader'
            elseif enchant == '6243' then
                MHenchant = 'Rune of Hysteria'
            elseif enchant == '3370' then
                MHenchant = 'Rune of Razorice'
            elseif enchant == '6241' then
                MHenchant = 'Rune of Sanguination'
            elseif enchant == '6242' then
                MHenchant = 'Rune of Spellwarding'
            elseif enchant == '6245' then
                MHenchant = 'Rune of the Apocalypse'
            elseif enchant == '3847' then
                MHenchant = 'Rune of the Stoneskin Gargoyle'
            elseif enchant == '6244' then
                MHenchant = 'Rune of Unending Thirst'
            else
                MHenchant = 'Unknown Enchant - ' .. enchant
            end
        end
    end
    if OHitemLink ~= nil then
        local _,_,enchant=strsplit(':',OHitemLink)
        if enchant ~= nil and enchant ~= '' then
            if enchant == '3368' then
                OHenchant = 'Rune of the Fallen Crusader'
            elseif enchant == '6243' then
                OHenchant = 'Rune of Hysteria'
            elseif enchant == '3370' then
                OHenchant = 'Rune of Razorice'
            elseif enchant == '6241' then
                OHenchant = 'Rune of Sanguination'
            elseif enchant == '6242' then
                OHenchant = 'Rune of Spellwarding'
            elseif enchant == '6245' then
                OHenchant = 'Rune of the Apocalypse'
            elseif enchant == '3847' then
                OHenchant = 'Rune of the Stoneskin Gargoyle'
            elseif enchant == '6244' then
                OHenchant = 'Rune of Unending Thirst'
            else
                OHenchant = 'Unknown Enchant - ' .. enchant
            end
        end
    end
    if (MHenchant or OHenchant) == type then return true end
    return false
end


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end




local function ClearCDs()
    MaxDps:GlowCooldown(classtable.ArmyoftheDead, false)
    MaxDps:GlowCooldown(classtable.PillarofFrost, false)
    MaxDps:GlowCooldown(classtable.BloodTap, false)
    MaxDps:GlowCooldown(classtable.RaiseDead, false)
    MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, false)
    MaxDps:GlowCooldown(classtable.HornofWinter, false)
end

function Frost:callaction()
    if (MaxDps:CheckSpellUsable(classtable.Presence, 'Presence')) and cooldown[classtable.Presence].ready then
        if not setSpell then setSpell = classtable.Presence end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArmyoftheDead, 'ArmyoftheDead')) and cooldown[classtable.ArmyoftheDead].ready then
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, cooldown[classtable.ArmyoftheDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost')) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodTap, 'BloodTap')) and (death.cooldown_remains >2.0) and cooldown[classtable.BloodTap].ready then
        MaxDps:GlowCooldown(classtable.BloodTap, cooldown[classtable.BloodTap].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (debuff[classtable.FrostFeverDeBuff].remains <= 2 or debuff[classtable.BloodPlagueDeBuff].remains <= 2) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (debuff[classtable.FrostFeverDeBuff].remains <= 2) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.PlagueStrike, 'PlagueStrike')) and (debuff[classtable.BloodPlagueDeBuff].remains <= 2) and cooldown[classtable.PlagueStrike].ready then
        if not setSpell then setSpell = classtable.PlagueStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (death >= 1 and frost >= 1 and unholy >= 1) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (( death == 2 and frost == 2 ) or ( death == 2 and unholy == 2 ) or ( frost == 2 and unholy == 2 )) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (RunicPower >= 110) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (( death == 2 or unholy == 2 or frost == 2 )) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (RunicPower >= 100) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (ttd <= 45) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (( blood.cooldown_remains + frost.cooldown_remains + unholy.cooldown_remains ) >8) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end
function DeathKnight:Frost()
    fd = MaxDps.FrameData
    ttd = (fd.timeToDie and fd.timeToDie) or 500
    timeShift = fd.timeShift
    gcd = fd.gcd
    cooldown = fd.cooldown
    buff = fd.buff
    debuff = fd.debuff
    talents = fd.talents
    targets = MaxDps:SmartAoe()
    Mana = UnitPower('player', ManaPT)
    ManaMax = UnitPowerMax('player', ManaPT)
    ManaDeficit = ManaMax - Mana
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    Runes = UnitPower('player', RunesPT)
    RuneBlood = UnitPower('player', RuneBloodPT)
    RuneFrost = UnitPower('player', RuneFrostPT)
    RuneUnholy = UnitPower('player', RuneUnholyPT)
    RunicPower = UnitPower('player', RunicPowerPT)
    RunicPowerMax = UnitPowerMax('player', RunicPowerPT)
    RunicPowerDeficit = RunicPowerMax - RunicPower
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.bloodlust = 0
    classtable.FrostFeverDeBuff = 55095
    classtable.BloodPlagueDeBuff = 0
    classtable.RimeBuff = 59052
    setSpell = nil
    ClearCDs()

    Frost:callaction()
    if setSpell then return setSpell end
end
