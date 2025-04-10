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

local Unholy = {}

local trinket_1_buffs = false
local trinket_2_buffs = false
local trinket_1_duration = 0
local trinket_2_duration = 0
local trinket_1_high_value = false
local trinket_2_high_value = false
local trinket_1_sync = false
local trinket_2_sync = false
local trinket_priority = false
local damage_trinket_priority = false
local apoc_timing = 0
local pop_wounds = false
local pooling_runic_power = false
local spend_rp = false
local epidemic_targets = 0


local function GetTotemInfoByName(name)
    local info = {
        duration = 0,
        remains = 0,
        up = false,
    }
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local remains = math.floor(startTime+duration-GetTime())
        if (totemName == name ) then
            info.duration = duration
            info.up = true
            info.remains = remains
            break
        end
    end
    return info
end


local function GetTotemTypeActive(i)
   local arg1, totemName, startTime, duration, icon = GetTotemInfo(i)
   return duration > 0
end




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


function Unholy:precombat()
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and (not UnitExists ( 'pet' )) and cooldown[classtable.RaiseDead].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ArmyoftheDead, 'ArmyoftheDead') and talents[classtable.ArmyoftheDead]) and cooldown[classtable.ArmyoftheDead].ready and not UnitAffectingCombat('player') then
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, cooldown[classtable.ArmyoftheDead].ready)
    end
end
function Unholy:aoe()
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.FesteringWoundDeBuff].count >= 1 and buff[classtable.DeathandDecayBuff].up and talents[classtable.BurstingSores] and cooldown[classtable.Apocalypse].remains >apoc_timing) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and targets <epidemic_targets) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Epidemic, 'Epidemic')) and (debuff[classtable.VirulentPlagueDeBuff].up and not pooling_runic_power) and cooldown[classtable.Epidemic].ready then
        if not setSpell then setSpell = classtable.Epidemic end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.ChainsofIceTrollbaneSlowDeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (cooldown[classtable.Apocalypse].remains <apoc_timing or buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (debuff[classtable.FesteringWoundDeBuff].count <2) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.FesteringWoundDeBuff].count >= 1 and cooldown[classtable.Apocalypse].remains >gcd or buff[classtable.VampiricStrikeBuff].up and debuff[classtable.VirulentPlagueDeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
end
function Unholy:aoe_burst()
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not buff[classtable.VampiricStrikeBuff].up and targets <epidemic_targets and ( not talents[classtable.BurstingSores] or talents[classtable.BurstingSores] and MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) <targets and MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) <targets * 0.4 and buff[classtable.SuddenDoomBuff].up or buff[classtable.SuddenDoomBuff].up and ( talents[classtable.DoomedBidding] and talents[classtable.MenacingMagus] or talents[classtable.RottenTouch] or debuff[classtable.DeathRotDeBuff].remains <gcd ) )) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Epidemic, 'Epidemic')) and (debuff[classtable.VirulentPlagueDeBuff].up and not buff[classtable.VampiricStrikeBuff].up and ( not talents[classtable.BurstingSores] or talents[classtable.BurstingSores] and MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) <1 and MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) <targets * 0.4 and buff[classtable.SuddenDoomBuff].up or buff[classtable.SuddenDoomBuff].up and ( buff[classtable.AFeastofSoulsBuff].up or debuff[classtable.DeathRotDeBuff].remains <gcd or debuff[classtable.DeathRotDeBuff].count <10 ) )) and cooldown[classtable.Epidemic].ready then
        if not setSpell then setSpell = classtable.Epidemic end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.ChainsofIceTrollbaneSlowDeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.FesteringWoundDeBuff].count >= 1 or buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (targets <epidemic_targets) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Epidemic, 'Epidemic')) and (debuff[classtable.VirulentPlagueDeBuff].up) and cooldown[classtable.Epidemic].ready then
        if not setSpell then setSpell = classtable.Epidemic end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (debuff[classtable.FesteringWoundDeBuff].count <= 2) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
