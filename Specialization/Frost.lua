local _, addonTable = ...
local DeathKnight = addonTable.DeathKnight
local MaxDps = _G.MaxDps
if not MaxDps then return end

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

local trinket_one_exclude
local trinket_two_exclude
local trinket_one_sync
local trinket_two_sync
local trinket_one_buffs
local trinket_two_buffs
local trinket_priority
local damage_trinket_priority
local trinket_one_manual
local trinket_two_manual
local rw_buffs
local two_hand_check
local static_obliterate_buffs
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

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if not C_Spell.IsSpellUsable(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) or (classtable.HuntersPreyBuff and not buff[classtable.HuntersPreyBuff].up) and targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'HammerofWrath' then
        if ( (classtable.AvengingWrathBuff and not buff[classtable.AvengingWrathBuff].up) or (classtable.FinalVerdictBuff and not buff[classtable.FinalVerdictBuff].up) ) and targethealthPerc > 20 then
            return false
        end
    end
    if spellstring == 'Execute' then
        if (classtable.SuddenDeathBuff and not buff[classtable.SuddenDeathBuff].up) and targethealthPerc > 35 then
            return false
        end
    end
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' and spellstring then return true end
    for i,costtable in pairs(costs) do
        if UnitPower('player', costtable.type) < costtable.cost then
            return false
        end
    end
    return true
end
local function MaxGetSpellCost(spell,power)
    local costs = C_Spell.GetSpellPowerCost(spell)
    if type(costs) ~= 'table' then return 0 end
    for i,costtable in pairs(costs) do
        if costtable.name == power then
            return costtable.cost
        end
    end
    return 0
end



local function CheckEquipped(checkName)
    for i=1,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = itemID and C_Item.GetItemInfo(itemID) or ''
        if checkName == itemName then
            return true
        end
    end
    return false
end




local function CheckTrinketNames(checkName)
    --if slot == 1 then
    --    slot = 13
    --end
    --if slot == 2 then
    --    slot = 14
    --end
    for i=13,14 do
        local itemID = GetInventoryItemID('player', i)
        local itemName = C_Item.GetItemInfo(itemID)
        if checkName == itemName then
            return true
        end
    end
    return false
end


local function CheckTrinketCooldown(slot)
    if slot == 1 then
        slot = 13
    end
    if slot == 2 then
        slot = 14
    end
    if slot == 13 or slot == 14 then
        local itemID = GetInventoryItemID('player', slot)
        local _, duration, _ = C_Item.GetItemCooldown(itemID)
        if duration == 0 then return true else return false end
    else
        local tOneitemID = GetInventoryItemID('player', 13)
        local tTwoitemID = GetInventoryItemID('player', 14)
        local tOneitemName = C_Item.GetItemInfo(tOneitemID)
        local tTwoitemName = C_Item.GetItemInfo(tTwoitemID)
        if tOneitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tOneitemID)
            if duration == 0 then return true else return false end
        end
        if tTwoitemName == slot then
            local _, duration, _ = C_Item.GetItemCooldown(tTwoitemID)
            if duration == 0 then return true else return false end
        end
    end
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


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
    end
end


local function CheckPrevSpell(spell)
    if MaxDps and MaxDps.spellHistory then
        if MaxDps.spellHistory[1] then
            if MaxDps.spellHistory[1] == spell then
                return true
            end
            if MaxDps.spellHistory[1] ~= spell then
                return false
            end
        end
    end
    return true
end


local function boss()
    if UnitExists('boss1')
    or UnitExists('boss2')
    or UnitExists('boss3')
    or UnitExists('boss4')
    or UnitExists('boss5')
    or UnitExists('boss6')
    or UnitExists('boss7')
    or UnitExists('boss8')
    or UnitExists('boss9')
    or UnitExists('boss10') then
        return true
    end
    return false
end


