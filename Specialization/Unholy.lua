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

local Unholy = {}

local trinket_1_buffs
local trinket_2_buffs
local trinket_1_duration
local trinket_2_duration
local trinket_1_sync
local trinket_2_sync
local trinket_priority
local damage_trinket_priority
local st_planning
local adds_remain
local apoc_timing
local pop_wounds
local pooling_runic_power
local spend_rp

local function CheckSpellCosts(spell,spellstring)
    if not IsSpellKnownOrOverridesKnown(spell) then return false end
    if spellstring == 'TouchofDeath' then
        if targethealthPerc > 15 then
            return false
        end
    end
    if spellstring == 'KillShot' then
        if (classtable.SicEmBuff and not buff[classtable.SicEmBuff].up) and targethealthPerc > 15 then
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


function Unholy:precombat()
    if (MaxDps:FindSpell(classtable.RaiseDead) and CheckSpellCosts(classtable.RaiseDead, 'RaiseDead')) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    else
        MaxDps:GlowCooldown(classtable.RaiseDead, false)
    end
    if (MaxDps:FindSpell(classtable.ArmyoftheDead) and CheckSpellCosts(classtable.ArmyoftheDead, 'ArmyoftheDead')) and cooldown[classtable.ArmyoftheDead].ready then
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, cooldown[classtable.ArmyoftheDead].ready)
    else
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, false)
    end
end
function Unholy:aoe()
    if (MaxDps:FindSpell(classtable.DeathandDecay) and CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and ( not talents[classtable.BurstingSores] or debuff[classtable.FesteringWoundDebuff].count == targets or debuff[classtable.FesteringWoundDebuff].count >= 8 or (targets >1) and targets <= 11 and targets >5 )) and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (MaxDps:FindSpell(classtable.Epidemic) and CheckSpellCosts(classtable.Epidemic, 'Epidemic')) and (not pooling_runic_power) and cooldown[classtable.Epidemic].ready then
        return classtable.Epidemic
    end
    if (MaxDps:FindSpell(classtable.FesteringStrike) and CheckSpellCosts(classtable.FesteringStrike, 'FesteringStrike')) and (cooldown[classtable.Apocalypse].duration <gcd and debuff[classtable.FesteringWoundDeBuff].count == 0 or buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        return classtable.FesteringStrike
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.FesteringWoundDeBuff].count >= 1 and cooldown[classtable.Apocalypse].duration >gcd) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.FesteringStrike) and CheckSpellCosts(classtable.FesteringStrike, 'FesteringStrike')) and (debuff[classtable.FesteringWoundDeBuff].count <4) and cooldown[classtable.FesteringStrike].ready then
        return classtable.FesteringStrike
    end