end
function Unholy:aoe_setup()
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and ( not talents[classtable.BurstingSores] and not talents[classtable.VileContagion] or MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) >= 1 or MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) >= 8 or (targets >1) and targets <= 11 and targets >5 or not buff[classtable.DeathandDecayBuff].up and talents[classtable.Defile] )) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.ChainsofIceTrollbaneSlowDeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (not talents[classtable.VileContagion]) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (cooldown[classtable.VileContagion].remains <5 or MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) >= 1 and debuff[classtable.FesteringWoundDeBuff].count <= 4) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and buff[classtable.SuddenDoomBuff].up and targets <epidemic_targets) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Epidemic, 'Epidemic')) and (debuff[classtable.VirulentPlagueDeBuff].up and not pooling_runic_power and buff[classtable.SuddenDoomBuff].up) and cooldown[classtable.Epidemic].ready then
        if not setSpell then setSpell = classtable.Epidemic end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (cooldown[classtable.Apocalypse].remains <gcd and debuff[classtable.FesteringWoundDeBuff].count == 0 or MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) <1) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and targets <epidemic_targets) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Epidemic, 'Epidemic')) and (debuff[classtable.VirulentPlagueDeBuff].up and not pooling_runic_power) and cooldown[classtable.Epidemic].ready then
        if not setSpell then setSpell = classtable.Epidemic end
    end