function Frost:precombat()
    rw_buffs = talents[classtable.GatheringStorm] or talents[classtable.BitingCold]
    two_hand_check = twoh_check()
    static_obliterate_buffs = talents[classtable.ArcticAssault] or talents[classtable.FrigidExecutioner] or two_hand_check
    breath_rp_cost = 17
    static_rime_buffs = talents[classtable.RageoftheFrozenChampion] or talents[classtable.Icebreaker]
    breath_rp_threshold = 60
    erw_breath_rp_trigger = 70
    erw_breath_rune_trigger = 3
    oblit_rune_pooling = 4
    breath_rime_rp_threshold = 60
end
function Frost:aoe()
    if (CheckSpellCosts(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up and talents[classtable.CleavingStrikes] and buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.Obliterate].ready then
        return classtable.Obliterate
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and ( talents[classtable.ShatteredFrost] or targets <4 )) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up or not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (not pooling_runic_power and ( ga_priority or debuff[classtable.RazoriceDeBuff].count <5 )) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.Obliterate, 'Obliterate')) and cooldown[classtable.Obliterate].ready then
        return classtable.Obliterate
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >25) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end
function Frost:breath()
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (rime_buffs and RunicPower >( breath_rime_rp_threshold - ( (talents[classtable.RageoftheFrozenChampion] and talents[classtable.RageoftheFrozenChampion] or 0) * 6 ) )) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >30 and ( not buff[classtable.EmpowerRuneWeaponBuff].up or breath_dying )) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
    if (CheckSpellCosts(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up or RunicPowerDeficit >20) and cooldown[classtable.Obliterate].ready then
        return classtable.Obliterate
    end
    if (CheckSpellCosts(classtable.RemorselessWinter, 'RemorselessWinter')) and (breath_dying) and cooldown[classtable.RemorselessWinter].ready then
        return classtable.RemorselessWinter
    end
    if (CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.MograinesMightBuff].up and st_planning and talents[classtable.UnholyGround] and not buff[classtable.DeathandDecayBuff].up and RunicPowerDeficit >= 10 and not talents[classtable.Obliteration] or breath_dying) and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (breath_dying) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
