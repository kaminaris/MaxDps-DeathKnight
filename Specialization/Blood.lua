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

local Blood = {}

local trinket_1_buffs
local trinket_2_buffs
local damage_trinket_priority
local death_strike_dump_amount
local bone_shield_refresh_value
local heart_strike_rp_drw
local death_strike_pre_essence_dump_amount


local function GetTotemDuration(name)
    for index=1,MAX_TOTEMS do
        local arg1, totemName, startTime, duration, icon = GetTotemInfo(index)
        local est_dur = math.floor(startTime+duration-GetTime())
        if (totemName == name and est_dur and est_dur > 0) then return est_dur else return 0 end
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


function Blood:deathbringer()
    death_strike_dump_amount = 65
    bone_shield_refresh_value = 6
    heart_strike_rp_drw = ( 25 + targets * (talents[classtable.Heartbreaker] and talents[classtable.Heartbreaker] or 0) * 2 )
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and (not UnitExists ( 'pet' )) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodTap, 'BloodTap')) and (Runes <= 1) and cooldown[classtable.BloodTap].ready then
        MaxDps:GlowCooldown(classtable.BloodTap, cooldown[classtable.BloodTap].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (true and buff[classtable.BloodShieldBuff].up and buff[classtable.BloodShieldBuff].remains <= gcd) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathsCaress, 'DeathsCaress')) and (not buff[classtable.BoneShieldBuff].up) and cooldown[classtable.DeathsCaress].ready then
        if not setSpell then setSpell = classtable.DeathsCaress end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd or RunicPowerDeficit <35) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (debuff[classtable.ReapersMarkDeBuff].up and debuff[classtable.ReapersMarkDeBuff].remains <2 * gcd) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (debuff[classtable.ReapersMarkDeBuff].up and cooldown[classtable.BloodBoil].charges >= 1.5) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consumption, 'Consumption') and talents[classtable.Consumption]) and (debuff[classtable.ReapersMarkDeBuff].up and debuff[classtable.BloodPlagueDeBuff].up) and cooldown[classtable.Consumption].ready then
        MaxDps:GlowCooldown(classtable.Consumption, cooldown[classtable.Consumption].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (buff[classtable.ReaperofSoulsBuff].up and buff[classtable.CoagulopathyBuff].remains >1 * gcd) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (targets == 1 and ( MaxDps:GetTimeToPct(35) <5 or buff[classtable.ReaperofSoulsBuff].up ) and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (( debuff[classtable.ReapersMarkDeBuff].up and ( ( UnitExists('pet') and UnitName('pet')  == 'dancing_rune_weapon' ) and debuff[classtable.BloodPlagueDeBuff].count <2 ) ) or not debuff[classtable.BloodPlagueDeBuff].up or ( cooldown[classtable.BloodBoil].charges >= 1 and debuff[classtable.ReapersMarkDeBuff].up and buff[classtable.CoagulopathyBuff].remains >2 * gcd )) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (( ( debuff[classtable.ReapersMarkDeBuff].up ) and not buff[classtable.DeathandDecayBuff].up ) or not buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and (buff[classtable.ExterminateBuff].up and ( RunicPowerDeficit >20 and buff[classtable.CoagulopathyBuff].remains >2 * gcd )) and cooldown[classtable.Marrowrend].ready then
        if not setSpell then setSpell = classtable.Marrowrend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and (( buff[classtable.ExterminateBuff].up ) and ( RunicPowerDeficit >20 and buff[classtable.CoagulopathyBuff].remains >2 * gcd )) and cooldown[classtable.Marrowrend].ready then
        if not setSpell then setSpell = classtable.Marrowrend end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and (debuff[classtable.ReapersMarkDeBuff].up) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ReapersMark, 'ReapersMark')) and (not debuff[classtable.ReapersMarkDeBuff].up and debuff[classtable.BloodPlagueDeBuff].up) and cooldown[classtable.ReapersMark].ready then
        MaxDps:GlowCooldown(classtable.ReapersMark, cooldown[classtable.ReapersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bonestorm, 'Bonestorm')) and (buff[classtable.DeathandDecayBuff].up and buff[classtable.BoneShieldBuff].count >5 and cooldown[classtable.DancingRuneWeapon].remains >= 10 and ( debuff[classtable.ReapersMarkDeBuff].up )) and cooldown[classtable.Bonestorm].ready then
        if not setSpell then setSpell = classtable.Bonestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Blooddrinker, 'Blooddrinker')) and (buff[classtable.CoagulopathyBuff].remains >3 * gcd and not buff[classtable.DancingRuneWeaponBuff].up) and cooldown[classtable.Blooddrinker].ready then
        MaxDps:GlowCooldown(classtable.Blooddrinker, cooldown[classtable.Blooddrinker].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DancingRuneWeapon, 'DancingRuneWeapon') and talents[classtable.DancingRuneWeapon]) and (buff[classtable.CoagulopathyBuff].remains >2 * gcd) and cooldown[classtable.DancingRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.DancingRuneWeapon, cooldown[classtable.DancingRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bonestorm, 'Bonestorm')) and (buff[classtable.DeathandDecayBuff].up and buff[classtable.BoneShieldBuff].count >5 and cooldown[classtable.DancingRuneWeapon].remains >= 10) and cooldown[classtable.Bonestorm].ready then
        if not setSpell then setSpell = classtable.Bonestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tombstone, 'Tombstone')) and (buff[classtable.DeathandDecayBuff].up and buff[classtable.BoneShieldBuff].count >5 and RunicPowerDeficit >= 30 and cooldown[classtable.DancingRuneWeapon].remains >= 10) and cooldown[classtable.Tombstone].ready then
        MaxDps:GlowCooldown(classtable.Tombstone, cooldown[classtable.Tombstone].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and (not debuff[classtable.BonestormDeBuff].up and ( buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value and RunicPowerDeficit >20 or buff[classtable.BoneShieldBuff].remains <= 3 )) and cooldown[classtable.Marrowrend].ready then
        if not setSpell then setSpell = classtable.Marrowrend end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.5 or ( DeathKnight:TimeToRunes(5) <= gcd )) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consumption, 'Consumption') and talents[classtable.Consumption]) and cooldown[classtable.Consumption].ready then
        MaxDps:GlowCooldown(classtable.Consumption, cooldown[classtable.Consumption].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (RunicPowerDeficit <= heart_strike_rp_drw or RunicPower >= death_strike_dump_amount) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.5 and buff[classtable.HemostasisBuff].count <5 and cooldown[classtable.ReapersMark].remains >5) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (Runes >= 1 or DeathKnight:TimeToRunes(2) <gcd or RunicPowerDeficit >= heart_strike_rp_drw) and cooldown[classtable.HeartStrike].ready then
        if not setSpell then setSpell = classtable.HeartStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