end
function Unholy:cds()
    if (MaxDps:CheckSpellUsable(classtable.DarkTransformation, 'DarkTransformation')) and (UnitExists ( 'pet' ) and targets == 1 and ( cooldown[classtable.Apocalypse].remains <8 or not talents[classtable.Apocalypse] or targets >= 1 ) or MaxDps:boss() and ttd <20) and cooldown[classtable.DarkTransformation].ready then
        MaxDps:GlowCooldown(classtable.DarkTransformation, cooldown[classtable.DarkTransformation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.UnholyAssault, 'UnholyAssault')) and (targets == 1 and ( cooldown[classtable.Apocalypse].remains <gcd * 2 or not talents[classtable.Apocalypse] or targets >= 2 and buff[classtable.DarkTransformationBuff].up ) or MaxDps:boss() and ttd <20) and cooldown[classtable.UnholyAssault].ready then
        if not setSpell then setSpell = classtable.UnholyAssault end
    end
    if (MaxDps:CheckSpellUsable(classtable.Apocalypse, 'Apocalypse') and talents[classtable.Apocalypse]) and (targets == 1 or ttd <20) and cooldown[classtable.Apocalypse].ready then
        if not setSpell then setSpell = classtable.Apocalypse end
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (ttd >debuff[classtable.VirulentPlagueDeBuff].remains and debuff[classtable.VirulentPlagueDeBuff].remains <5 and ( debuff[classtable.VirulentPlagueDeBuff].refreshable or talents[classtable.Superstrain] and ( debuff[classtable.FrostFeverDeBuff].refreshable or debuff[classtable.BloodPlagueDeBuff].refreshable ) ) and ( not talents[classtable.UnholyBlight] or talents[classtable.Plaguebringer] ) and ( not talents[classtable.RaiseAbomination] or talents[classtable.RaiseAbomination] and cooldown[classtable.RaiseAbomination].remains >debuff[classtable.VirulentPlagueDeBuff].remains * 3 )) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (targets == 1 and not buff[classtable.SuddenDoomBuff].up and ( buff[classtable.FestermightBuff].up and buff[classtable.FestermightBuff].count >8 or not talents[classtable.Festermight] ) and ( math.max(0,20 - (cooldown[classtable.Apocalypse].duration - cooldown[classtable.Apocalypse].remains)) <5 or not talents[classtable.Apocalypse] ) and debuff[classtable.FesteringWoundDeBuff].count <= 2 or MaxDps:boss() and ttd <12) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
end
function Unholy:cds_aoe()
    if (MaxDps:CheckSpellUsable(classtable.UnholyAssault, 'UnholyAssault')) and (targets >1 and ( cooldown[classtable.VileContagion].remains <3 or cooldown[classtable.VileContagion].remains >40 or not talents[classtable.VileContagion] )) and cooldown[classtable.UnholyAssault].ready then
        if not setSpell then setSpell = classtable.UnholyAssault end
    end
    if (MaxDps:CheckSpellUsable(classtable.VileContagion, 'VileContagion') and talents[classtable.VileContagion]) and (debuff[classtable.FesteringWoundDeBuff].count >= 4 and ( targets >4 or (targets <2) and ttd >4 ) and ( (targets >1) and targets <= 11 or cooldown[classtable.DeathandDecay].remains <3 or buff[classtable.DeathandDecayBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 4 ) or targets >1 and debuff[classtable.FesteringWoundDeBuff].count == 6) and cooldown[classtable.VileContagion].ready then
        if not setSpell then setSpell = classtable.VileContagion end
    end
    if (MaxDps:CheckSpellUsable(classtable.DarkTransformation, 'DarkTransformation')) and (UnitExists ( 'pet' ) and targets >1 and ( cooldown[classtable.VileContagion].remains >5 or not talents[classtable.VileContagion] or buff[classtable.DeathandDecayBuff].up or cooldown[classtable.DeathandDecay].remains <3 )) and cooldown[classtable.DarkTransformation].ready then
        MaxDps:GlowCooldown(classtable.DarkTransformation, cooldown[classtable.DarkTransformation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (debuff[classtable.VirulentPlagueDeBuff].remains <5 and ( debuff[classtable.VirulentPlagueDeBuff].refreshable or talents[classtable.Morbidity] and not buff[classtable.GiftoftheSanlaynBuff].up and talents[classtable.Superstrain] and debuff[classtable.FrostFeverDeBuff].refreshable and debuff[classtable.BloodPlagueDeBuff].refreshable ) and ( not talents[classtable.UnholyBlight] or talents[classtable.UnholyBlight] and not cooldown[classtable.DarkTransformation].ready ) and ( not talents[classtable.RaiseAbomination] or talents[classtable.RaiseAbomination] and not cooldown[classtable.RaiseAbomination].ready )) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.Apocalypse, 'Apocalypse') and talents[classtable.Apocalypse]) and (targets >1 and Runes <= 3) and cooldown[classtable.Apocalypse].ready then
        if not setSpell then setSpell = classtable.Apocalypse end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (targets >1) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
end
function Unholy:cds_aoe_san()
    if (MaxDps:CheckSpellUsable(classtable.DarkTransformation, 'DarkTransformation')) and (UnitExists ( 'pet' ) and targets >1 and ( buff[classtable.DeathandDecayBuff].up or targets <= 3 )) and cooldown[classtable.DarkTransformation].ready then
        MaxDps:GlowCooldown(classtable.DarkTransformation, cooldown[classtable.DarkTransformation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.UnholyAssault, 'UnholyAssault')) and (targets >1 and ( cooldown[classtable.VileContagion].remains <6 or cooldown[classtable.VileContagion].remains >40 or not talents[classtable.VileContagion] ) or MaxDps:boss() and ttd <20) and cooldown[classtable.UnholyAssault].ready then
        if not setSpell then setSpell = classtable.UnholyAssault end
    end
    if (MaxDps:CheckSpellUsable(classtable.VileContagion, 'VileContagion') and talents[classtable.VileContagion]) and (debuff[classtable.FesteringWoundDeBuff].count >= 4 and ( targets >4 or (targets <2) and ttd >4 ) and ( (targets >1) and targets <= 11 or cooldown[classtable.DeathandDecay].remains <3 or buff[classtable.DeathandDecayBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 4 ) or targets >1 and debuff[classtable.FesteringWoundDeBuff].count == 6) and cooldown[classtable.VileContagion].ready then
        if not setSpell then setSpell = classtable.VileContagion end
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (( debuff[classtable.VirulentPlagueDeBuff].refreshable or talents[classtable.Morbidity] and not buff[classtable.GiftoftheSanlaynBuff].up and talents[classtable.Superstrain] and debuff[classtable.FrostFeverDeBuff].refreshable and debuff[classtable.BloodPlagueDeBuff].refreshable ) and ( not talents[classtable.UnholyBlight] or talents[classtable.UnholyBlight] and cooldown[classtable.DarkTransformation].remains >15 / ( ( 2 * (talents[classtable.Superstrain] and talents[classtable.Superstrain] or 0) ) + ( 2 * (talents[classtable.EbonFever] and talents[classtable.EbonFever] or 0) ) + ( 2 * (talents[classtable.Plaguebringer] and talents[classtable.Plaguebringer] or 0) ) ) ) and ( not talents[classtable.RaiseAbomination] or talents[classtable.RaiseAbomination] and cooldown[classtable.RaiseAbomination].remains >15 / ( ( 2 * (talents[classtable.Superstrain] and talents[classtable.Superstrain] or 0) ) + ( 2 * (talents[classtable.EbonFever] and talents[classtable.EbonFever] or 0) ) + ( 2 * (talents[classtable.Plaguebringer] and talents[classtable.Plaguebringer] or 0) ) ) )) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.Apocalypse, 'Apocalypse') and talents[classtable.Apocalypse]) and (targets >1 and Runes <= 3) and cooldown[classtable.Apocalypse].ready then
        if not setSpell then setSpell = classtable.Apocalypse end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (targets >1) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
