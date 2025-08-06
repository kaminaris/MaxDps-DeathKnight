local _, addonTable = ...
local DeathKnight = addonTable.DeathKnight
local MaxDps = _G.MaxDps
if not MaxDps then return end
local LibStub = LibStub
local setSpell

local ceil = ceil
local floor = floor
local fmod = fmod
local format = format
local max = max
local min = min
local pairs = pairs
local select = select
local strsplit = strsplit
local GetTime = GetTime

local UnitAffectingCombat = UnitAffectingCombat
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitSpellHaste = UnitSpellHaste
local UnitThreatSituation = UnitThreatSituation
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
local GetSpellCastCount = C_Spell.GetSpellCastCount
local GetUnitSpeed = GetUnitSpeed
local GetCritChance = GetCritChance
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = C_Item.GetItemInfo
local GetItemSpell = C_Item.GetItemSpell
local GetNamePlates = C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates or GetNamePlates
local GetPowerRegenForPowerType = GetPowerRegenForPowerType
local GetSpellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName or GetSpellInfo
local GetTotemInfo = GetTotemInfo
local IsStealthed = IsStealthed
local IsCurrentSpell = C_Spell and C_Spell.IsCurrentSpell
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo

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
local RunesMax
local RunesDeficit
local RunesPerc
local RunesRegen
local RunesRegenCombined
local RunesTimeToMax
local RunicPower
local RunicPowerMax
local RunicPowerDeficit
local RunicPowerPerc
local RunicPowerRegen
local RunicPowerRegenCombined
local RunicPowerTimeToMax
local RuneBlood
local RuneBloodMax
local RuneBloodDeficit
local RuneBloodPerc
local RuneBloodRegen
local RuneBloodRegenCombined
local RuneBloodTimeToMax
local RuneFrost
local RuneFrostMax
local RuneFrostDeficit
local RuneFrostPerc
local RuneFrostRegen
local RuneFrostRegenCombined
local RuneFrostTimeToMax
local RuneUnholy
local RuneUnholyMax
local RuneUnholyDeficit
local RuneUnholyPerc
local RuneUnholyRegen
local RuneUnholyRegenCombined
local RuneUnholyTimeToMax
local RuneBlood
local RuneFrost
local RuneUnholy

local Frost = {}