end
function Unholy:aoe_burst()
    if (MaxDps:FindSpell(classtable.Defile) and CheckSpellCosts(classtable.Defile, 'Defile')) and (not debuff[classtable.Defile].up) and cooldown[classtable.Defile].ready then
        return classtable.Defile
    end
    if (MaxDps:FindSpell(classtable.Epidemic) and CheckSpellCosts(classtable.Epidemic, 'Epidemic')) and (not pooling_runic_power and ( targets >= 6 and not talents[classtable.BurstingSores] or talents[classtable.BurstingSores] and debuff[classtable.FesteringWoundDebuff].count ~= targets and debuff[classtable.FesteringWoundDebuff].count <6 or not talents[classtable.BurstingSores] and RunicPowerDeficit <30 or buff[classtable.SuddenDoomBuff].up )) and cooldown[classtable.Epidemic].ready then
        return classtable.Epidemic
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.FesteringWoundDeBuff].count >= 1) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.FesteringStrike) and CheckSpellCosts(classtable.FesteringStrike, 'FesteringStrike')) and (buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        return classtable.FesteringStrike
    end
    if (MaxDps:FindSpell(classtable.Epidemic) and CheckSpellCosts(classtable.Epidemic, 'Epidemic')) and (not pooling_runic_power) and cooldown[classtable.Epidemic].ready then
        return classtable.Epidemic
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
end
function Unholy:cds()
    if (MaxDps:FindSpell(classtable.DarkTransformation) and CheckSpellCosts(classtable.DarkTransformation, 'DarkTransformation')) and (( st_planning or adds_remain ) and ( cooldown[classtable.Apocalypse].duration <8 or not talents[classtable.Apocalypse] or targets >= 1 )) and cooldown[classtable.DarkTransformation].ready then
        MaxDps:GlowCooldown(classtable.DarkTransformation, cooldown[classtable.DarkTransformation].ready)
    else
        MaxDps:GlowCooldown(classtable.DarkTransformation, false)
    end
    if (MaxDps:FindSpell(classtable.UnholyAssault) and CheckSpellCosts(classtable.UnholyAssault, 'UnholyAssault')) and (( st_planning or adds_remain ) and ( cooldown[classtable.Apocalypse].duration <gcd * 2 or not talents[classtable.Apocalypse] or targets >= 2 and buff[classtable.DarkTransformationBuff].up )) and cooldown[classtable.UnholyAssault].ready then
        return classtable.UnholyAssault
    end
    if (MaxDps:FindSpell(classtable.Apocalypse) and CheckSpellCosts(classtable.Apocalypse, 'Apocalypse')) and (( st_planning or adds_remain )) and cooldown[classtable.Apocalypse].ready then
        MaxDps:GlowCooldown(classtable.Apocalypse, cooldown[classtable.Apocalypse].ready)
    else
        MaxDps:GlowCooldown(classtable.Apocalypse, false)
    end
    if (MaxDps:FindSpell(classtable.Outbreak) and CheckSpellCosts(classtable.Outbreak, 'Outbreak')) and (( debuff[classtable.VirulentPlagueDeBuff].refreshable or talents[classtable.Superstrain] and ( debuff[classtable.FrostFeverDeBuff].refreshable or debuff[classtable.BloodPlagueDeBuff].refreshable ) ) and ( not talents[classtable.UnholyBlight] or talents[classtable.UnholyBlight] and cooldown[classtable.DarkTransformation].duration >15 % ( ( 3 * (talents[classtable.Superstrain] and talents[classtable.Superstrain] or 0) ) + ( 2 * (talents[classtable.EbonFever] and talents[classtable.EbonFever] or 0) ) + ( 2 * (talents[classtable.Plaguebringer] and talents[classtable.Plaguebringer] or 0) ) ) ) and ( not talents[classtable.RaiseAbomination] or talents[classtable.RaiseAbomination] and cooldown[classtable.RaiseAbomination].duration >15 % ( ( 3 * (talents[classtable.Superstrain] and talents[classtable.Superstrain] or 0) ) + ( 2 * (talents[classtable.EbonFever] and talents[classtable.EbonFever] or 0) ) + ( 2 * (talents[classtable.Plaguebringer] and talents[classtable.Plaguebringer] or 0) ) ) )) and cooldown[classtable.Outbreak].ready then
        return classtable.Outbreak
    end
    if (MaxDps:FindSpell(classtable.AbominationLimb) and CheckSpellCosts(classtable.AbominationLimb, 'AbominationLimb')) and (( st_planning or adds_remain ) and ( targets >= 2 or not buff[classtable.SuddenDoomBuff].up and buff[classtable.FestermightBuff].up and debuff[classtable.FesteringWoundDeBuff].count <= 2 )) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    else
        MaxDps:GlowCooldown(classtable.AbominationLimb, false)
    end
end
function Unholy:cds_san()
    if (MaxDps:FindSpell(classtable.DarkTransformation) and CheckSpellCosts(classtable.DarkTransformation, 'DarkTransformation')) and (targets >= 1 and ( st_planning or adds_remain ) and ( talents[classtable.Apocalypse] and ( ( UnitExists('pet') and UnitName('pet')  == 'apoc_ghoul' ) or targets >= 2 ) or not talents[classtable.Apocalypse] )) and cooldown[classtable.DarkTransformation].ready then
        MaxDps:GlowCooldown(classtable.DarkTransformation, cooldown[classtable.DarkTransformation].ready)
    else
        MaxDps:GlowCooldown(classtable.DarkTransformation, false)
    end
    if (MaxDps:FindSpell(classtable.UnholyAssault) and CheckSpellCosts(classtable.UnholyAssault, 'UnholyAssault')) and (( st_planning or adds_remain ) and ( buff[classtable.DarkTransformationBuff].up and buff[classtable.DarkTransformationBuff].remains <12 )) and cooldown[classtable.UnholyAssault].ready then
        return classtable.UnholyAssault
    end
    if (MaxDps:FindSpell(classtable.Apocalypse) and CheckSpellCosts(classtable.Apocalypse, 'Apocalypse')) and (( st_planning or adds_remain ) and ( debuff[classtable.FesteringWoundDeBuff].count >= 3 or targets >= 2 )) and cooldown[classtable.Apocalypse].ready then
        MaxDps:GlowCooldown(classtable.Apocalypse, cooldown[classtable.Apocalypse].ready)
    else
        MaxDps:GlowCooldown(classtable.Apocalypse, false)
    end
    if (MaxDps:FindSpell(classtable.Outbreak) and CheckSpellCosts(classtable.Outbreak, 'Outbreak')) and (( GetTotemDuration('abomination') <15 and debuff[classtable.VirulentPlagueDeBuff].refreshable or talents[classtable.Morbidity] and buff[classtable.InflictionofSorrowBuff].up and talents[classtable.Superstrain] and debuff[classtable.FrostFeverDeBuff].refreshable and debuff[classtable.BloodPlagueDeBuff].refreshable ) and ( not talents[classtable.UnholyBlight] or talents[classtable.UnholyBlight] and cooldown[classtable.DarkTransformation].duration >15 % ( ( 3 * (talents[classtable.Superstrain] and talents[classtable.Superstrain] or 0) ) + ( 2 * (talents[classtable.EbonFever] and talents[classtable.EbonFever] or 0) ) + ( 2 * (talents[classtable.Plaguebringer] and talents[classtable.Plaguebringer] or 0) ) ) ) and ( not talents[classtable.RaiseAbomination] or talents[classtable.RaiseAbomination] and cooldown[classtable.RaiseAbomination].duration >15 % ( ( 3 * (talents[classtable.Superstrain] and talents[classtable.Superstrain] or 0) ) + ( 2 * (talents[classtable.EbonFever] and talents[classtable.EbonFever] or 0) ) + ( 2 * (talents[classtable.Plaguebringer] and talents[classtable.Plaguebringer] or 0) ) ) )) and cooldown[classtable.Outbreak].ready then
        return classtable.Outbreak
    end
    if (MaxDps:FindSpell(classtable.AbominationLimb) and CheckSpellCosts(classtable.AbominationLimb, 'AbominationLimb')) and (targets >= 1 and ( st_planning or adds_remain ) and ( targets >= 2 or not buff[classtable.DarkTransformationBuff].up and not buff[classtable.SuddenDoomBuff].up and buff[classtable.FestermightBuff].up and debuff[classtable.FesteringWoundDeBuff].count <= 2 )) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    else
        MaxDps:GlowCooldown(classtable.AbominationLimb, false)
    end
end
function Unholy:cds_shared()
    if (MaxDps:FindSpell(classtable.ArmyoftheDead) and CheckSpellCosts(classtable.ArmyoftheDead, 'ArmyoftheDead')) and (( st_planning or adds_remain ) and ( talents[classtable.CommanderoftheDead] and cooldown[classtable.DarkTransformation].duration <5 or not talents[classtable.CommanderoftheDead] and targets >= 1 ) or ttd <35) and cooldown[classtable.ArmyoftheDead].ready then
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, cooldown[classtable.ArmyoftheDead].ready)
    else
        MaxDps:GlowCooldown(classtable.ArmyoftheDead, false)
    end
    if (MaxDps:FindSpell(classtable.RaiseAbomination) and CheckSpellCosts(classtable.RaiseAbomination, 'RaiseAbomination')) and (( st_planning or adds_remain ) and ( talents[classtable.CommanderoftheDead] and cooldown[classtable.DarkTransformation].duration <gcd * 2 or not talents[classtable.CommanderoftheDead] and targets >= 1 ) or ttd <30) and cooldown[classtable.RaiseAbomination].ready then
        MaxDps:GlowCooldown(classtable.RaiseAbomination, cooldown[classtable.RaiseAbomination].ready)
    else
        MaxDps:GlowCooldown(classtable.RaiseAbomination, false)
    end
    if (MaxDps:FindSpell(classtable.SummonGargoyle) and CheckSpellCosts(classtable.SummonGargoyle, 'SummonGargoyle')) and (( st_planning or adds_remain ) and ( buff[classtable.CommanderoftheDeadBuff].up or not talents[classtable.CommanderoftheDead] and targets >= 1 )) and cooldown[classtable.SummonGargoyle].ready then
        MaxDps:GlowCooldown(classtable.SummonGargoyle, cooldown[classtable.SummonGargoyle].ready)
    else
        MaxDps:GlowCooldown(classtable.SummonGargoyle, false)
    end
    if (MaxDps:FindSpell(classtable.VileContagion) and CheckSpellCosts(classtable.VileContagion, 'VileContagion')) and (adds_remain and ( debuff[classtable.FesteringWoundDeBuff].count == 6 and ( debuff[classtable.Defile].up or debuff[classtable.DeathandDecayDebuff].up or cooldown[classtable.AnyDnd].duration <3 ) or (targets >1) and targets <= 11 and targets >5 or buff[classtable.DeathandDecayBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 4 or cooldown[classtable.AnyDnd].duration <3 and debuff[classtable.FesteringWoundDeBuff].count >= 4 )) and cooldown[classtable.VileContagion].ready then
        return classtable.VileContagion
    end
end
function Unholy:cleave()
    if (MaxDps:FindSpell(classtable.DeathandDecay) and CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up) and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and talents[classtable.ImprovedDeathCoil]) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
    if (MaxDps:FindSpell(classtable.FesteringStrike) and CheckSpellCosts(classtable.FesteringStrike, 'FesteringStrike')) and (not pop_wounds and debuff[classtable.FesteringWoundDeBuff].count <4 or buff[classtable.FesteringScytheBuff].up) and cooldown[classtable.FesteringStrike].ready then
        return classtable.FesteringStrike
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (pop_wounds) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.Epidemic) and CheckSpellCosts(classtable.Epidemic, 'Epidemic')) and (not pooling_runic_power) and cooldown[classtable.Epidemic].ready then
        return classtable.Epidemic
    end