end
function Frost:cold_heart()
    if (CheckSpellCosts(classtable.ChainsofIce, 'ChainsofIce')) and (boss and ttd <gcd and ( Runes <2 or not buff[classtable.KillingMachineBuff].up and ( not two_hand_check and buff[classtable.ColdHeartBuff].count >= 4 or two_hand_check and buff[classtable.ColdHeartBuff].count >8 ) or buff[classtable.KillingMachineBuff].up and ( not two_hand_check and buff[classtable.ColdHeartBuff].count >8 or two_hand_check and buff[classtable.ColdHeartBuff].count >10 ) )) and cooldown[classtable.ChainsofIce].ready then
        return classtable.ChainsofIce
    end
    if (CheckSpellCosts(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].up and buff[classtable.ColdHeartBuff].count >= 10 and ( buff[classtable.PillarofFrostBuff].remains <gcd * ( 1 + ( talents[classtable.FrostwyrmsFury] and cooldown[classtable.FrostwyrmsFury].ready ) ) or buff[classtable.UnholyStrengthBuff].up and buff[classtable.UnholyStrengthBuff].remains <gcd )) and cooldown[classtable.ChainsofIce].ready then
        return classtable.ChainsofIce
    end
    if (CheckSpellCosts(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and wep_rune_check('Rune of fallen_crusader') and not buff[classtable.PillarofFrostBuff].up and cooldown[classtable.PillarofFrost].remains >15 and ( buff[classtable.ColdHeartBuff].count >= 10 and buff[classtable.UnholyStrengthBuff].up or buff[classtable.ColdHeartBuff].count >= 13 )) and cooldown[classtable.ChainsofIce].ready then
        return classtable.ChainsofIce
    end
    if (CheckSpellCosts(classtable.ChainsofIce, 'ChainsofIce')) and (not talents[classtable.Obliteration] and not wep_rune_check('Rune of fallen_crusader') and buff[classtable.ColdHeartBuff].count >= 10 and not buff[classtable.PillarofFrostBuff].up and cooldown[classtable.PillarofFrost].remains >20) and cooldown[classtable.ChainsofIce].ready then
        return classtable.ChainsofIce
    end
    if (CheckSpellCosts(classtable.ChainsofIce, 'ChainsofIce')) and (talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up and ( buff[classtable.ColdHeartBuff].count >= 14 and buff[classtable.UnholyStrengthBuff].up or buff[classtable.ColdHeartBuff].count >= 19 or cooldown[classtable.PillarofFrost].remains <3 and buff[classtable.ColdHeartBuff].count >= 14 )) and cooldown[classtable.ChainsofIce].ready then
        return classtable.ChainsofIce
    end
end
function Frost:cooldowns()
    if (CheckSpellCosts(classtable.AbominationLimb, 'AbominationLimb')) and (talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up and sending_cds or boss and ttd <15) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (CheckSpellCosts(classtable.AbominationLimb, 'AbominationLimb')) and (not talents[classtable.Obliteration] and sending_cds) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (CheckSpellCosts(classtable.RemorselessWinter, 'RemorselessWinter')) and (rw_buffs and sending_cds and ( not talents[classtable.ArcticAssault] or not buff[classtable.PillarofFrostBuff].up )) and cooldown[classtable.RemorselessWinter].ready then
        return classtable.RemorselessWinter
    end
    if (CheckSpellCosts(classtable.ChillStreak, 'ChillStreak')) and (sending_cds and ( not talents[classtable.ArcticAssault] or not buff[classtable.PillarofFrostBuff].up )) and cooldown[classtable.ChillStreak].ready then
        MaxDps:GlowCooldown(classtable.ChillStreak, cooldown[classtable.ChillStreak].ready)
    end
    if (CheckSpellCosts(classtable.ReapersMark, 'ReapersMark')) and (not debuff[classtable.ReapersMarkDebuffDeBuff].up) and cooldown[classtable.ReapersMark].ready then
        MaxDps:GlowCooldown(classtable.ReapersMark, cooldown[classtable.ReapersMark].ready)
    end
    if (CheckSpellCosts(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and buff[classtable.PillarofFrostBuff].up or boss and ttd <20) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (CheckSpellCosts(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (buff[classtable.BreathofSindragosaBuff].up and RunicPower <erw_breath_rp_trigger and Runes <erw_breath_rune_trigger) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (CheckSpellCosts(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (not talents[classtable.BreathofSindragosa] and not talents[classtable.Obliteration] and not buff[classtable.EmpowerRuneWeaponBuff].up and Runes <5 and ( cooldown[classtable.PillarofFrost].remains <7 or buff[classtable.PillarofFrostBuff].up or not talents[classtable.PillarofFrost] )) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (CheckSpellCosts(classtable.PillarofFrost, 'PillarofFrost')) and (talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and sending_cds or boss and ttd <20) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (CheckSpellCosts(classtable.PillarofFrost, 'PillarofFrost')) and (talents[classtable.BreathofSindragosa] and sending_cds and cooldown[classtable.BreathofSindragosa].remains) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (CheckSpellCosts(classtable.PillarofFrost, 'PillarofFrost')) and (not talents[classtable.Obliteration] and not talents[classtable.BreathofSindragosa] and sending_cds) and cooldown[classtable.PillarofFrost].ready then
        MaxDps:GlowCooldown(classtable.PillarofFrost, cooldown[classtable.PillarofFrost].ready)
    end
    if (CheckSpellCosts(classtable.BreathofSindragosa, 'BreathofSindragosa')) and (not buff[classtable.BreathofSindragosaBuff].up and RunicPower >breath_rp_threshold and ( cooldown[classtable.PillarofFrost].ready and sending_cds or boss and ttd <30 ) or ( timeInCombat <10 and Runes <1 )) and cooldown[classtable.BreathofSindragosa].ready then
        MaxDps:GlowCooldown(classtable.BreathofSindragosa, cooldown[classtable.BreathofSindragosa].ready)
    end
    if (CheckSpellCosts(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (talents[classtable.RideroftheApocalypse] and talents[classtable.ApocalypseNow] and sending_cds and ( not talents[classtable.BreathofSindragosa] and buff[classtable.PillarofFrostBuff].up or buff[classtable.BreathofSindragosaBuff].up ) or boss and ttd <30) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (CheckSpellCosts(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and targets == 1 and ( talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and not talents[classtable.Obliteration] or not talents[classtable.PillarofFrost] ) and ( (targets <2) or ( math.huge >15 + (targets>1 and MaxDps:MaxAddDuration() or 0) or talents[classtable.AbsoluteZero] and math.huge >15 + (targets>1 and MaxDps:MaxAddDuration() or 0) ) ) or boss and ttd <3) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (CheckSpellCosts(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and targets >= 2 and ( talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up or (targets >1) and (targets >1) and math.huge >cooldown[classtable.PillarofFrost].remains - math.huge - (targets>1 and MaxDps:MaxAddDuration() or 0) )) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (CheckSpellCosts(classtable.FrostwyrmsFury, 'FrostwyrmsFury')) and (not talents[classtable.ApocalypseNow] and talents[classtable.Obliteration] and ( talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and not two_hand_check or not buff[classtable.PillarofFrostBuff].up and two_hand_check and cooldown[classtable.PillarofFrost].ready==false or not talents[classtable.PillarofFrost] ) and ( ( buff[classtable.PillarofFrostBuff].remains <gcd or buff[classtable.UnholyStrengthBuff].up ) and ( debuff[classtable.RazoriceDeBuff].count == 5 or not wep_rune_check('Rune of Razorice') and not talents[classtable.GlacialAdvance] ) )) and cooldown[classtable.FrostwyrmsFury].ready then
        MaxDps:GlowCooldown(classtable.FrostwyrmsFury, cooldown[classtable.FrostwyrmsFury].ready)
    end
    if (CheckSpellCosts(classtable.RaiseDead, 'RaiseDead')) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (ttd >5 and MaxDps:GetTimeToPct(35) <5 and MaxDps:GetTimeToPct(0) >5 and targets <= 2 and ( talents[classtable.Obliteration] and ( buff[classtable.PillarofFrostBuff].up and not buff[classtable.KillingMachineBuff].up and Runes >2 or not buff[classtable.PillarofFrostBuff].up ) or talents[classtable.BreathofSindragosa] and ( buff[classtable.BreathofSindragosaBuff].up and RunicPower >50 or not buff[classtable.BreathofSindragosaBuff].up ) or not talents[classtable.BreathofSindragosa] and not talents[classtable.Obliteration] )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (CheckSpellCosts(classtable.Frostscythe, 'Frostscythe')) and (not buff[classtable.KillingMachineBuff].up and ( not talents[classtable.ArcticAssault] or not buff[classtable.PillarofFrostBuff].up )) and cooldown[classtable.Frostscythe].ready then
        return classtable.Frostscythe
    end
    if (CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and not buff[classtable.MograinesMightBuff].up and adds_remain and ( buff[classtable.PillarofFrostBuff].up and buff[classtable.KillingMachineBuff].up and ( talents[classtable.EnduringStrength] or buff[classtable.PillarofFrostBuff].remains >5 ) or not buff[classtable.PillarofFrostBuff].up and ( cooldown[classtable.DeathandDecay].charges == 2 or cooldown[classtable.PillarofFrost].remains >cooldown[classtable.DeathandDecay].duration ) or not talents[classtable.TheLongWinter] and cooldown[classtable.PillarofFrost].remains <gcd * 2 or boss and boss and ttd <11 ) and ( targets >5 or talents[classtable.CleavingStrikes] and targets >= 2 )) and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
end
function Frost:high_prio()
    if (CheckSpellCosts(classtable.MindFreeze, 'MindFreeze')) and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and cooldown[classtable.MindFreeze].ready then
        MaxDps:GlowCooldown(classtable.MindFreeze, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up and targets >= 2 and ( ( not talents[classtable.Obliteration] or talents[classtable.Obliteration] and ( not cooldown[classtable.PillarofFrost].ready or buff[classtable.PillarofFrostBuff].up and not buff[classtable.KillingMachineBuff].up ) ) or ( CheckEquipped('FyralaththeDreamrender') and not debuff[classtable.MarkofFyralathDeBuff].up ) )) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (ga_priority and rp_buffs and talents[classtable.Obliteration] and talents[classtable.BreathofSindragosa] and not buff[classtable.PillarofFrostBuff].up and not buff[classtable.BreathofSindragosaBuff].up and cooldown[classtable.BreathofSindragosa].remains >breath_pooling_time) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (ga_priority and rp_buffs and talents[classtable.BreathofSindragosa] and not buff[classtable.BreathofSindragosaBuff].up and cooldown[classtable.BreathofSindragosa].remains >breath_pooling_time) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (ga_priority and rp_buffs and not talents[classtable.BreathofSindragosa] and talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up and not talents[classtable.ShatteredFrost]) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (targets == 1 and rp_buffs and talents[classtable.Obliteration] and talents[classtable.BreathofSindragosa] and not buff[classtable.PillarofFrostBuff].up and not buff[classtable.BreathofSindragosaBuff].up and cooldown[classtable.BreathofSindragosa].remains >breath_pooling_time) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (targets == 1 and rp_buffs and talents[classtable.BreathofSindragosa] and not buff[classtable.BreathofSindragosaBuff].up and cooldown[classtable.BreathofSindragosa].remains >breath_pooling_time) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (targets == 1 and rp_buffs and not talents[classtable.BreathofSindragosa] and talents[classtable.Obliteration] and not buff[classtable.PillarofFrostBuff].up) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
end
function Frost:obliteration()
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and rime_buffs) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and not buff[classtable.DeathandDecayBuff].up and ga_priority) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (buff[classtable.KillingMachineBuff].count <2 and buff[classtable.PillarofFrostBuff].remains <gcd and not buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and talents[classtable.AFeastofSouls] and buff[classtable.AFeastofSoulsBuff].up and not talents[classtable.ArcticAssault]) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up) and cooldown[classtable.Obliterate].ready then
        return classtable.Obliterate
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (not buff[classtable.KillingMachineBuff].up and ( not debuff[classtable.FrostFeverDeBuff].up )) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (( ga_priority or debuff[classtable.RazoriceDeBuff].count <5 ) and ( not wep_rune_check('Rune of Razorice') and ( debuff[classtable.RazoriceDeBuff].count <5 or debuff[classtable.RazoriceDeBuff].remains <gcd * 3 ) or ( ( rp_buffs or Runes <2 ) and targets >1 ) )) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (( Runes <2 or rp_buffs or debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] or talents[classtable.RideroftheApocalypse] ) and not pooling_runic_power and ( not talents[classtable.GlacialAdvance] or targets == 1 or talents[classtable.ShatteredFrost] )) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and ( not talents[classtable.GlacialAdvance] or targets == 1 or talents[classtable.ShatteredFrost] )) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (not pooling_runic_power and ga_priority) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.HornofWinter, 'HornofWinter')) and (Runes <3) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (not buff[classtable.KillingMachineBuff].up) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
end
function Frost:racials()
end
function Frost:single_target()
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (talents[classtable.AFeastofSouls] and debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] and buff[classtable.AFeastofSoulsBuff].up) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].count == 2) and cooldown[classtable.Obliterate].ready then
        return classtable.Obliterate
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (( debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] ) or ( buff[classtable.KillingMachineBuff].up and Runes <2 and not talents[classtable.Icebreaker] )) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (rime_buffs) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.Obliterate, 'Obliterate')) and (buff[classtable.KillingMachineBuff].up) and cooldown[classtable.Obliterate].ready then
        return classtable.Obliterate
    end
    if (CheckSpellCosts(classtable.GlacialAdvance, 'GlacialAdvance')) and (not pooling_runic_power and not wep_rune_check('Rune of Razorice') and ( debuff[classtable.RazoriceDeBuff].count <5 or debuff[classtable.RazoriceDeBuff].remains <gcd * 3 )) and cooldown[classtable.GlacialAdvance].ready then
        return classtable.GlacialAdvance
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and ( rp_buffs or ( not talents[classtable.ShatteringBlade] and RunicPowerDeficit <20 ) or debuff[classtable.RazoriceDeBuff].count == 5 and talents[classtable.ShatteringBlade] )) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (buff[classtable.RimeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power and not ( two_hand_check or talents[classtable.ShatteringBlade] )) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.Obliterate, 'Obliterate')) and (not pooling_runes) and cooldown[classtable.Obliterate].ready then
        return classtable.Obliterate
    end
    if (CheckSpellCosts(classtable.FrostStrike, 'FrostStrike')) and (not pooling_runic_power) and cooldown[classtable.FrostStrike].ready then
        return classtable.FrostStrike
    end
    if (CheckSpellCosts(classtable.HowlingBlast, 'HowlingBlast')) and (not debuff[classtable.FrostFeverDeBuff].up) and cooldown[classtable.HowlingBlast].ready then
        return classtable.HowlingBlast
    end
    if (CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (talents[classtable.BreathofSindragosa] and not buff[classtable.BreathofSindragosaBuff].up and not (true_breath_cooldown >= 0) and Runes <2 and not buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (CheckSpellCosts(classtable.HornofWinter, 'HornofWinter')) and (Runes <2 and RunicPowerDeficit >25 and ( not talents[classtable.BreathofSindragosa] or true_breath_cooldown >cooldown[classtable.HornofWinter].duration - 15 )) and cooldown[classtable.HornofWinter].ready then
        MaxDps:GlowCooldown(classtable.HornofWinter, cooldown[classtable.HornofWinter].ready)
    end
end
function Frost:trinkets()
end
function Frost:variables()
    st_planning = targets == 1
    adds_remain = targets >= 2
    sending_cds = ( st_planning or adds_remain )
    rime_buffs = buff[classtable.RimeBuff].up and ( not debuff[classtable.FrostFeverDeBuff].up or static_rime_buffs or talents[classtable.Avalanche] and not talents[classtable.ArcticAssault] and debuff[classtable.RazoriceDeBuff].count <5 )
    rp_buffs = talents[classtable.UnleashedFrenzy] and ( buff[classtable.UnleashedFrenzyBuff].remains <gcd * 3 or buff[classtable.UnleashedFrenzyBuff].count <3 ) or talents[classtable.IcyTalons] and ( buff[classtable.IcyTalonsBuff].remains <gcd * 3 or buff[classtable.IcyTalonsBuff].count <( 3 + ( 2 * (talents[classtable.Smotheringoffense] and talents[classtable.Smotheringoffense] or 0) ) + ( 2 * (talents[classtable.DarkTalons] and talents[classtable.DarkTalons] or 0) ) ) )
    cooldown_check = talents[classtable.PillarofFrost] and buff[classtable.PillarofFrostBuff].up and ( talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].remains >10 or not talents[classtable.Obliteration] ) or not talents[classtable.PillarofFrost] and buff[classtable.EmpowerRuneWeaponBuff].up or not talents[classtable.PillarofFrost] and not talents[classtable.EmpowerRuneWeapon] or targets >= 2 and buff[classtable.PillarofFrostBuff].up
    if cooldown[classtable.BreathofSindragosa].remains >cooldown[classtable.PillarofFrost].remains then
        true_breath_cooldown = cooldown[classtable.BreathofSindragosa].remains
    else
        true_breath_cooldown = cooldown[classtable.PillarofFrost].remains
    end
    if RunicPower <35 and Runes <2 and cooldown[classtable.PillarofFrost].remains <10 then
        oblit_pooling_time = ( ( cooldown[classtable.PillarofFrost].remains + 1 ) % gcd ) % ( ( Runes + 3 ) * ( RunicPower + 5 ) ) * 100
    else
        oblit_pooling_time = 3
    end
    if RunicPowerDeficit >10 and true_breath_cooldown <10 then
        breath_pooling_time = ( ( true_breath_cooldown + 1 ) % gcd ) % ( ( Runes + 1 ) * ( RunicPower + 20 ) ) * 100
    else
        breath_pooling_time = 2
    end
    pooling_runes = Runes <oblit_rune_pooling and talents[classtable.Obliteration] and ( not talents[classtable.BreathofSindragosa] or true_breath_cooldown >= 0 ) and cooldown[classtable.PillarofFrost].remains <oblit_pooling_time
    pooling_runic_power = talents[classtable.BreathofSindragosa] and true_breath_cooldown <breath_pooling_time or talents[classtable.Obliteration] and RunicPower <35 and cooldown[classtable.PillarofFrost].remains <oblit_pooling_time
    ga_priority = ( talents[classtable.ShatteredFrost] and targets >= 2 ) or ( not talents[classtable.ShatteredFrost] and talents[classtable.ShatteringBlade] and targets >= 4 ) or ( not talents[classtable.ShatteredFrost] and not talents[classtable.ShatteringBlade] and targets >= 2 )
    breath_dying = RunicPower <breath_rp_cost * 2 and DeathKnight:TimeToRunes(2) >RunicPower % breath_rp_cost
end

function Frost:callaction()
    if (CheckSpellCosts(classtable.MindFreeze, 'MindFreeze')) and cooldown[classtable.MindFreeze].ready then
        MaxDps:GlowCooldown(classtable.MindFreeze, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    local variablesCheck = Frost:variables()
    if variablesCheck then
        return variablesCheck
    end
    local trinketsCheck = Frost:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    local high_prioCheck = Frost:high_prio()
    if high_prioCheck then
        return high_prioCheck
    end
    local cooldownsCheck = Frost:cooldowns()
    if cooldownsCheck then
        return cooldownsCheck
    end
    local racialsCheck = Frost:racials()
    if racialsCheck then
        return racialsCheck
    end
    if (talents[classtable.ColdHeart] and ( not buff[classtable.KillingMachineBuff].up or talents[classtable.BreathofSindragosa] ) and ( ( debuff[classtable.RazoriceDeBuff].count == 5 or not wep_rune_check('Rune of Razorice') and not talents[classtable.GlacialAdvance] and not talents[classtable.Avalanche] and not talents[classtable.ArcticAssault] ) or boss and ttd <= gcd )) then
        local cold_heartCheck = Frost:cold_heart()
        if cold_heartCheck then
            return Frost:cold_heart()
        end
    end
    if (buff[classtable.BreathofSindragosaBuff].up) then
        local breathCheck = Frost:breath()
        if breathCheck then
            return Frost:breath()
        end
    end
    if (talents[classtable.Obliteration] and buff[classtable.PillarofFrostBuff].up and not buff[classtable.BreathofSindragosaBuff].up) then
        local obliterationCheck = Frost:obliteration()
        if obliterationCheck then
            return Frost:obliteration()
        end
    end
    if (targets >= 2) then
        local aoeCheck = Frost:aoe()
        if aoeCheck then
            return Frost:aoe()
        end
    end
    if (targets == 1) then
        local single_targetCheck = Frost:single_target()
        if single_targetCheck then
            return Frost:single_target()
        end
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
    targethealthPerc = (targetHP / targetmaxHP) * 100
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
    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end
    classtable.KillingMachineBuff = 51124
    classtable.DeathandDecayBuff = 188290
    classtable.FrostFeverDeBuff = 55095
    classtable.RazoriceDeBuff = 51714
    classtable.RimeBuff = 59052
    classtable.EmpowerRuneWeaponBuff = 47568
    classtable.MograinesMightBuff = 444505
    classtable.ColdHeartBuff = 281209
    classtable.PillarofFrostBuff = 51271
    classtable.UnholyStrengthBuff = 53365
    classtable.ReapersMarkDebuffDeBuff = 439594
    classtable.BreathofSindragosaBuff = 152279
    classtable.MarkofFyralathDeBuff = 414532
    classtable.AFeastofSoulsBuff = 440861
    classtable.UnleashedFrenzyBuff = 376907
    classtable.IcyTalonsBuff = 194879

    local precombatCheck = Frost:precombat()
    if precombatCheck then
        return Frost:precombat()
    end

    local callactionCheck = Frost:callaction()
    if callactionCheck then
        return Frost:callaction()
    end
end
