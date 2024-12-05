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

local trinket_one_sync
local trinket_two_sync
local trinket_one_buffs
local trinket_two_buffs
local trinket_one_duration
local trinket_two_duration
local trinket_priority
local damage_trinket_priority
local trinket_one_manual
local trinket_two_manual
local rw_buffs
local breath_rp_cost
local static_rime_buffs
local breath_rp_threshold
local erw_breath_rp_trigger
local erw_breath_rune_trigger
local oblit_rune_pooling
local breath_rime_rp_threshold
local st_planning
local adds_remain
local sending_cds
local rime_buffs
local rp_buffs
local cooldown_check
local true_breath_cooldown
local oblit_pooling_time
local breath_pooling_time
local pooling_runes
local pooling_runic_power
local ga_priority
local breath_dying
local fwf_buffs


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


function Frost:precombat()
    rw_buffs = talents[classtable.GatheringStorm] or talents[classtable.BitingCold]
    breath_rp_cost = 17
    static_rime_buffs = talents[classtable.RageoftheFrozenChampion] or talents[classtable.Icebreaker] or talents[classtable.BindInDarkness]
    breath_rp_threshold = 60
    erw_breath_rp_trigger = 70
    erw_breath_rune_trigger = 3
    oblit_rune_pooling = 4
    breath_rime_rp_threshold = 60
end
function Frost:cold_heart()
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (ttd <gcd and ( Runes <2 or not buff[classtable.KillingMachineBuff].up and ( not (twoh_check() == true and 2 or 1) and buff[classtable.ColdHeartBuff].count >= 4 or (twoh_check() == true and 2 or 1) and buff[classtable.ColdHeartBuff].count >8 ) or buff[classtable.KillingMachineBuff].up and ( not (twoh_check() == true and 2 or 1) and buff[classtable.ColdHeartBuff].count >8 or (twoh_check() == true and 2 or 1) and buff[classtable.ColdHeartBuff].count >10 ) )) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].up and buff[classtable.ColdHeartBuff].count >= 10 and ( buff[classtable.PillarofFrostBuff].remains <gcd * ( 1 + ( talents[classtable.FrostwyrmsFury] and cooldown[classtable.FrostwyrmsFury].ready and 1 or 0 ) ) or buff[classtable.UnholyStrengthBuff].up and buff[classtable.UnholyStrengthBuff].remains <gcd )) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and wep_rune_check('Rune of fallen_crusader') and not buff[classtable.PillarofFrostBuff].up and cooldown[classtable.PillarofFrost].remains >15 and ( buff[classtable.ColdHeartBuff].count >= 10 and buff[classtable.UnholyStrengthBuff].up or buff[classtable.ColdHeartBuff].count >= 13 )) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and not wep_rune_check('Rune of fallen_crusader') and buff[classtable.ColdHeartBuff].count >= 10 and not buff[classtable.PillarofFrostBuff].up and cooldown[classtable.PillarofFrost].remains >20) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChainsofIce, 'ChainsofIce')) and (talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up and ( buff[classtable.ColdHeartBuff].count >= 14 and buff[classtable.UnholyStrengthBuff].up or buff[classtable.ColdHeartBuff].count >= 19 or cooldown[classtable.PillarofFrost].remains <3 and buff[classtable.ColdHeartBuff].count >= 14 )) and cooldown[classtable.ChainsofIce].ready then
        if not setSpell then setSpell = classtable.ChainsofIce end
    end
