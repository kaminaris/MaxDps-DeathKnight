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
local DemonicFuryPT = Enum.PowerType.DemonicFury
local BurningEmbersPT = Enum.PowerType.BurningEmbers
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


function Frost:precombat()
    if (MaxDps:CheckSpellUsable(classtable.Presence, 'Presence')) and (not buff[classtable.PresenceBuff].up) and cooldown[classtable.Presence].ready and not UnitAffectingCombat('player') then
        if not setSpell then setSpell = classtable.Presence end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and cooldown[classtable.HornofWinter].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ArmyoftheDead, 'ArmyoftheDead')) and cooldown[classtable.ArmyoftheDead].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, cooldown[classtable.ArmyoftheDead].ready)
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.HornofWinter, false)
    MaxDps:GlowCooldown(classtable.ArmyoftheDead, false)
    MaxDps:GlowCooldown(classtable.PillarofFrost, false)
    MaxDps:GlowCooldown(classtable.RaiseDead, false)
    MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, false)
    MaxDps:GlowCooldown(classtable.BloodTap, false)
end

function Frost:callaction()
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost')) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and (not UnitExists ( 'pet' )) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (debuff[classtable.FrostFeverDeBuff].remains <3 or debuff[classtable.BloodPlagueDeBuff].remains <3) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.UnholyBlight, 'UnholyBlight') and talents[classtable.UnholyBlight]) and ((talents[classtable.UnholyBlight] and true or false) and ( debuff[classtable.FrostFeverDeBuff].remains <3 or debuff[classtable.BloodPlagueDeBuff].remains <3 )) and cooldown[classtable.UnholyBlight].ready then
        if not setSpell then setSpell = classtable.UnholyBlight end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.PlagueStrike, 'PlagueStrike')) and (not debuff[classtable.BloodPlagueDeBuff].up) and cooldown[classtable.PlagueStrike].ready then
        if not setSpell then setSpell = classtable.PlagueStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.PlagueLeech, 'PlagueLeech') and talents[classtable.PlagueLeech]) and ((talents[classtable.PlagueLeech] and true or false) and ( ( cooldown[classtable.Outbreak].remains <1 ) or ( buff[classtable.RimeBuff].up and debuff[classtable.BloodPlagueDeBuff].remains <3 and ( DeathKnight:RuneTypeCount("unholy") >= 1 or DeathKnight:RuneTypeCount("death") >= 1 ) ) )) and cooldown[classtable.PlagueLeech].ready then
        if not setSpell then setSpell = classtable.PlagueLeech end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (RunicPower <= 76) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (ttd <= 60 and buff[classtable.MoguPowerPotionBuff].up) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not buff[classtable.KillingMachineBuff].up) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodTap, 'BloodTap') and talents[classtable.BloodTap]) and ((talents[classtable.BloodTap] and buff[classtable.BloodChargeBuff].count >=5  or false)) and cooldown[classtable.BloodTap].ready then
        MaxDps:GlowCooldown(classtable.BloodTap, cooldown[classtable.BloodTap].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
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

    classtable.FrostStrike = 49143
    classtable.Presence = 48266
    classtable.PresenceBuff = 48266

    classtable.FrostFeverDeBuff = 55095
    classtable.BloodPlagueDeBuff = 55078
    --classtable.RimeBuff
    classtable.KillingMachineBuff = 51124
    classtable.MoguPowerPotionBuff = 447200
    classtable.BloodChargeBuff = 114851

    local function debugg()
        talents[classtable.UnholyBlight] = 1
        talents[classtable.PlagueLeech] = 1
        talents[classtable.BloodTap] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Frost:precombat()

    Frost:callaction()
    if setSpell then return setSpell end
end