local trinket_1_sync = false
local trinket_2_sync = false
local trinket_1_buffs = false
local trinket_2_buffs = false
local trinket_1_duration = 0
local trinket_2_duration = 0
local trinket_priority = false
local damage_trinket_priority = false
local trinket_1_manual = false
local trinket_2_manual = false
local rw_buffs = false
local breath_rp_cost = 0
local static_rime_buffs = false
local breath_rp_threshold = false
local erw_breath_rp_trigger = 70
local erw_breath_rune_trigger = 3
local oblit_rune_pooling = 4
local breath_rime_rp_threshold = 60
local st_planning = false
local adds_remain = false
local use_breath = false
local sending_cds = false
local rime_buffs = false
local rp_buffs = false
local cooldown_check = false
local true_breath_cooldown = 0
local oblit_pooling_time = false
local breath_pooling_time = false
local pooling_runes = false
local pooling_runic_power = false
local ga_priority = false
local breath_dying = false
local fwf_buffs = false


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
    local MHenchant
    local OHenchant
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
    if MaxDps:HasOnUseEffect('13') and (talents[classtable.PillarofFrost] and not talents[classtable.BreathofSindragosa] and (math.fmod(MaxDps:CheckTrinketCooldownDuration('13') , cooldown[classtable.PillarofFrost].duration) == 0) or talents[classtable.BreathofSindragosa] and (math.fmod(cooldown[classtable.BreathofSindragosa].duration , MaxDps:CheckTrinketCooldownDuration('13')) == 0)) then
        trinket_1_sync = 1
    else
        trinket_1_sync = 0.5
    end
    if MaxDps:HasOnUseEffect('14') and (talents[classtable.PillarofFrost] and not talents[classtable.BreathofSindragosa] and (math.fmod(MaxDps:CheckTrinketCooldownDuration('14') , cooldown[classtable.PillarofFrost].duration) == 0) or talents[classtable.BreathofSindragosa] and (math.fmod(cooldown[classtable.BreathofSindragosa].duration , MaxDps:CheckTrinketCooldownDuration('14')) == 0)) then
        trinket_2_sync = 1
    else
        trinket_2_sync = 0.5
    end
    trinket_1_buffs = MaxDps:HasOnUseEffect('13') and (MaxDps:HasOnUseEffect('13') or MaxDps:HasBuffEffect('13', 'strength') or MaxDps:HasBuffEffect('13', 'mastery') or MaxDps:HasBuffEffect('13', 'versatility') or MaxDps:HasBuffEffect('13', 'haste') or MaxDps:HasBuffEffect('13', 'crit')) or MaxDps:CheckTrinketNames('TreacherousTransmitter')
    trinket_2_buffs = MaxDps:HasOnUseEffect('14') and (MaxDps:HasOnUseEffect('14') or MaxDps:HasBuffEffect('14', 'strength') or MaxDps:HasBuffEffect('14', 'mastery') or MaxDps:HasBuffEffect('14', 'versatility') or MaxDps:HasBuffEffect('14', 'haste') or MaxDps:HasBuffEffect('14', 'crit')) or MaxDps:CheckTrinketNames('TreacherousTransmitter')
    if MaxDps:CheckTrinketNames('TreacherousTransmitter') then
        trinket_1_duration = 15
    else
        trinket_1_duration = 1
    end
    if MaxDps:CheckTrinketNames('TreacherousTransmitter') then
        trinket_2_duration = 15
    else
        trinket_2_duration = 1
    end
    if not trinket_1_buffs and trinket_2_buffs and (MaxDps:HasOnUseEffect('14') or not MaxDps:HasOnUseEffect('13')) or trinket_2_buffs and ((MaxDps:CheckTrinketCooldownDuration('14')%trinket_2_duration)*(1.5 + (MaxDps:HasBuffEffect('14', 'strength') and 1 or 0))*(trinket_2_sync)*(1+((MaxDps:CheckTrinketItemLevel('14') - MaxDps:CheckTrinketItemLevel('13'))%100)))>((MaxDps:CheckTrinketCooldownDuration('13')%trinket_1_duration)*(1.5 + (MaxDps:HasBuffEffect('13', 'strength') and 1 or 0))*(trinket_1_sync)*(1+((MaxDps:CheckTrinketItemLevel('13') - MaxDps:CheckTrinketItemLevel('14'))%100))) then
        trinket_priority = 2
    else
        trinket_priority = true
    end
    if not trinket_1_buffs and not trinket_2_buffs and MaxDps:CheckTrinketItemLevel('14') >= MaxDps:CheckTrinketItemLevel('13') then
        damage_trinket_priority = 2
    else
        damage_trinket_priority = true
    end
    trinket_1_manual = MaxDps:CheckTrinketNames('AlgetharPuzzleBox') or MaxDps:CheckTrinketNames('TreacherousTransmitter')
    trinket_2_manual = MaxDps:CheckTrinketNames('AlgetharPuzzleBox') or MaxDps:CheckTrinketNames('TreacherousTransmitter')
    rw_buffs = talents[classtable.GatheringStorm] or talents[classtable.BitingCold]
    breath_rp_cost = 17
    static_rime_buffs = talents[classtable.RageoftheFrozenChampion] or talents[classtable.Icebreaker] or talents[classtable.BindInDarkness]
    breath_rp_threshold = false
    erw_breath_rp_trigger = 70
    erw_breath_rune_trigger = 3
    oblit_rune_pooling = 4
    breath_rime_rp_threshold = 60