end
function Unholy:cds_cleave_san()
    if (MaxDps:CheckSpellUsable(classtable.DarkTransformation, 'DarkTransformation')) and (UnitExists ( 'pet' ) and buff[classtable.DeathandDecayBuff].up and ( talents[classtable.Apocalypse] and (math.max(0,20 - (cooldown[classtable.Apocalypse].duration - cooldown[classtable.Apocalypse].remains)) >0) or not talents[classtable.Apocalypse] ) or MaxDps:boss() and ttd <20 or (targets >1) and targets <20) and cooldown[classtable.DarkTransformation].ready then
        MaxDps:GlowCooldown(classtable.DarkTransformation, cooldown[classtable.DarkTransformation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.UnholyAssault, 'UnholyAssault')) and (buff[classtable.DarkTransformationBuff].up and buff[classtable.DarkTransformationBuff].remains <12 or MaxDps:boss() and ttd <20 or (targets >1) and targets <20) and cooldown[classtable.UnholyAssault].ready then
        if not setSpell then setSpell = classtable.UnholyAssault end
    end
    if (MaxDps:CheckSpellUsable(classtable.Apocalypse, 'Apocalypse') and talents[classtable.Apocalypse]) and cooldown[classtable.Apocalypse].ready then
        if not setSpell then setSpell = classtable.Apocalypse end
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (( debuff[classtable.VirulentPlagueDeBuff].refreshable or talents[classtable.Morbidity] and buff[classtable.InflictionofSorrowBuff].up and talents[classtable.Superstrain] and debuff[classtable.FrostFeverDeBuff].refreshable and debuff[classtable.BloodPlagueDeBuff].refreshable ) and ( not talents[classtable.UnholyBlight] or talents[classtable.UnholyBlight] and cooldown[classtable.DarkTransformation].remains >5 ) and ( not talents[classtable.RaiseAbomination] or talents[classtable.RaiseAbomination] and cooldown[classtable.RaiseAbomination].remains >5 )) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (not buff[classtable.GiftoftheSanlaynBuff].up and not buff[classtable.SuddenDoomBuff].up and buff[classtable.FestermightBuff].up and debuff[classtable.FesteringWoundDeBuff].count <= 2 or not buff[classtable.GiftoftheSanlaynBuff].up and MaxDps:boss() and ttd <12) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
end
function Unholy:cds_san()
    if (MaxDps:CheckSpellUsable(classtable.DarkTransformation, 'DarkTransformation')) and (UnitExists ( 'pet' ) and targets >= 1 and targets == 1 and ( talents[classtable.Apocalypse] and (math.max(0,20 - (cooldown[classtable.Apocalypse].duration - cooldown[classtable.Apocalypse].remains)) >0) or not talents[classtable.Apocalypse] ) or MaxDps:boss() and ttd <20) and cooldown[classtable.DarkTransformation].ready then
        MaxDps:GlowCooldown(classtable.DarkTransformation, cooldown[classtable.DarkTransformation].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.UnholyAssault, 'UnholyAssault')) and (targets == 1 and ( buff[classtable.DarkTransformationBuff].up and buff[classtable.DarkTransformationBuff].remains <12 ) or MaxDps:boss() and ttd <20) and cooldown[classtable.UnholyAssault].ready then
        if not setSpell then setSpell = classtable.UnholyAssault end
    end
    if (MaxDps:CheckSpellUsable(classtable.Apocalypse, 'Apocalypse') and talents[classtable.Apocalypse]) and (targets == 1 or ttd <20) and cooldown[classtable.Apocalypse].ready then
        if not setSpell then setSpell = classtable.Apocalypse end
    end
    if (MaxDps:CheckSpellUsable(classtable.Outbreak, 'Outbreak')) and (ttd >debuff[classtable.VirulentPlagueDeBuff].remains and debuff[classtable.VirulentPlagueDeBuff].remains <5 and ( debuff[classtable.VirulentPlagueDeBuff].refreshable or talents[classtable.Morbidity] and buff[classtable.InflictionofSorrowBuff].up and talents[classtable.Superstrain] and debuff[classtable.FrostFeverDeBuff].refreshable and debuff[classtable.BloodPlagueDeBuff].refreshable ) and ( not talents[classtable.UnholyBlight] or talents[classtable.UnholyBlight] and not cooldown[classtable.DarkTransformation].ready ) and ( not talents[classtable.RaiseAbomination] or talents[classtable.RaiseAbomination] and not cooldown[classtable.RaiseAbomination].ready )) and cooldown[classtable.Outbreak].ready then
        if not setSpell then setSpell = classtable.Outbreak end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (targets >= 1 and targets == 1 and not buff[classtable.GiftoftheSanlaynBuff].up and not buff[classtable.SuddenDoomBuff].up and buff[classtable.FestermightBuff].up and debuff[classtable.FesteringWoundDeBuff].count <= 2 or not buff[classtable.GiftoftheSanlaynBuff].up and ttd <12) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