end
function Frost:breath()
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].count == 2) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and MaxDps:GetTimeToPct(0) >5 and RunicPower >50) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (( rime_buffs or not buff[classtable.KillingMachineBuff].up and buff[classtable.PillarofFrostBuff].up and talents[classtable.Obliteration] and not buff[classtable.BonegrinderFrostBuff].up ) and RunicPower >( breath_rime_rp_threshold - ( (talents[classtable.RageoftheFrozenChampion] and talents[classtable.RageoftheFrozenChampion] or 0) * 6 ) ) or not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >30 and ( not buff[classtable.EmpowerRuneWeaponBuff].up or RunicPower <breath_rp_cost * 2 * gcd )) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up or RunicPowerDeficit >20) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.RemorselessWinter, 'RemorselessWinter')) and (breath_dying) and cooldown[classtable.RemorselessWinter].ready then
        if not setSpell then setSpell = classtable.RemorselessWinter end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not debuff[classtable.DeathandDecayDebuff].up and ( st_planning and talents[classtable.UnholyGround] and RunicPowerDeficit >= 10 and not talents[classtable.Obliteration] or breath_dying )) and cooldown[classtable.DeathandDecay].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up and ( buff[classtable.ExterminateBuff].up or ttd <gcd * 2 )) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and rime_buffs) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and not buff[classtable.DeathandDecayBuff].up and ga_priority) and cooldown[classtable.GlacialAdvance].ready then
        if not setSpell then setSpell = classtable.GlacialAdvance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and not buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and talents[classtable.AFeastofSouls] and buff[classtable.AFeastofSoulsBuff].up) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and MaxDps:GetTimeToPct(0) >5 and Runes >2) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not buff[classtable.KillingMachineBuff].up and ( not debuff[classtable.FrostFeverDeBuff].up )) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance')) and (( ga_priority or debuff[classtable.RazoriceDeBuff].count <5 ) and ( not wep_rune_check('Rune of Razorice') and ( debuff[classtable.RazoriceDeBuff].count <5 or debuff[classtable.RazoriceDeBuff].remains <gcd * 3 ) or ( ( rp_buffs or Runes <2 ) and targets >1 ) )) and cooldown[classtable.GlacialAdvance].ready then
        if not setSpell then setSpell = classtable.GlacialAdvance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (( Runes <2 or rp_buffs or debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] ) and not pooling_runic_power and ( not talents[classtable.GlacialAdvance] or targets == 1 or talents[classtable.ShatteredFrost] )) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and ( not talents[classtable.GlacialAdvance] or targets == 1 or talents[classtable.ShatteredFrost] )) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance')) and (not pooling_runic_power and ga_priority) and cooldown[classtable.GlacialAdvance].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and ( talents[classtable.ShatteredFrost] or targets <4 )) and cooldown[classtable.FrostStrike].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.GlacialAdvance, 'GlacialAdvance')) and (not pooling_runic_power and ( ga_priority or debuff[classtable.RazoriceDeBuff].count <5 )) and cooldown[classtable.GlacialAdvance].ready then
        if not setSpell then setSpell = classtable.GlacialAdvance end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >25 and ( not talents[classtable.BreathofSindragosa] or true_breath_cooldown >cooldown[classtable.HornofWinter].duration - 15 )) and cooldown[classtable.HornofWinter].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (( debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] ) or ( Runes <2 and not talents[classtable.Icebreaker] )) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (rime_buffs and talents[classtable.Icebreaker]) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up and not pooling_runes) and cooldown[classtable.Obliterate].ready then
        if not setSpell then setSpell = classtable.Obliterate end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and MaxDps:GetTimeToPct(0) >5 and Runes >2) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and ( rp_buffs or ( not talents[classtable.ShatteringBlade] and RunicPowerDeficit <20 ) )) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up and ( not talents[classtable.BreathofSindragosa] or talents[classtable.RageoftheFrozenChampion] or cooldown[classtable.BreathofSindragosa].ready==false )) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and not ( (twoh_check() == true and 2 or 1) or talents[classtable.ShatteringBlade] )) and cooldown[classtable.FrostStrike].ready then
        if not setSpell then setSpell = classtable.FrostStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Obliterate, 'Obliterate')) and (not pooling_runes and (twoh_check() == true and 2 or 1)) and cooldown[classtable.Obliterate].ready then
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
    if (MaxDps:CheckSpellUsable(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >25 and ( not talents[classtable.BreathofSindragosa] or true_breath_cooldown >cooldown[classtable.HornofWinter].duration - 15 )) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.MindFreeze, false)
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
    sending_cds = ( st_planning or adds_remain )
    rime_buffs = buff[classtable.RimeBuff].up and ( static_rime_buffs or talents[classtable.Avalanche] and not talents[classtable.ArcticAssault] and debuff[classtable.RazoriceDeBuff].count <5 )
    rp_buffs = talents[classtable.UnleashedFrenzy] and ( buff[classtable.UnleashedFrenzyBuff].remains <gcd * 3 or buff[classtable.UnleashedFrenzyBuff].count <3 ) or talents[classtable.IcyTalons] and ( buff[classtable.IcyTalonsBuff].remains <gcd * 3 or buff[classtable.IcyTalonsBuff].count <( 3 + ( 2 * (talents[classtable.Smotheringoffense] and talents[classtable.Smotheringoffense] or 0) ) + ( 2 * (talents[classtable.DarkTalons] and talents[classtable.DarkTalons] or 0) ) ) )
    cooldown_check = talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and ( talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].remains >10 or not talents[classtable.Obliteration] ) or not talents[classtable.PillarofFrost] and buff[classtable.EmpowerRuneWeaponBuff].up or not talents[classtable.PillarofFrost] and not talents[classtable.EmpowerRuneWeapon] or targets >= 2 and buff[classtable.PillarofFrostBuff].up
    if cooldown[classtable.BreathofSindragosa].remains >cooldown[classtable.PillarofFrost].remains then
        true_breath_cooldown = cooldown[classtable.BreathofSindragosa].remains
    else
        true_breath_cooldown = cooldown[classtable.PillarofFrost].remains
    end
    if RunicPower <35 and Runes <2 and cooldown[classtable.PillarofFrost].remains <10 then
        oblit_pooling_time = ( ( cooldown[classtable.PillarofFrost].remains + 1 ) % gcd ) % ( ( Runes + 1 ) * ( ( RunicPower + 5 ) ) ) * 100
    else
        oblit_pooling_time = 3
    end
    if RunicPowerDeficit >10 and true_breath_cooldown <10 then
        breath_pooling_time = ( ( true_breath_cooldown + 1 ) % gcd ) % ( ( Runes + 1 ) * ( RunicPower + 20 ) ) * 100
    else
        breath_pooling_time = 2
    end
    pooling_runes = Runes <oblit_rune_pooling and talents[classtable.Obliteration] and ( not talents[classtable.BreathofSindragosa] or true_breath_cooldown >0 ) and cooldown[classtable.PillarofFrost].remains <oblit_pooling_time
    pooling_runic_power = talents[classtable.BreathofSindragosa] and ( true_breath_cooldown <breath_pooling_time or ttd <30 and not cooldown[classtable.BreathofSindragosa].ready==false ) or talents[classtable.Obliteration] and ( not talents[classtable.BreathofSindragosa] or cooldown[classtable.BreathofSindragosa].remains >30 ) and RunicPower <35 and cooldown[classtable.PillarofFrost].remains <oblit_pooling_time
    ga_priority = ( not talents[classtable.ShatteredFrost] and talents[classtable.ShatteringBlade] and targets >= 4 ) or ( not talents[classtable.ShatteredFrost] and not talents[classtable.ShatteringBlade] and targets >= 2 )
    breath_dying = RunicPower <breath_rp_cost * 2 * gcd and DeathKnight:TimeToRunes(2) >RunicPower % breath_rp_cost
    fwf_buffs = ( buff[classtable.PillarofFrostBuff].remains <gcd or ( buff[classtable.UnholyStrengthBuff].up and buff[classtable.UnholyStrengthBuff].remains <gcd ) or ( (talents[classtable.Bonegrinder] and talents[classtable.Bonegrinder] or 0) == 2 and buff[classtable.BonegrinderFrostBuff].up and buff[classtable.BonegrinderFrostBuff].remains <gcd ) ) and ( targets >1 or debuff[classtable.RazoriceDeBuff].count == 5 or not wep_rune_check('Rune of Razorice') and ( not talents[classtable.GlacialAdvance] or not talents[classtable.Avalanche] or not talents[classtable.ArcticAssault] ) or talents[classtable.ShatteringBlade] )
    if (MaxDps:CheckSpellUsable(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up and targets >= 2 and ( not talents[classtable.Obliteration] or talents[classtable.WitherAway] or talents[classtable.Obliteration] and ( not cooldown[classtable.PillarofFrost].ready or buff[classtable.PillarofFrostBuff].up and not buff[classtable.KillingMachineBuff].up ) )) and cooldown[classtable.HowlingBlast].ready then
        if not setSpell then setSpell = classtable.HowlingBlast end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up and sending_cds and ( not (MaxDps.ActiveHeroTree == 'deathbringer') or cooldown[classtable.ReapersMark].remains <5 ) or MaxDps:boss() and ttd <15) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (not talents[classtable.Obliteration] and sending_cds) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RemorselessWinter, 'RemorselessWinter')) and (rw_buffs and sending_cds and ( not talents[classtable.ArcticAssault] or not buff[classtable.PillarofFrostBuff].up ) and ( cooldown[classtable.PillarofFrost].remains >20 or cooldown[classtable.PillarofFrost].remains <4 or ( buff[classtable.GatheringStormBuff].count == 10 and buff[classtable.RemorselessWinterBuff].remains <gcd ) ) and ttd >10) and cooldown[classtable.RemorselessWinter].ready then
        if not setSpell then setSpell = classtable.RemorselessWinter end
    end
    if (MaxDps:CheckSpellUsable(classtable.ChillStreak, 'ChillStreak')) and (sending_cds and ( not talents[classtable.ArcticAssault] or not buff[classtable.PillarofFrostBuff].up )) and cooldown[classtable.ChillStreak].ready then
        MaxDps:GlowCooldown(classtable.ChillStreak, cooldown[classtable.ChillStreak].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and buff[classtable.PillarofFrostBuff].up or MaxDps:boss() and ttd <20) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (buff[classtable.BreathofSindragosaBuff].up and ( RunicPower <40 or RunicPower <erw_breath_rp_trigger and Runes <erw_breath_rune_trigger )) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (not talents[classtable.BreathofSindragosa] and not talents[classtable.Obliteration] and not buff[classtable.EmpowerRuneWeaponBuff].up and Runes <5 and ( cooldown[classtable.PillarofFrost].remains <7 or buff[classtable.PillarofFrostBuff].up or not talents[classtable.PillarofFrost] )) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost')) and (talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and sending_cds or MaxDps:boss() and ttd <20) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost')) and (talents[classtable.BreathofSindragosa] and sending_cds and cooldown[classtable.BreathofSindragosa].ready==false and buff[classtable.UnleashedFrenzyBuff].up and ( not (MaxDps.ActiveHeroTree == 'deathbringer') or Runes >1 )) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.PillarofFrost, 'PillarofFrost')) and (not talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and sending_cds) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BreathofSindragosa, 'BreathofSindragosa')) and (not buff[classtable.BreathofSindragosaBuff].up and RunicPower >breath_rp_threshold and ( Runes <2 or RunicPower >80 ) and ( ( buff[classtable.PillarofFrostBuff].up or cooldown[classtable.PillarofFrost].remains >30 or cooldown[classtable.PillarofFrost].ready ) and sending_cds or ttd <30 ) or ( timeInCombat <10 and Runes <1 )) and cooldown[classtable.BreathofSindragosa].ready then
        MaxDps:GlowCooldown(classtable.BreathofSindragosa, cooldown[classtable.BreathofSindragosa].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ReapersMark, 'ReapersMark')) and (( MaxDps:boss() or ttd >13 ) and not debuff[classtable.ReapersMarkDebuffDeBuff].up and ( buff[classtable.PillarofFrostBuff].up or cooldown[classtable.PillarofFrost].remains >5 )) and cooldown[classtable.ReapersMark].ready then
        MaxDps:GlowCooldown(classtable.ReapersMark, cooldown[classtable.ReapersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and ((MaxDps.ActiveHeroTree == 'rideroftheapocalypse') and talents[classtable.ApocalypseNow] and sending_cds and ( not talents[classtable.BreathofSindragosa] and buff[classtable.PillarofFrostBuff].up or buff[classtable.BreathofSindragosaBuff].up ) or MaxDps:boss() and ttd <20) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and targets == 1 and ( talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and not talents[classtable.Obliteration] or not talents[classtable.PillarofFrost] ) and ( (targets <2) or math.huge >cooldown[classtable.FrostwyrmsFury].duration + (targets>1 and MaxDps:MaxAddDuration() or 0) ) and fwf_buffs or ttd <3) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and targets >= 2 and ( talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up or (targets >1) and (targets >1) and math.huge <cooldown[classtable.PillarofFrost].remains - math.huge - (targets>1 and MaxDps:MaxAddDuration() or 0) ) and fwf_buffs) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and talents[classtable.Obliteration] and ( talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and not main_hand.two_hand or not buff[classtable.PillarofFrostBuff].up and (twoh_check() == true and 2 or 1) and cooldown[classtable.PillarofFrost].ready==false or not talents[classtable.PillarofFrost] ) and fwf_buffs and ( (targets <2) or math.huge >cooldown[classtable.FrostwyrmsFury].duration + (targets>1 and MaxDps:MaxAddDuration() or 0) )) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and (buff[classtable.PillarofFrostBuff].up) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Frostscythe, 'Frostscythe')) and (not buff[classtable.KillingMachineBuff].up and not buff[classtable.PillarofFrostBuff].up) and cooldown[classtable.Frostscythe].ready then
        if not setSpell then setSpell = classtable.Frostscythe end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and ((MaxDps.ActiveHeroTree == 'deathbringer') and not buff[classtable.DeathandDecayBuff].up and st_planning and cooldown[classtable.ReapersMark].remains <gcd * 2) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and adds_remain and ( buff[classtable.PillarofFrostBuff].up and buff[classtable.KillingMachineBuff].up and ( talents[classtable.EnduringStrength] or buff[classtable.PillarofFrostBuff].remains >5 ) or not buff[classtable.PillarofFrostBuff].up and ( cooldown[classtable.DeathandDecay].charges == 2 or cooldown[classtable.PillarofFrost].remains >cooldown[classtable.DeathandDecay].duration or not talents[classtable.TheLongWinter] and cooldown[classtable.PillarofFrost].remains <gcd * 2 ) or ttd <15 ) and ( targets >5 or talents[classtable.CleavingStrikes] and targets >= 2 )) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.ArcanePulse, 'ArcanePulse')) and (cooldown_check) and cooldown[classtable.ArcanePulse].ready then
        if not setSpell then setSpell = classtable.ArcanePulse end
    end
    if (talents[classtable.ColdHeart] and ( not buff[classtable.KillingMachineBuff].up or talents[classtable.BreathofSindragosa] ) and ( ( debuff[classtable.RazoriceDeBuff].count == 5 or not wep_rune_check('Rune of Razorice') and not talents[classtable.GlacialAdvance] and not talents[classtable.Avalanche] and not talents[classtable.ArcticAssault] ) or MaxDps:boss() and ttd <= gcd )) then
        Frost:cold_heart()
    end
    if (buff[classtable.BreathofSindragosaBuff].up or breath_ticks_left >0) then
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
    classtable.KillingMachineBuff = 51124
    classtable.ColdHeartBuff = 281209
    classtable.PillarofFrostBuff = 51271
    classtable.UnholyStrengthBuff = 53365
    classtable.BonegrinderFrostBuff = 377098
    classtable.FrostFeverDeBuff = 55095
    classtable.EmpowerRuneWeaponBuff = 47568
    classtable.DeathandDecayDebuff = 52212
    classtable.RimeBuff = 59052
    classtable.ExterminateBuff = 441378
    classtable.DeathandDecayBuff = 188290
    classtable.RazoriceDeBuff = 51714
    classtable.AFeastofSoulsBuff = 440861
    classtable.UnleashedFrenzyBuff = 376907
    classtable.IcyTalonsBuff = 194879
    classtable.GatheringStormBuff = 194912
    classtable.RemorselessWinterBuff = 196770
    classtable.BreathofSindragosaBuff = 152279
    classtable.ReapersMarkDebuffDeBuff = 439594
    setSpell = nil
    ClearCDs()

    Frost:precombat()

    Frost:callaction()
    if setSpell then return setSpell end
end