end
function Frost:cold_heart()
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (ttd <gcd and (Runes <2 or not buff[classtable.KillingMachineBuff].up and (not twoh_check() and buff[classtable.ColdHeartBuff].count >= 4 or twoh_check() and buff[classtable.ColdHeartBuff].count >8) or buff[classtable.KillingMachineBuff].up and (not twoh_check() and buff[classtable.ColdHeartBuff].count >8 or twoh_check() and buff[classtable.ColdHeartBuff].count >10))) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].up and buff[classtable.ColdHeartBuff].count >= 10 and (buff[classtable.PillarofFrostBuff].remains <gcd*(1+(((talents[classtable.FrostwyrmsFury] and talents[classtable.FrostwyrmsFury] or 0) and cooldown[classtable.FrostwyrmsFury].ready) and 1 or 0)) or buff[classtable.UnholyStrengthBuff].up and buff[classtable.UnholyStrengthBuff].remains <gcd)) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and wep_rune_check('Rune of fallen_crusader') and not buff[classtable.PillarofFrostBuff].up and cooldown[classtable.PillarofFrost].remains >15 and (buff[classtable.ColdHeartBuff].count >= 10 and buff[classtable.UnholyStrengthBuff].up or buff[classtable.ColdHeartBuff].count >= 13)) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and not wep_rune_check('Rune of fallen_crusader') and buff[classtable.ColdHeartBuff].count >= 10 and not buff[classtable.PillarofFrostBuff].up and cooldown[classtable.PillarofFrost].remains >20) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up and (buff[classtable.ColdHeartBuff].count >= 14 and buff[classtable.UnholyStrengthBuff].up or buff[classtable.ColdHeartBuff].count >= 19 or cooldown[classtable.PillarofFrost].remains <3 and buff[classtable.ColdHeartBuff].count >= 14)) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
end
function Frost:breath()
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].count == 2) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and ttd >5 and RunicPower >50) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and ((rime_buffs or not buff[classtable.KillingMachineBuff].up and buff[classtable.PillarofFrostBuff].up and talents[classtable.Obliteration] and not buff[classtable.BonegrinderFrostBuff].up) and RunicPower>(breath_rime_rp_threshold-((talents[classtable.RageoftheFrozenChampion] and talents[classtable.RageoftheFrozenChampion] or 0) * 6)) or not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >30 and (not buff[classtable.EmpowerRuneWeaponBuff].up or RunicPower <breath_rp_cost*2 * gcd)) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up or RunicPowerDeficit >20) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and ttd >5 and targets == 1 and Runes >2) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.RemorselessWinter, 'RemorselessWinter')) and (breath_dying) and cooldown[classtable.RemorselessWinter].ready then
        if not setSpell then setSpell = classtable.RemorselessWinter end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and (st_planning and talents[classtable.UnholyGround] and RunicPowerDeficit >= 10 and not talents[classtable.Obliteration] or breath_dying)) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (breath_dying) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
end
function Frost:obliteration()
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up and (buff[classtable.ExterminateBuff].up or ttd <gcd*2)) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and rime_buffs) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance') and talents[classtable.GlacialAdvance]) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and not buff[classtable.DeathandDecayBuff].up and ga_priority) and cooldown[classtable.GlacialAdvance].ready then
        if not setSpell then setSpell = classtable.GlacialAdvance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and not buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and talents[classtable.AFeastofSouls] and buff[classtable.AFeastofSoulsBuff].up) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and ttd >5 and targets == 1 and Runes >2 and not buff[classtable.KillingMachineBuff].up) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and ttd >5 and Runes >2) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not buff[classtable.KillingMachineBuff].up and (not debuff[classtable.FrostFeverDeBuff].up)) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance') and talents[classtable.GlacialAdvance]) and ((ga_priority or debuff[classtable.RazoriceDeBuff].count <5) and (not wep_rune_check('Rune of Razorice') and (debuff[classtable.RazoriceDeBuff].count <5 or debuff[classtable.RazoriceDeBuff].remains <gcd*3) or ((rp_buffs or Runes <2) and targets >1))) and cooldown[classtable.GlacialAdvance].ready then
        if not setSpell then setSpell = classtable.GlacialAdvance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and ((Runes <2 or rp_buffs or debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade]) and not pooling_runic_power and (not talents[classtable.GlacialAdvance] or targets == 1 or talents[classtable.ShatteredFrost])) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and (not talents[classtable.GlacialAdvance] or targets == 1 or talents[classtable.ShatteredFrost])) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance') and talents[classtable.GlacialAdvance]) and (not pooling_runic_power and ga_priority) and cooldown[classtable.GlacialAdvance].ready then
        if not setSpell then setSpell = classtable.GlacialAdvance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and (Runes <3) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not buff[classtable.KillingMachineBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
end
function Frost:aoe()
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up and talents[classtable.CleavingStrikes] and buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and (talents[classtable.ShatteredFrost] or targets <4)) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].count >0) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance') and talents[classtable.GlacialAdvance]) and (not pooling_runic_power and (ga_priority or debuff[classtable.RazoriceDeBuff].count <5)) and cooldown[classtable.GlacialAdvance].ready then
        if not setSpell then setSpell = classtable.GlacialAdvance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >25 and (not talents[classtable.BreathofSindragosa] or true_breath_cooldown >cooldown[classtable.HornofWinter].duration-15)) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end