end
function Unholy:cleave()
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and ( not cooldown[classtable.Apocalypse].ready or not talents[classtable.Apocalypse] )) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and talents[classtable.ImprovedDeathCoil]) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and not talents[classtable.ImprovedDeathCoil]) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (not buff[classtable.VampiricStrikeBuff].up and not pop_wounds and debuff[classtable.FesteringWoundDeBuff].count <2 or buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (not buff[classtable.VampiricStrikeBuff].up and cooldown[classtable.Apocalypse].remains <apoc_timing and debuff[classtable.FesteringWoundDeBuff].count <1) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (pop_wounds) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
end
function Unholy:san_fishing()
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and not buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (buff[classtable.SuddenDoomBuff].up and talents[classtable.DoomedBidding] or (MaxDps.tier and MaxDps.tier[33].count >= 4) and (buff[classtable.EssenceoftheBloodQueenBuff].count == 5) and talents[classtable.FrenziedBloodthirst] and not buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (targethealthPerc <= 35 and ttd >5) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (( debuff[classtable.FesteringWoundDeBuff].count >= 3 - ( UnitExists('pet') and 1 or 0 ) and cooldown[classtable.Apocalypse].remains >apoc_timing ) or buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (debuff[classtable.FesteringWoundDeBuff].count <3 - ( UnitExists('pet') and 1 or 0 )) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
end
function Unholy:san_st()
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and talents[classtable.UnholyGround] and cooldown[classtable.DarkTransformation].remains <5) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (buff[classtable.SuddenDoomBuff].up and buff[classtable.GiftoftheSanlaynBuff].up and ( talents[classtable.DoomedBidding] or talents[classtable.RottenTouch] ) or Runes <3 and not buff[classtable.RunicCorruptionBuff].up or (MaxDps.tier and MaxDps.tier[33].count >= 4) and RunicPower >80 or buff[classtable.GiftoftheSanlaynBuff].up and (buff[classtable.EssenceoftheBloodQueenBuff].count == 5) and talents[classtable.FrenziedBloodthirst] and (MaxDps.tier and MaxDps.tier[33].count >= 4) and (buff[classtable.WinningStreakBuff].count == 10) and Runes <= 3 and buff[classtable.EssenceoftheBloodQueenBuff].remains >3) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (buff[classtable.GiftoftheSanlaynBuff].up and buff[classtable.VampiricStrikeBuff].up or talents[classtable.GiftoftheSanlayn] and buff[classtable.DarkTransformationBuff].up and buff[classtable.DarkTransformationBuff].remains <gcd) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (targethealthPerc <= 35 and not buff[classtable.GiftoftheSanlaynBuff].up and ttd >5) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (buff[classtable.VampiricStrikeBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 1) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (( debuff[classtable.FesteringWoundDeBuff].count == 0 and cooldown[classtable.Apocalypse].remains <apoc_timing ) or ( talents[classtable.GiftoftheSanlayn] and not buff[classtable.GiftoftheSanlaynBuff].up or not talents[classtable.GiftoftheSanlayn] ) and ( buff[classtable.FesteringScytheBuff].up or debuff[classtable.FesteringWoundDeBuff].count <= 1 )) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (( not talents[classtable.Apocalypse] or cooldown[classtable.Apocalypse].remains >apoc_timing ) and ( debuff[classtable.FesteringWoundDeBuff].count >= 3 - ( UnitExists('pet') and 1 or 0 ) or buff[classtable.VampiricStrikeBuff].up )) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and debuff[classtable.DeathRotDeBuff].remains <gcd or ( buff[classtable.SuddenDoomBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 1 or Runes <2 )) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.FesteringWoundDeBuff].count >4) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
end
function Unholy:san_trinkets()
end
function Unholy:st()
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (targethealthPerc <= 35 and ttd >5) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.ChainsofIceTrollbaneSlowDeBuff].up) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (talents[classtable.UnholyGround] and not buff[classtable.DeathandDecayBuff].up and ( (math.max(0,20 - (cooldown[classtable.Apocalypse].duration - cooldown[classtable.Apocalypse].remains)) >0) or ( UnitExists('pet') and UnitName('pet')  == 'Abomination' ) or ( UnitExists('pet') and UnitName('pet')  == 'Gargoyle' ) )) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and spend_rp or MaxDps:boss() and ttd <10) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.FesteringStrike, 'FesteringStrike')) and (debuff[classtable.FesteringWoundDeBuff].count <4 and ( not pop_wounds or buff[classtable.FesteringScytheBuff].up )) and cooldown[classtable.FesteringStrike].ready then
        if not setSpell then setSpell = classtable.FesteringStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (pop_wounds) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power) and cooldown[classtable.DeathCoil].ready then
        if not setSpell then setSpell = classtable.DeathCoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.WoundSpender, 'WoundSpender')) and (not pop_wounds and debuff[classtable.FesteringWoundDeBuff].count >= 4) and cooldown[classtable.WoundSpender].ready then
        if not setSpell then setSpell = classtable.WoundSpender end
    end