end
local function racials()
end
function Unholy:san_fishing()
    if (MaxDps:FindSpell(classtable.DeathandDecay) and CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (not buff[classtable.DeathandDecayBuff].up and not buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (buff[classtable.SuddenDoomBuff].up and talents[classtable.DoomedBidding]) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
    if (MaxDps:FindSpell(classtable.SoulReaper) and CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (targetHP <= 35 and ttd >5) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (not buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (( debuff[classtable.FesteringWoundDeBuff].count >= 3 - ( UnitExists('pet') and UnitName('pet')  == 'abomination' ) and cooldown[classtable.Apocalypse].duration >apoc_timing ) or buff[classtable.VampiricStrikeBuff].up) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.FesteringStrike) and CheckSpellCosts(classtable.FesteringStrike, 'FesteringStrike')) and (debuff[classtable.FesteringWoundDeBuff].count <3 - ( UnitExists('pet') and UnitName('pet')  == 'abomination' )) and cooldown[classtable.FesteringStrike].ready then
        return classtable.FesteringStrike
    end
end
function Unholy:san_st()
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (buff[classtable.EssenceoftheBloodQueenBuff].remains <3 and buff[classtable.VampiricStrikeBuff].up or talents[classtable.GiftoftheSanlayn] and buff[classtable.DarkTransformationBuff].up and buff[classtable.DarkTransformationBuff].remains <gcd) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (buff[classtable.SuddenDoomBuff].up and buff[classtable.GiftoftheSanlaynBuff].remains and buff[classtable.EssenceoftheBloodQueenBuff].count >= 3 and ( talents[classtable.DoomedBidding] or talents[classtable.RottenTouch] ) or Runes <2 and not buff[classtable.RunicCorruptionBuff].up) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
    if (MaxDps:FindSpell(classtable.SoulReaper) and CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (targetHP <= 35 and not buff[classtable.GiftoftheSanlaynBuff].up and ttd >5) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:FindSpell(classtable.FesteringStrike) and CheckSpellCosts(classtable.FesteringStrike, 'FesteringStrike')) and (( debuff[classtable.FesteringWoundDeBuff].count <4 and cooldown[classtable.Apocalypse].duration <apoc_timing ) or ( talents[classtable.GiftoftheSanlayn] and not buff[classtable.GiftoftheSanlaynBuff].up or not talents[classtable.GiftoftheSanlayn] ) and ( buff[classtable.FesteringScytheBuff].up or debuff[classtable.FesteringWoundDeBuff].count <= 1 - ( UnitExists('pet') and UnitName('pet')  == 'abomination' ) )) and cooldown[classtable.FesteringStrike].ready then
        return classtable.FesteringStrike
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (( debuff[classtable.FesteringWoundDeBuff].count >= 3 - ( UnitExists('pet') and UnitName('pet')  == 'abomination' ) and cooldown[classtable.Apocalypse].duration >apoc_timing ) or buff[classtable.VampiricStrikeBuff].up and cooldown[classtable.Apocalypse].duration >apoc_timing) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and debuff[classtable.DeathRotDeBuff].remains <gcd or ( buff[classtable.SuddenDoomBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 1 or Runes <2 )) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (debuff[classtable.FesteringWoundDeBuff].count >4) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
end
local function san_trinkets()
end
function Unholy:st()
    if (MaxDps:FindSpell(classtable.SoulReaper) and CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (targetHP <= 35 and ttd >5) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power and spend_rp or ttd <10) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
    if (MaxDps:FindSpell(classtable.FesteringStrike) and CheckSpellCosts(classtable.FesteringStrike, 'FesteringStrike')) and (not pop_wounds and debuff[classtable.FesteringWoundDeBuff].count <4) and cooldown[classtable.FesteringStrike].ready then
        return classtable.FesteringStrike
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (pop_wounds) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
    if (MaxDps:FindSpell(classtable.DeathCoil) and CheckSpellCosts(classtable.DeathCoil, 'DeathCoil')) and (not pooling_runic_power) and cooldown[classtable.DeathCoil].ready then
        return classtable.DeathCoil
    end
    if (MaxDps:FindSpell(classtable.WoundSpender) and CheckSpellCosts(classtable.WoundSpender, 'WoundSpender')) and (not pop_wounds and debuff[classtable.FesteringWoundDeBuff].count >= 4) and cooldown[classtable.WoundSpender].ready then
        return classtable.WoundSpender
    end
end
local function trinkets()
end
function Unholy:variables()
    if targets == 1 and ( (targets <2) or math.huge >15 ) then
        st_planning = true
    else
        st_planning = false
    end
    if targets >= 2 and ( (targets <2) or (targets >1) and targets >6 ) then
        adds_remain = true
    else
        adds_remain = false
    end
    if cooldown[classtable.Apocalypse].duration <10 and debuff[classtable.FesteringWoundDeBuff].count <= 4 and cooldown[classtable.UnholyAssault].duration >10 then
        apoc_timing = 7
    else
        apoc_timing = 3
    end
    if ( cooldown[classtable.Apocalypse].duration >apoc_timing or not talents[classtable.Apocalypse] ) and ( debuff[classtable.FesteringWoundDeBuff].count >= 1 and cooldown[classtable.UnholyAssault].duration <20 and talents[classtable.UnholyAssault] and st_planning or debuff[classtable.RottenTouchDeBuff].up and debuff[classtable.FesteringWoundDeBuff].count >= 1 or debuff[classtable.FesteringWoundDeBuff].count >= 4 - ( UnitExists('pet') and UnitName('pet')  == 'abomination' and 1 or 0) ) or ttd <5 and debuff[classtable.FesteringWoundDeBuff].count >= 1 then
        pop_wounds = true
    else
        pop_wounds = false
    end
    if talents[classtable.VileContagion] and cooldown[classtable.VileContagion].duration <3 and RunicPower <60 and not st_planning then
        pooling_runic_power = true
    else
        pooling_runic_power = false
    end
    if ( not talents[classtable.RottenTouch] or talents[classtable.RottenTouch] and not debuff[classtable.RottenTouchDeBuff].up or RunicPowerDeficit <20 ) and ( ( talents[classtable.ImprovedDeathCoil] and ( targets == 2 or talents[classtable.CoilofDevastation] ) or Runes <3 or ( UnitExists('pet') and UnitName('pet')  == 'gargoyle' ) or buff[classtable.SuddenDoomBuff].up or not pop_wounds and debuff[classtable.FesteringWoundDeBuff].count >= 4 ) ) then
        spend_rp = true
    else
        spend_rp = false
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
    classtable.DeathandDecayBuff = not talents[classtable.Defile] and 188290 or 152280
    classtable.FesteringWoundDeBuff = 194310
    classtable.FesteringScytheBuff = 458123
    classtable.SuddenDoomBuff = 81340
    classtable.DarkTransformationBuff = 377588
    classtable.VirulentPlagueDeBuff = 191587
    classtable.FrostFeverDeBuff = 55095
    classtable.BloodPlagueDeBuff = 55078
    classtable.FestermightBuff = 377591
    classtable.InflictionofSorrowBuff = 0
    classtable.CommanderoftheDeadBuff = 390260
    classtable.DeathandDecayDebuff = 52212
    classtable.VampiricStrikeBuff = 0
    classtable.EssenceoftheBloodQueenBuff = 0
    classtable.GiftoftheSanlaynBuff = 0
    classtable.RunicCorruptionBuff = 51460
    classtable.DeathRotDeBuff = 377540
    classtable.RottenTouchDeBuff = 390276
	classtable.WoundSpender = st_planning and classtable.ClawingShadows or classtable.Epidemic
	classtable.FesteringScythe = 458128
	if buff[classtable.FesteringScytheBuff].up then
		classtable.FesteringStrike = classtable.FesteringScythe
	else
		classtable.FesteringStrike = 85948
	end

    Unholy:variables()
    --if (talents[classtable.VampiricStrike]) then
    --    local san_trinketsCheck = Unholy:san_trinkets()
    --    if san_trinketsCheck then
    --        return Unholy:san_trinkets()
    --    end
    --end
    --if (not talents[classtable.VampiricStrike]) then
    --    local trinketsCheck = Unholy:trinkets()
    --    if trinketsCheck then
    --        return Unholy:trinkets()
    --    end
    --end
    --local racialsCheck = Unholy:racials()
    --if racialsCheck then
    --    return racialsCheck
    --end
    local cds_sharedCheck = Unholy:cds_shared()
    if cds_sharedCheck then
        return cds_sharedCheck
    end
    if (not talents[classtable.VampiricStrike]) then
        local cdsCheck = Unholy:cds()
        if cdsCheck then
            return Unholy:cds()
        end
    end
    if (talents[classtable.VampiricStrike]) then
        local cds_sanCheck = Unholy:cds_san()
        if cds_sanCheck then
            return Unholy:cds_san()
        end
    end
    if (targets <4 and targets >= 2) then
        local cleaveCheck = Unholy:cleave()
        if cleaveCheck then
            return Unholy:cleave()
        end
    end
    if (targets >= 4 and buff[classtable.DeathandDecayBuff].up) then
        local aoe_burstCheck = Unholy:aoe_burst()
        if aoe_burstCheck then
            return Unholy:aoe_burst()
        end
    end
    if (targets >= 4 and not buff[classtable.DeathandDecayBuff].up) then
        local aoeCheck = Unholy:aoe()
        if aoeCheck then
            return Unholy:aoe()
        end
    end
    if (talents[classtable.GiftoftheSanlayn] and not buff[classtable.GiftoftheSanlaynBuff].up and buff[classtable.EssenceoftheBloodQueenBuff].remains <cooldown[classtable.DarkTransformation].duration + 2) then
        local san_fishingCheck = Unholy:san_fishing()
        if san_fishingCheck then
            return Unholy:san_fishing()
        end
    end
    if (targets == 1 and talents[classtable.VampiricStrike]) then
        local san_stCheck = Unholy:san_st()
        if san_stCheck then
            return Unholy:san_st()
        end
    end
    if (targets == 1 and not talents[classtable.VampiricStrike]) then
        local stCheck = Unholy:st()
        if stCheck then
            return Unholy:st()
        end
    end
end