function Frost:single_target()
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (talents[classtable.AFeastofSouls] and debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and buff[classtable.AFeastofSoulsBuff].up) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].count == 2 or buff[classtable.ExterminateBuff].up) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and ((debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade]) or (Runes <2 and not talents[classtable.Icebreaker])) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and ttd >5 and not buff[classtable.KillingMachineBuff].up) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (rime_buffs) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up and not pooling_runes) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and ttd >5 and Runes >2) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and (rp_buffs or (not talents[classtable.ShatteringBlade] and RunicPowerDeficit <20))) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and not (twoh_check() or talents[classtable.ShatteringBlade])) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (not pooling_runes and twoh_check()) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (not pooling_runes) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >25 and (not talents[classtable.BreathofSindragosa] or true_breath_cooldown >cooldown[classtable.HornofWinter].duration-15)) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.MindFreeze, false)
    MaxDps:GlowCooldown(classtable.treacherous_transmitter, false)
    MaxDps:GlowCooldown(classtable.trinket1, false)
    MaxDps:GlowCooldown(classtable.trinket2, false)
    MaxDps:GlowCooldown(classtable.AbominationLimb, false)
    MaxDps:GlowCooldown(classtable.ChillStreak, false)
    MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, false)
    MaxDps:GlowCooldown(classtable.PillarofFrost, false)
    MaxDps:GlowCooldown(classtable.BreathofSindragosa, false)
    MaxDps:GlowCooldown(classtable.ReapersMark, false)
    MaxDps:GlowCooldown(classtable.FrostwyrmsFury, false)
    MaxDps:GlowCooldown(classtable.RaiseDead, false)
    MaxDps:GlowCooldown(classtable.HornofWinter, false)
end