end
function Unholy:trinkets()
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.RaiseDead, false)
    MaxDps:GlowCooldown(classtable.ArmyoftheDead, false)
    MaxDps:GlowCooldown(classtable.MindFreeze, false)
    MaxDps:GlowCooldown(classtable.RaiseAbomination, false)
    MaxDps:GlowCooldown(classtable.SummonGargoyle, false)
    MaxDps:GlowCooldown(classtable.DarkTransformation, false)
    MaxDps:GlowCooldown(classtable.AbominationLimb, false)
end

function Unholy:callaction()
    if (MaxDps:CheckSpellUsable(classtable.MindFreeze, 'MindFreeze')) and cooldown[classtable.MindFreeze].ready then
        MaxDps:GlowCooldown(classtable.MindFreeze, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if cooldown[classtable.Apocalypse].remains <5 and debuff[classtable.FesteringWoundDeBuff].count <1 and cooldown[classtable.UnholyAssault].remains >5 then
        apoc_timing = 3
    else
        apoc_timing = 0
    end
    pop_wounds = ( cooldown[classtable.Apocalypse].remains >apoc_timing or not talents[classtable.Apocalypse] ) and ( debuff[classtable.FesteringWoundDeBuff].count >= 1 and cooldown[classtable.UnholyAssault].remains <20 and talents[classtable.UnholyAssault] and targets == 1 or debuff[classtable.RottenTouchDeBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 1 or debuff[classtable.FesteringWoundDeBuff].count >= 4 - ( UnitExists('pet') and 1 or 0 ) ) or ttd <5 and debuff[classtable.FesteringWoundDeBuff].count >= 1
    pooling_runic_power = talents[classtable.VileContagion] and cooldown[classtable.VileContagion].remains <5 and RunicPower <30
    spend_rp = ( not talents[classtable.RottenTouch] or talents[classtable.RottenTouch] and not debuff[classtable.RottenTouchDeBuff].up or RunicPowerDeficit <20 ) and ( ( talents[classtable.ImprovedDeathCoil] and ( targets == 2 or talents[classtable.CoilofDevastation] ) or Runes <3 or ( UnitExists('pet') and UnitName('pet')  == 'Gargoyle' ) or buff[classtable.SuddenDoomBuff].up or not pop_wounds and debuff[classtable.FesteringWoundDeBuff].count >= 4 ) )
    epidemic_targets = 3 + (talents[classtable.ImprovedDeathCoil] and talents[classtable.ImprovedDeathCoil] or 0) + ( ( (talents[classtable.FrenziedBloodthirst] and talents[classtable.FrenziedBloodthirst] or 0) and buff[classtable.EssenceoftheBloodQueenBuff].count >5 ) and 1 or 0 ) + ( ( (talents[classtable.HungeringThirst] and talents[classtable.HungeringThirst] or 0) and talents[classtable.HarbingerofDoom] and buff[classtable.SuddenDoomBuff].up ) and 1 or 0 )
    if (talents[classtable.VampiricStrike]) then
        Unholy:san_trinkets()
    end
    if (not talents[classtable.VampiricStrike]) then
        Unholy:trinkets()
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and (targets >= 2 or ( 6-Runes >= 5 and RunicPowerDeficit >= 60 )) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArmyoftheDead, 'ArmyoftheDead') and talents[classtable.ArmyoftheDead]) and (( talents[classtable.CommanderoftheDead] and cooldown[classtable.DarkTransformation].remains <5 or not talents[classtable.CommanderoftheDead] and targets >= 1 ) or MaxDps:boss() and ttd <35) and cooldown[classtable.ArmyoftheDead].ready then
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, cooldown[classtable.ArmyoftheDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RaiseAbomination, 'RaiseAbomination') and talents[classtable.RaiseAbomination]) and cooldown[classtable.RaiseAbomination].ready then
        MaxDps:GlowCooldown(classtable.RaiseAbomination, cooldown[classtable.RaiseAbomination].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SummonGargoyle, 'SummonGargoyle') and talents[classtable.SummonGargoyle]) and (( buff[classtable.CommanderoftheDeadBuff].up or not talents[classtable.CommanderoftheDead] and targets >= 1 ) or MaxDps:boss() and ttd <25) and cooldown[classtable.SummonGargoyle].ready then
        MaxDps:GlowCooldown(classtable.SummonGargoyle, cooldown[classtable.SummonGargoyle].ready)
    end
    if (talents[classtable.VampiricStrike] and targets >= 3) then
        Unholy:cds_aoe_san()
    end
    if (not talents[classtable.VampiricStrike] and targets >= 2) then
        Unholy:cds_aoe()
    end
    if (talents[classtable.VampiricStrike] and targets == 2) then
        Unholy:cds_cleave_san()
    end
    if (talents[classtable.VampiricStrike] and targets == 1) then
        Unholy:cds_san()
    end
    if (not talents[classtable.VampiricStrike] and targets == 1) then
        Unholy:cds()
    end
    if (targets == 2) then
        Unholy:cleave()
    end
    if (targets >= 3 and not buff[classtable.DeathandDecayBuff].up and cooldown[classtable.DeathandDecay].remains <10) then
        Unholy:aoe_setup()
    end
    if (targets >= 3 and ( buff[classtable.DeathandDecayBuff].up or buff[classtable.DeathandDecayBuff].up and MaxDps:DebuffCounter(classtable.FesteringWoundDebuff, 1) >= ( 1 * 0.5 ) )) then
        Unholy:aoe_burst()
    end
    if (targets >= 3 and not buff[classtable.DeathandDecayBuff].up) then
        Unholy:aoe()
    end
    if (targets == 1 and talents[classtable.GiftoftheSanlayn] and not cooldown[classtable.DarkTransformation].ready and not buff[classtable.GiftoftheSanlaynBuff].up and buff[classtable.EssenceoftheBloodQueenBuff].remains <cooldown[classtable.DarkTransformation].remains + 3) then
        Unholy:san_fishing()
    end
    if (targets == 1 and talents[classtable.VampiricStrike]) then
        Unholy:san_st()
    end
    if (targets == 1 and not talents[classtable.VampiricStrike]) then
        Unholy:st()
    end