end
function Blood:sanlayn()
    death_strike_dump_amount = 65
    death_strike_pre_essence_dump_amount = 20
    bone_shield_refresh_value = 7
    heart_strike_rp_drw = ( 21 + targets * (talents[classtable.Heartbreaker] and talents[classtable.Heartbreaker] or 0) * 2 )
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (true and buff[classtable.BloodShieldBuff].up and buff[classtable.BloodShieldBuff].remains <= gcd) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathsCaress, 'DeathsCaress')) and (not buff[classtable.BoneShieldBuff].up) and cooldown[classtable.DeathsCaress].ready then
        if not setSpell then setSpell = classtable.DeathsCaress end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (not debuff[classtable.BloodPlagueDeBuff].up or ( debuff[classtable.BloodPlagueDeBuff].remains <10 and buff[classtable.DancingRuneWeaponBuff].up )) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consumption, 'Consumption') and talents[classtable.Consumption]) and (( UnitExists('pet') and UnitName('pet')  == 'dancing_rune_weapon' ) and GetTotemDuration('dancing_rune_weapon') <= 3) and cooldown[classtable.Consumption].ready then
        MaxDps:GlowCooldown(classtable.Consumption, cooldown[classtable.Consumption].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Bonestorm, 'Bonestorm')) and (( buff[classtable.DeathandDecayBuff].up ) and buff[classtable.BoneShieldBuff].count >5 and cooldown[classtable.DancingRuneWeapon].remains >= 25) and cooldown[classtable.Bonestorm].ready then
        if not setSpell then setSpell = classtable.Bonestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (RunicPower >= 108) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (buff[classtable.DancingRuneWeaponBuff].up and Runes >1) and cooldown[classtable.HeartStrike].ready then
        if not setSpell then setSpell = classtable.HeartStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.DeathandDecay].ready then
        if not setSpell then setSpell = classtable.DeathandDecay end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (buff[classtable.InflictionofSorrowBuff].up and buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.HeartStrike].ready then
        if not setSpell then setSpell = classtable.HeartStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and (not UnitExists ( 'pet' )) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.Tombstone, 'Tombstone')) and (( not buff[classtable.DancingRuneWeaponBuff].up and buff[classtable.DeathandDecayBuff].up ) and buff[classtable.BoneShieldBuff].count >5 and RunicPowerDeficit >= 30 and cooldown[classtable.DancingRuneWeapon].remains >= 25 and buff[classtable.CoagulopathyBuff].remains >2 * gcd) and cooldown[classtable.Tombstone].ready then
        MaxDps:GlowCooldown(classtable.Tombstone, cooldown[classtable.Tombstone].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DancingRuneWeapon, 'DancingRuneWeapon') and talents[classtable.DancingRuneWeapon]) and (buff[classtable.CoagulopathyBuff].remains >= 2 * gcd and ( not buff[classtable.EssenceoftheBloodQueenBuff].up or buff[classtable.EssenceoftheBloodQueenBuff].remains >= 3 * gcd ) and ( not buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.DancingRuneWeaponBuff].remains >= 6 * gcd )) and cooldown[classtable.DancingRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.DancingRuneWeapon, cooldown[classtable.DancingRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (not buff[classtable.VampiricStrikeBuff].up and cooldown[classtable.DancingRuneWeapon].remains <= 30 and RunicPower >death_strike_pre_essence_dump_amount and buff[classtable.EssenceoftheBloodQueenBuff].count >= 3) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and (not debuff[classtable.BonestormDeBuff].up and ( buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value and RunicPowerDeficit >20 or buff[classtable.BoneShieldBuff].remains <= 3 )) and cooldown[classtable.Marrowrend].ready then
        if not setSpell then setSpell = classtable.Marrowrend end
    end
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and (not debuff[classtable.BonestormDeBuff].up and ( buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value and RunicPowerDeficit >20 and not cooldown[classtable.DancingRuneWeapon].ready or buff[classtable.BoneShieldBuff].remains <= 3 )) and cooldown[classtable.Marrowrend].ready then
        if not setSpell then setSpell = classtable.Marrowrend end
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (targets == 1 and MaxDps:GetTimeToPct(35) <5 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        if not setSpell then setSpell = classtable.SoulReaper end
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.DancingRuneWeaponBuff].up and ( buff[classtable.CoagulopathyBuff].remains <2 * gcd or ( RunicPowerDeficit <= heart_strike_rp_drw and buff[classtable.InciteTerrorBuff].count >= 3 ) )) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (buff[classtable.VampiricStrikeBuff].up or buff[classtable.InflictionofSorrowBuff].up and ( ( (talents[classtable.Consumption] and true or false) and buff[classtable.ConsumptionBuff].up ) or not (talents[classtable.Consumption] and true or false) ) and debuff[classtable.BloodPlagueDeBuff].up and debuff[classtable.BloodPlagueDeBuff].remains >20) and cooldown[classtable.HeartStrike].ready then
        if not setSpell then setSpell = classtable.HeartStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.DancingRuneWeapon, 'DancingRuneWeapon') and talents[classtable.DancingRuneWeapon]) and (buff[classtable.CoagulopathyBuff].up) and cooldown[classtable.DancingRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.DancingRuneWeapon, cooldown[classtable.DancingRuneWeapon].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (RunicPowerDeficit <= heart_strike_rp_drw or RunicPower >= death_strike_dump_amount) and cooldown[classtable.DeathStrike].ready then
        if not setSpell then setSpell = classtable.DeathStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 2 or ( DeathKnight:TimeToRunes(5) <= gcd )) and cooldown[classtable.BloodBoil].ready then
        if not setSpell then setSpell = classtable.BloodBoil end
    end
    if (MaxDps:CheckSpellUsable(classtable.Consumption, 'Consumption') and talents[classtable.Consumption]) and (cooldown[classtable.DancingRuneWeapon].remains >20) and cooldown[classtable.Consumption].ready then
        MaxDps:GlowCooldown(classtable.Consumption, cooldown[classtable.Consumption].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (Runes >1) and cooldown[classtable.HeartStrike].ready then
        if not setSpell then setSpell = classtable.HeartStrike end
    end
    if (MaxDps:CheckSpellUsable(classtable.Bonestorm, 'Bonestorm')) and (buff[classtable.DeathandDecayBuff].up and buff[classtable.BoneShieldBuff].count >5 and cooldown[classtable.DancingRuneWeapon].remains >= 25) and cooldown[classtable.Bonestorm].ready then
        if not setSpell then setSpell = classtable.Bonestorm end
    end
    if (MaxDps:CheckSpellUsable(classtable.Tombstone, 'Tombstone')) and (buff[classtable.DeathandDecayBuff].up and buff[classtable.BoneShieldBuff].count >5 and RunicPowerDeficit >= 30 and cooldown[classtable.DancingRuneWeapon].remains >= 25) and cooldown[classtable.Tombstone].ready then
        MaxDps:GlowCooldown(classtable.Tombstone, cooldown[classtable.Tombstone].ready)
    end
end


local function ClearCDs()
    MaxDps:GlowCooldown(classtable.MindFreeze, false)
    MaxDps:GlowCooldown(classtable.IceboundFortitude, false)
    MaxDps:GlowCooldown(classtable.VampiricBlood, false)
    MaxDps:GlowCooldown(classtable.RuneTap, false)
    MaxDps:GlowCooldown(classtable.RaiseDead, false)
    MaxDps:GlowCooldown(classtable.BloodTap, false)
    MaxDps:GlowCooldown(classtable.Consumption, false)
    MaxDps:GlowCooldown(classtable.AbominationLimb, false)
    MaxDps:GlowCooldown(classtable.ReapersMark, false)
    MaxDps:GlowCooldown(classtable.Blooddrinker, false)
    MaxDps:GlowCooldown(classtable.DancingRuneWeapon, false)
    MaxDps:GlowCooldown(classtable.Tombstone, false)
end

function Blood:callaction()
    if (MaxDps:CheckSpellUsable(classtable.MindFreeze, 'MindFreeze')) and cooldown[classtable.MindFreeze].ready then
        MaxDps:GlowCooldown(classtable.MindFreeze, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    if (MaxDps:CheckSpellUsable(classtable.IceboundFortitude, 'IceboundFortitude')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and not ( buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.VampiricBloodBuff].up )) and cooldown[classtable.IceboundFortitude].ready then
        MaxDps:GlowCooldown(classtable.IceboundFortitude, cooldown[classtable.IceboundFortitude].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.VampiricBlood, 'VampiricBlood')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and not ( buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.IceboundFortitudeBuff].up )) and cooldown[classtable.VampiricBlood].ready then
        MaxDps:GlowCooldown(classtable.VampiricBlood, cooldown[classtable.VampiricBlood].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RuneTap, 'RuneTap')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and not ( buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.VampiricBloodBuff].up or buff[classtable.IceboundFortitudeBuff].up )) and cooldown[classtable.RuneTap].ready then
        MaxDps:GlowCooldown(classtable.RuneTap, cooldown[classtable.RuneTap].ready)
    end
    if ((MaxDps.ActiveHeroTree == 'deathbringer')) then
        Blood:deathbringer()
    end
    if (not (MaxDps.ActiveHeroTree == 'deathbringer')) then
        Blood:sanlayn()
    end
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
    classtable.BloodShieldBuff = 77535
    classtable.BoneShieldBuff = 195181
    classtable.CoagulopathyBuff = 391481
    classtable.ReapersMarkDeBuff = 439843
    classtable.BloodPlagueDeBuff = 55078
    classtable.ReaperofSoulsBuff = 440002
    classtable.SoulReaperDeBuff = 343294
    classtable.DeathandDecayBuff = 188290
    classtable.ExterminateBuff = 441378
    classtable.DancingRuneWeaponBuff = 81256
    classtable.BonestormDeBuff = 194844
    classtable.HemostasisBuff = 273947
    classtable.InflictionofSorrowBuff = 433925
    classtable.EssenceoftheBloodQueenBuff = 0
    classtable.VampiricStrikeBuff = 433899
    classtable.InciteTerrorBuff = 434151
    classtable.ConsumptionBuff = 274156
    classtable.VampiricBloodBuff = 55233
    classtable.IceboundFortitudeBuff = 48792

    local function debugg()
        talents[classtable.DancingRuneWeapon] = 1
        talents[classtable.Consumption] = 1
    end


    --if MaxDps.db.global.debugMode then
    --   debugg()
    --end

    setSpell = nil
    ClearCDs()

    Blood:callaction()
    if setSpell then return setSpell end
end