function Frost:callaction()
    if (MaxDps:CheckSpellUsable(classtable.MindFreeze, 'MindFreeze')) and cooldown[classtable.MindFreeze].ready then
        MaxDps:GlowCooldown(classtable.MindFreeze, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    st_planning = targets == 1
    adds_remain = targets >1
    use_breath = st_planning or targets >= 2
    sending_cds = (st_planning or adds_remain)
    rime_buffs = buff[classtable.RimeBuff].up and (static_rime_buffs or talents[classtable.Avalanche] and not talents[classtable.ArcticAssault] and debuff[classtable.RazoriceDeBuff].count <5)
    rp_buffs = talents[classtable.UnleashedFrenzy] and (buff[classtable.UnleashedFrenzyBuff].remains <gcd*3 or buff[classtable.UnleashedFrenzyBuff].count <3) or talents[classtable.IcyTalons] and (buff[classtable.IcyTalonsBuff].remains <gcd*3 or buff[classtable.IcyTalonsBuff].count<(3+(2 * (talents[classtable.SmotheringOffense] and talents[classtable.SmotheringOffense] or 0))+(2 * (talents[classtable.DarkTalons] and talents[classtable.DarkTalons] or 0))))
    cooldown_check = (not talents[classtable.BreathofSindragosa] or buff[classtable.BreathofSindragosaBuff].up) and (talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and (talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].remains >10 or not talents[classtable.Obliteration]) or not talents[classtable.PillarofFrost] and buff[classtable.EmpowerRuneWeaponBuff].up or not talents[classtable.PillarofFrost] and not talents[classtable.EmpowerRuneWeapon] or targets >= 2 and buff[classtable.PillarofFrostBuff].up)
    if cooldown[classtable.BreathofSindragosa].remains >cooldown[classtable.PillarofFrost].remains then
        true_breath_cooldown = cooldown[classtable.BreathofSindragosa].remains
    else
        true_breath_cooldown = cooldown[classtable.PillarofFrost].remains
    end
    if RunicPower <35 and Runes <2 and cooldown[classtable.PillarofFrost].remains <10 then
        oblit_pooling_time = ((cooldown[classtable.PillarofFrost].remains + 1)%gcd)%((Runes + 1)*((RunicPower + 5)))*100
    else
        oblit_pooling_time = 3
    end
    if RunicPowerDeficit >10 and true_breath_cooldown <10 then
        breath_pooling_time = ((true_breath_cooldown + 1)%gcd)%((Runes + 1)*(RunicPower + 20))*100
    else
        breath_pooling_time = false
    end
    pooling_runes = Runes <oblit_rune_pooling and talents[classtable.Obliteration] and (not talents[classtable.BreathofSindragosa] or true_breath_cooldown >0) and cooldown[classtable.PillarofFrost].remains <oblit_pooling_time
    pooling_runic_power = talents[classtable.BreathofSindragosa] and (true_breath_cooldown <breath_pooling_time or ttd <30 and cooldown[classtable.BreathofSindragosa].ready) or talents[classtable.Obliteration] and (not talents[classtable.BreathofSindragosa] or cooldown[classtable.BreathofSindragosa].remains >30) and RunicPower <35 and cooldown[classtable.PillarofFrost].remains <oblit_pooling_time
    ga_priority = (not talents[classtable.ShatteredFrost] and talents[classtable.ShatteringBlade] and targets >= 4) or (not talents[classtable.ShatteredFrost] and not talents[classtable.ShatteringBlade] and targets >= 2)
    breath_dying = RunicPower <breath_rp_cost*2 * gcd and DeathKnight:TimeToRunes(2) >RunicPower%breath_rp_cost
    fwf_buffs = (buff[classtable.PillarofFrostBuff].remains <gcd or (buff[classtable.UnholyStrengthBuff].up and buff[classtable.UnholyStrengthBuff].remains <gcd) or ((talents[classtable.Bonegrinder] and talents[classtable.Bonegrinder] or 0) == 2 and buff[classtable.BonegrinderFrostBuff].up and buff[classtable.BonegrinderFrostBuff].remains <gcd)) and (targets >1 or debuff[classtable.RazoriceDeBuff].count == 5 or not wep_rune_check('Rune of Razorice') and (not talents[classtable.GlacialAdvance] or not talents[classtable.Avalanche] or not talents[classtable.ArcticAssault]) or talents[classtable.ShatteringBlade])
    if (MaxDps:CheckSpellUsable(classtable.treacherous_transmitter, 'treacherous_transmitter')) and (cooldown[classtable.PillarofFrost].remains <6 and sending_cds and (trinket_1_buffs and trinket_2_buffs or not talents[classtable.BreathofSindragosa] or cooldown[classtable.BreathofSindragosa].remains <6) or MaxDps:boss() and ttd <30) and cooldown[classtable.treacherous_transmitter].ready then
        MaxDps:GlowCooldown(classtable.treacherous_transmitter, cooldown[classtable.treacherous_transmitter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not (0 >0) and trinket_1_buffs and not trinket_1_manual and ((not trinket_2_buffs and buff[classtable.BreathofSindragosaBuff].up or not talents[classtable.BreathofSindragosa] or trinket_2_buffs) and buff[classtable.PillarofFrostBuff].remains >trinket_1_duration%2) and (not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('14') or trinket_priority == 1)) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not (0 >0) and trinket_2_buffs and not trinket_2_manual and ((not trinket_1_buffs and buff[classtable.BreathofSindragosaBuff].up or not talents[classtable.BreathofSindragosa] or trinket_2_buffs) and buff[classtable.PillarofFrostBuff].remains >trinket_2_duration%2) and (not MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketCooldown('13') or trinket_priority == 2)) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (0 >0 and trinket_1_buffs and not trinket_1_manual and not buff[classtable.PillarofFrostBuff].up and (not talents[classtable.BreathofSindragosa] or not buff[classtable.BreathofSindragosaBuff].up and RunicPower >breath_rp_threshold and ((buff[classtable.PillarofFrostBuff].remains >6 or cooldown[classtable.PillarofFrost].ready) and sending_cds)) and (not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('14') or trinket_priority == 1) or trinket_1_duration >= ttd and MaxDps:boss()) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (0 >0 and trinket_2_buffs and not trinket_2_manual and not buff[classtable.PillarofFrostBuff].up and (not talents[classtable.BreathofSindragosa] or not buff[classtable.BreathofSindragosaBuff].up and RunicPower >breath_rp_threshold and ((buff[classtable.PillarofFrostBuff].remains >6 or cooldown[classtable.PillarofFrost].ready) and sending_cds)) and (not MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketCooldown('13') or trinket_priority == 2) or trinket_2_duration >= ttd and MaxDps:boss()) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket1, 'trinket1')) and (not trinket_1_buffs and not trinket_1_manual and (damage_trinket_priority == 1 or (not MaxDps:HasOnUseEffect('14') or MaxDps:CheckTrinketCooldown('14'))) and ((0 >0 and (not talents[classtable.BreathofSindragosa] or not buff[classtable.BreathofSindragosaBuff].up or not breath_dying) and not buff[classtable.PillarofFrostBuff].up or not (0 >0)) and (not trinket_2_buffs or cooldown[classtable.PillarofFrost].remains >20) or not talents[classtable.PillarofFrost]) or MaxDps:boss() and ttd <15) and cooldown[classtable.trinket1].ready then
        MaxDps:GlowCooldown(classtable.trinket1, cooldown[classtable.trinket1].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.trinket2, 'trinket2')) and (not trinket_2_buffs and not trinket_2_manual and (damage_trinket_priority == 2 or (not MaxDps:HasOnUseEffect('13') or MaxDps:CheckTrinketCooldown('13'))) and ((0 >0 and (not talents[classtable.BreathofSindragosa] or not buff[classtable.BreathofSindragosaBuff].up or not breath_dying) and not buff[classtable.PillarofFrostBuff].up or not (0 >0)) and (not trinket_1_buffs or cooldown[classtable.PillarofFrost].remains >20) or not talents[classtable.PillarofFrost]) or MaxDps:boss() and ttd <15) and cooldown[classtable.trinket2].ready then
        MaxDps:GlowCooldown(classtable.trinket2, cooldown[classtable.trinket2].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.main_hand, 'main_hand')) and (buff[classtable.PillarofFrostBuff].up or (trinket_1_buffs and trinket_2_buffs and (MaxDps:CheckTrinketCooldown('13') <cooldown[classtable.PillarofFrost].remains or MaxDps:CheckTrinketCooldown('14') <cooldown[classtable.PillarofFrost].remains) and cooldown[classtable.PillarofFrost].remains >20) or MaxDps:boss() and ttd <15) and cooldown[classtable.main_hand].ready then
        if not setSpell then setSpell = classtable.main_hand end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up and targets >= 2 and (not talents[classtable.BreathofSindragosa] or not buff[classtable.BreathofSindragosaBuff].up) and (not talents[classtable.Obliteration] or talents[classtable.WitherAway] or talents[classtable.Obliteration] and (not cooldown[classtable.PillarofFrost].ready or buff[classtable.PillarofFrostBuff].up and not buff[classtable.KillingMachineBuff].up))) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up and sending_cds and (not (MaxDps.ActiveHeroTree == 'deathbringer') or cooldown[classtable.ReapersMark].remains <5) or MaxDps:boss() and ttd <15) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (not talents[classtable.Obliteration] and sending_cds) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RemorselessWinter, 'RemorselessWinter')) and (rw_buffs and sending_cds and (not talents[classtable.ArcticAssault] or not buff[classtable.PillarofFrostBuff].up) and (cooldown[classtable.PillarofFrost].remains >20 or cooldown[classtable.PillarofFrost].remains <gcd*3 or (buff[classtable.GatheringStormBuff].count == 10 and buff[classtable.RemorselessWinterBuff].remains <gcd)) and ttd >10) and cooldown[classtable.RemorselessWinter].ready then
        if not setSpell then setSpell = classtable.RemorselessWinter end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChillStreak, 'ChillStreak')) and (sending_cds and (not talents[classtable.ArcticAssault] or not buff[classtable.PillarofFrostBuff].up)) and cooldown[classtable.ChillStreak].ready then
        MaxDps:GlowCooldown(classtable.ChillStreak, cooldown[classtable.ChillStreak].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon') and talents[classtable.EmpowerRuneWeapon]) and (talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and buff[classtable.PillarofFrostBuff].up or MaxDps:boss() and ttd <20) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon') and talents[classtable.EmpowerRuneWeapon]) and (buff[classtable.BreathofSindragosaBuff].up and (RunicPower <40 or RunicPower <erw_breath_rp_trigger and Runes <erw_breath_rune_trigger)) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon') and talents[classtable.EmpowerRuneWeapon]) and (not talents[classtable.BreathofSindragosa] and not talents[classtable.Obliteration] and not buff[classtable.EmpowerRuneWeaponBuff].up and Runes <5 and (cooldown[classtable.PillarofFrost].remains <7 or buff[classtable.PillarofFrostBuff].up or not talents[classtable.PillarofFrost])) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost') and talents[classtable.PillarofFrost]) and (talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and sending_cds or MaxDps:boss() and ttd <20) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost') and talents[classtable.PillarofFrost]) and (talents[classtable.BreathofSindragosa] and sending_cds and (cooldown[classtable.BreathofSindragosa].remains >10 or not use_breath) and buff[classtable.UnleashedFrenzyBuff].up and (not (MaxDps.ActiveHeroTree == 'deathbringer') or Runes >1)) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost') and talents[classtable.PillarofFrost]) and (not talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and sending_cds) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BreathofSindragosa, 'BreathofSindragosa') and talents[classtable.BreathofSindragosa]) and (not buff[classtable.BreathofSindragosaBuff].up and RunicPower >breath_rp_threshold and (Runes <2 or RunicPower >80) and (cooldown[classtable.PillarofFrost].ready and use_breath or ttd <30) or (timeInCombat <10 and Runes <1)) and cooldown[classtable.BreathofSindragosa].ready then
        MaxDps:GlowCooldown(classtable.BreathofSindragosa, cooldown[classtable.BreathofSindragosa].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ReapersMark, 'ReapersMark')) and ((MaxDps:boss() or ttd >13) and not debuff[classtable.ReapersMarkDeBuff].up and (buff[classtable.PillarofFrostBuff].up or cooldown[classtable.PillarofFrost].remains >5)) and cooldown[classtable.ReapersMark].ready then
        MaxDps:GlowCooldown(classtable.ReapersMark, cooldown[classtable.ReapersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and ((MaxDps.ActiveHeroTree == 'rideroftheapocalypse') and talents[classtable.ApocalypseNow] and sending_cds and (not talents[classtable.BreathofSindragosa] and buff[classtable.PillarofFrostBuff].up or buff[classtable.BreathofSindragosaBuff].up) or MaxDps:boss() and ttd <20) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and targets == 1 and (talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and not talents[classtable.Obliteration] or not talents[classtable.PillarofFrost]) and fwf_buffs or MaxDps:boss() and ttd <3) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and targets >= 2 and (talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up or (targets >1) and (targets >1)) and fwf_buffs) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and talents[classtable.Obliteration] and (talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and not twoh_check() or not buff[classtable.PillarofFrostBuff].up and twoh_check() and not cooldown[classtable.PillarofFrost].ready or not talents[classtable.PillarofFrost]) and fwf_buffs) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and (not UnitExists('pet') and buff[classtable.PillarofFrostBuff].up) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostscythe, 'Frostscythe')) and (not buff[classtable.KillingMachineBuff].up and not buff[classtable.PillarofFrostBuff].up) and cooldown[classtable.Frostscythe].ready then
        if not setSpell then setSpell = classtable.Frostscythe end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and ((MaxDps.ActiveHeroTree == 'deathbringer') and not buff[classtable.DeathandDecayBuff].up and st_planning and cooldown[classtable.ReapersMark].remains <gcd*2 and Runes >2) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and targets >1 and ttd >5 and (buff[classtable.PillarofFrostBuff].up and buff[classtable.KillingMachineBuff].up and (talents[classtable.EnduringStrength] or buff[classtable.PillarofFrostBuff].remains >5)) and (targets >5 or talents[classtable.CleavingStrikes] and targets >= 2)) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and targets >1 and ttd >5 and (not buff[classtable.PillarofFrostBuff].up and (cooldown[classtable.DeathandDecay].charges == 2 and not cooldown[classtable.PillarofFrost].ready)) and (targets >5 or talents[classtable.CleavingStrikes] and targets >= 2)) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and targets >1 and ttd >5 and (not buff[classtable.PillarofFrostBuff].up and (cooldown[classtable.DeathandDecay].charges == 1 and cooldown[classtable.PillarofFrost].remains>(cooldown[classtable.DeathandDecay].duration-(cooldown[classtable.DeathandDecay].duration*(math.fmod(cooldown[classtable.DeathandDecay].charges , 1)))))) and (targets >5 or talents[classtable.CleavingStrikes] and targets >= 2)) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and targets >1 and ttd >5 and (not buff[classtable.PillarofFrostBuff].up and (not talents[classtable.TheLongWinter] and cooldown[classtable.PillarofFrost].remains <gcd*2) or ttd <15) and (targets >5 or talents[classtable.CleavingStrikes] and targets >= 2)) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and (cooldown_check) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
    end
    if (talents[classtable.ColdHeart] and (not buff[classtable.KillingMachineBuff].up or talents[classtable.BreathofSindragosa]) and ((debuff[classtable.RazoriceDeBuff].count == 5 or not wep_rune_check('Rune of Razorice') and not talents[classtable.GlacialAdvance] and not talents[classtable.Avalanche] and not talents[classtable.ArcticAssault]) or MaxDps:boss() and ttd <= gcd)) then
        Frost:cold_heart()
    end
    if (buff[classtable.BreathofSindragosaBuff].up or buff[classtable.BreathofSindragosaBuff].remains >0) then
        Frost:breath()
    end
    if (talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].up and not buff[classtable.BreathofSindragosaBuff].up) then
        Frost:obliteration()
    end
    if (targets >= 2) then
        Frost:aoe()
    end
    if (targets == 1) then
        Frost:single_target()
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
    targetHP = UnitHealth('target')
    targetmaxHP = UnitHealthMax('target')
    targethealthPerc = (targetHP >0 and targetmaxHP >0 and (targetHP / targetmaxHP) * 100) or 100
    curentHP = UnitHealth('player')
    maxHP = UnitHealthMax('player')
    healthPerc = (curentHP / maxHP) * 100
    timeInCombat = MaxDps.combatTime or 0
    classtable = MaxDps.SpellTable
    local trinket1ID = GetInventoryItemID('player', 13)
    local trinket2ID = GetInventoryItemID('player', 14)
    classtable.trinket1 = (trinket1ID and select(2,GetItemSpell(trinket1ID)) ) or 0
    classtable.trinket2 = (trinket2ID and select(2,GetItemSpell(trinket2ID)) ) or 0
    Runes = UnitPower('player', RunesPT)
    RunesMax = UnitPowerMax('player', RunesPT)
    RunesDeficit = RunesMax - Runes
    RunesPerc = (Runes / RunesMax) * 100
    RunesRegen = GetPowerRegenForPowerType(RunesPT)
    RunesTimeToMax = RunesDeficit / RunesRegen
    RunicPower = UnitPower('player', RunicPowerPT)
    RunicPowerMax = UnitPowerMax('player', RunicPowerPT)
    RunicPowerDeficit = RunicPowerMax - RunicPower
    RunicPowerPerc = (RunicPower / RunicPowerMax) * 100
    RunicPowerRegen = GetPowerRegenForPowerType(RunicPowerPT)
    RunicPowerTimeToMax = RunicPowerDeficit / RunicPowerRegen
    RuneBlood = UnitPower('player', RuneBloodPT)
    RuneFrost = UnitPower('player', RuneFrostPT)
    RuneUnholy = UnitPower('player', RuneUnholyPT)
    SpellHaste = UnitSpellHaste('player')
    SpellCrit = GetCritChance()
    --for spellId in pairs(MaxDps.Flags) do
    --    self.Flags[spellId] = false
    --    self:ClearGlowIndependent(spellId, spellId)
    --end
    classtable.RimeBuff = 59052
    classtable.UnleashedFrenzyBuff = 376907
    classtable.IcyTalonsBuff = 194879
    classtable.BreathofSindragosaBuff = 152279
    classtable.PillarofFrostBuff = 51271
    classtable.EmpowerRuneWeaponBuff = 47568
    classtable.UnholyStrengthBuff = 53365
    classtable.BonegrinderFrostBuff = 377103
    classtable.KillingMachineBuff = 51124
    classtable.GatheringStormBuff = 194912
    classtable.RemorselessWinterBuff = 196770
    classtable.DeathandDecayBuff = 188290
    classtable.ColdHeartBuff = 281208
    classtable.ExterminateBuff = 441416
    classtable.AFeastofSoulsBuff = 440861
    classtable.RazoriceDeBuff = 51714
    classtable.FrostFeverDeBuff = 55095
    classtable.ReapersMarkDeBuff = 434765
    classtable.ArcanePulse = 260369

    local function debugg()
        talents[classtable.BreathofSindragosa] = 1
        talents[classtable.PillarofFrost] = 1
        talents[classtable.Obliteration] = 1
        talents[classtable.WitherAway] = 1
        talents[classtable.EmpowerRuneWeapon] = 1
        talents[classtable.ArcticAssault] = 1
        talents[classtable.ApocalypseNow] = 1
        talents[classtable.EnduringStrength] = 1
        talents[classtable.CleavingStrikes] = 1
        talents[classtable.TheLongWinter] = 1
        talents[classtable.ColdHeart] = 1
        talents[classtable.GlacialAdvance] = 1
        talents[classtable.Avalanche] = 1
        talents[classtable.UnholyGround] = 1
        talents[classtable.ShatteringBlade] = 1
        talents[classtable.AFeastofSouls] = 1
        talents[classtable.ShatteredFrost] = 1
        talents[classtable.Icebreaker] = 1
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