end
function DeathKnight:Unholy()
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
    classtable.WoundSpender = IsSpellKnownOrOverridesKnown(classtable.ScourgeStrike) and C_Spell.GetSpellInfo(classtable.ScourgeStrike) and ( C_Spell.GetSpellInfo(C_Spell.GetSpellInfo(classtable.ScourgeStrike).name).spellID ) --55090
    classtable.FesteringScythe = 458128
    if buff[classtable.FesteringScytheBuff].up then
        classtable.FesteringStrike = classtable.FesteringScythe
    else
        classtable.FesteringStrike = 85948
    end
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.SuddenDoomBuff = 81340
    classtable.EssenceoftheBloodQueenBuff = 433925
    classtable.BloodFuryBuff = 20572
    classtable.DeathandDecayBuff = 188290
    classtable.BerserkingBuff = 26297
    classtable.UnholyStrengthBuff = 53365
    classtable.FestermightBuff = 377591
    classtable.FirebloodBuff = 273104
    classtable.DarkTransformationBuff = 63560
    classtable.CommanderoftheDeadBuff = 390260
    classtable.GiftoftheSanlaynBuff = 434153
    classtable.FesteringScytheBuff = 458123
    classtable.VampiricStrikeBuff = 433899
    classtable.AFeastofSoulsBuff = 440861
    classtable.InflictionofSorrowBuff = 460049
    classtable.RunicCorruptionBuff = 51460
    classtable.WinningStreakBuff = 1216813
    classtable.ErrantManaforgeEmissionBuff = 449952
    classtable.CrypticInstructionsBuff = 449946
    classtable.RealigningNexusConvergenceDivergenceBuff = 449947
    classtable.FesteringWoundDeBuff = 194310
    classtable.RottenTouchDeBuff = 390276
    classtable.ChainsofIceTrollbaneSlowDeBuff = 444826
    classtable.VirulentPlagueDeBuff = 191587
    classtable.DeathRotDeBuff = 377540
    classtable.FrostFeverDeBuff = 55095
    classtable.BloodPlagueDeBuff = 55078
    classtable.MarkofFyralathDeBuff = 414532
    classtable.ArcanePulse = 260369

    local function debugg()
        talents[classtable.VampiricStrike] = 1
        talents[classtable.SummonGargoyle] = 1
        talents[classtable.Festermight] = 1
        talents[classtable.CommanderoftheDead] = 1
        talents[classtable.GiftoftheSanlayn] = 1
        talents[classtable.BurstingSores] = 1
        talents[classtable.DoomedBidding] = 1
        talents[classtable.MenacingMagus] = 1
        talents[classtable.RottenTouch] = 1
        talents[classtable.VileContagion] = 1
        talents[classtable.Defile] = 1
        talents[classtable.Apocalypse] = 1
        talents[classtable.Superstrain] = 1
        talents[classtable.UnholyBlight] = 1
        talents[classtable.Plaguebringer] = 1
        talents[classtable.RaiseAbomination] = 1
        talents[classtable.Morbidity] = 1
        talents[classtable.ImprovedDeathCoil] = 1
        talents[classtable.FrenziedBloodthirst] = 1
        talents[classtable.UnholyGround] = 1
        talents[classtable.ArmyoftheDead] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Unholy:precombat()

    Unholy:callaction()
    if setSpell then return setSpell end
end
