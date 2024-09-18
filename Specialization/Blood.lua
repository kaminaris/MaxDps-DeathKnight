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

local Blood = {}

local trinket_one_buffs
local trinket_two_buffs
local trinket_one_exclude
local trinket_two_exclude
local damage_trinket_priority
local death_strike_dump_amount
local bone_shield_refresh_value
local heart_strike_rp_drw
local heart_strike_rp

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

function Blood:precombat()
end
function Blood:drw_up()
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and ( buff[classtable.BoneShieldBuff].remains <= 4 and buff[classtable.DancingRuneWeaponBuff].remains <= gcd*3 and not buff[classtable.BonestormBuff].up ) and cooldown[classtable.Marrowrend].ready then
        return classtable.Marrowrend
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (not debuff[classtable.BloodPlagueDeBuff].up) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:CheckSpellUsable(classtable.Tombstone, 'Tombstone')) and (buff[classtable.BoneShieldBuff].count >5 and Runes >= 2 and RunicPowerDeficit >= 30 and not talents[classtable.ShatteringBone] or ( talents[classtable.ShatteringBone] and debuff[classtable.DeathandDecayDebuff].up )) and cooldown[classtable.Tombstone].ready then
        MaxDps:GlowCooldown(classtable.Tombstone, cooldown[classtable.Tombstone].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd or buff[classtable.IcyTalonsBuff].remains <= gcd) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and (( buff[classtable.BoneShieldBuff].remains <= 4 or buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value ) and RunicPowerDeficit >20) and cooldown[classtable.Marrowrend].ready then
        return classtable.Marrowrend
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (targets == 1 and MaxDps:GetTimeToPct(35) <5 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (MaxDps:GetTimeToPct(35) <5 and targets >= 2 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not debuff[classtable.DeathandDecayDebuff].up and ( talents[classtable.SanguineGround] or talents[classtable.UnholyGround] )) and cooldown[classtable.DeathandDecay].charges >= cooldown[classtable.DeathandDecay].maxCharges and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (targets >2 and cooldown[classtable.BloodBoil].charges >= 1.1) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    heart_strike_rp_drw = ( 25 + targets * (talents[classtable.Heartbreaker] and talents[classtable.Heartbreaker] or 0) * 2 )
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (RunicPowerDeficit <= heart_strike_rp_drw or RunicPower >= death_strike_dump_amount) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Consumption, 'Consumption')) and cooldown[classtable.Consumption].ready then
        return classtable.Consumption
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.1 and buff[classtable.HemostasisBuff].count <5) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (DeathKnight:TimeToRunes(2) <gcd or RunicPowerDeficit >= heart_strike_rp_drw) and cooldown[classtable.HeartStrike].ready then
        return classtable.HeartStrike
    end
end
function Blood:racials()
end
function Blood:standard()
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and ( buff[classtable.BoneShieldBuff].remains <= 3 ) and cooldown[classtable.Marrowrend].ready then
        return classtable.Marrowrend
    end
    if (MaxDps:CheckSpellUsable(classtable.Tombstone, 'Tombstone')) and (buff[classtable.BoneShieldBuff].count >5 and Runes >= 2 and RunicPowerDeficit >= 30 and not talents[classtable.ShatteringBone] or ( talents[classtable.ShatteringBone] and debuff[classtable.DeathandDecayDebuff].up ) and cooldown[classtable.DancingRuneWeapon].remains >= 25) and cooldown[classtable.Tombstone].ready then
        MaxDps:GlowCooldown(classtable.Tombstone, cooldown[classtable.Tombstone].ready)
    end
    heart_strike_rp = ( 10 + targets * (talents[classtable.Heartbreaker] and talents[classtable.Heartbreaker] or 0) * 2 )
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd or buff[classtable.IcyTalonsBuff].remains <= gcd or RunicPower >= death_strike_dump_amount or RunicPowerDeficit <= heart_strike_rp or ttd <10) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathsCaress, 'DeathsCaress')) and (( buff[classtable.BoneShieldBuff].remains <= 4 or ( buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value + 1 ) ) and RunicPowerDeficit >10 and not ( talents[classtable.InsatiableBlade] and cooldown[classtable.DancingRuneWeapon].remains <buff[classtable.BoneShieldBuff].remains ) and not talents[classtable.Consumption] and not talents[classtable.Blooddrinker] and DeathKnight:TimeToRunes(3) >gcd) and cooldown[classtable.DeathsCaress].ready then
        return classtable.DeathsCaress
    end
    if (MaxDps:CheckSpellUsable(classtable.Marrowrend, 'Marrowrend')) and (( buff[classtable.BoneShieldBuff].remains <= 4 or buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value ) and RunicPowerDeficit >20 and not ( talents[classtable.InsatiableBlade] and cooldown[classtable.DancingRuneWeapon].remains <buff[classtable.BoneShieldBuff].remains )) and cooldown[classtable.Marrowrend].ready then
        return classtable.Marrowrend
    end
    if (MaxDps:CheckSpellUsable(classtable.Consumption, 'Consumption')) and cooldown[classtable.Consumption].ready then
        return classtable.Consumption
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (targets == 1 and MaxDps:GetTimeToPct(35) <5 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:CheckSpellUsable(classtable.SoulReaper, 'SoulReaper')) and (MaxDps:GetTimeToPct(35) <5 and targets >= 2 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:CheckSpellUsable(classtable.Bonestorm, 'Bonestorm')) and (buff[classtable.BoneShieldBuff].count >= 5) and cooldown[classtable.Bonestorm].ready then
        return classtable.Bonestorm
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.8 and ( buff[classtable.HemostasisBuff].count <= ( 5 - targets ) or targets >2 )) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (DeathKnight:TimeToRunes(4) <gcd) and cooldown[classtable.HeartStrike].ready then
        return classtable.HeartStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.1) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:CheckSpellUsable(classtable.HeartStrike, 'HeartStrike')) and (( Runes >1 and ( DeathKnight:TimeToRunes(3) <gcd or buff[classtable.BoneShieldBuff].count >7 ) )) and cooldown[classtable.HeartStrike].ready then
        return classtable.HeartStrike
    end
end
function Blood:trinkets()
end

function Blood:callaction()
    death_strike_dump_amount = 65
    heart_strike_rp = ( 10 + targets * (talents[classtable.Heartbreaker] and talents[classtable.Heartbreaker] or 0) * 2 )
    if talents[classtable.Consumption] or talents[classtable.Blooddrinker] then
        bone_shield_refresh_value = 4
    else
        bone_shield_refresh_value = 5
    end
    if (MaxDps:CheckSpellUsable(classtable.MindFreeze, 'MindFreeze')) and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and cooldown[classtable.MindFreeze].ready then
        MaxDps:GlowCooldown(classtable.MindFreeze, ( select(8,UnitCastingInfo('target')) ~= nil and not select(8,UnitCastingInfo('target')) or select(7,UnitChannelInfo('target')) ~= nil and not select(7,UnitChannelInfo('target'))) )
    end
    local trinketsCheck = Blood:trinkets()
    if trinketsCheck then
        return trinketsCheck
    end
    if (MaxDps:CheckSpellUsable(classtable.RaiseDead, 'RaiseDead')) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.ReapersMark, 'ReapersMark')) and cooldown[classtable.ReapersMark].ready then
        MaxDps:GlowCooldown(classtable.ReapersMark, cooldown[classtable.ReapersMark].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.IceboundFortitude, 'IceboundFortitude')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3) and not ( buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.VampiricBloodBuff].up )) and cooldown[classtable.IceboundFortitude].ready then
        MaxDps:GlowCooldown(classtable.IceboundFortitude, cooldown[classtable.IceboundFortitude].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.RuneTap, 'RuneTap')) and ((UnitThreatSituation('player') == 2 or UnitThreatSituation('player') == 3)  and not ( buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.VampiricBloodBuff].up or buff[classtable.IceboundFortitudeBuff].up )) and cooldown[classtable.RuneTap].ready then
        return classtable.RuneTap
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.BloodShieldBuff].up and buff[classtable.BloodShieldBuff].remains <= gcd) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathsCaress, 'DeathsCaress')) and (not buff[classtable.BoneShieldBuff].up) and cooldown[classtable.DeathsCaress].ready then
        return classtable.DeathsCaress
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathandDecay, 'DeathandDecay')) and (not debuff[classtable.DeathandDecayDebuff].up and ( talents[classtable.UnholyGround] or talents[classtable.SanguineGround] or targets >3 or buff[classtable.CrimsonScourgeBuff].up )) and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (MaxDps:CheckSpellUsable(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd or buff[classtable.IcyTalonsBuff].remains <= gcd or RunicPower >= death_strike_dump_amount or RunicPowerDeficit <= heart_strike_rp or ttd <10) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:CheckSpellUsable(classtable.Blooddrinker, 'Blooddrinker')) and (not buff[classtable.DancingRuneWeaponBuff].up) and cooldown[classtable.Blooddrinker].ready then
        MaxDps:GlowCooldown(classtable.Blooddrinker, cooldown[classtable.Blooddrinker].ready)
    end
    local racialsCheck = Blood:racials()
    if racialsCheck then
        return racialsCheck
    end
    if (MaxDps:CheckSpellUsable(classtable.SacrificialPact, 'SacrificialPact')) and (not buff[classtable.DancingRuneWeaponBuff].up and ( GetTotemDuration('Risen Ghoul') <2 or ttd <gcd )) and cooldown[classtable.SacrificialPact].ready then
        MaxDps:GlowCooldown(classtable.SacrificialPact, cooldown[classtable.SacrificialPact].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.BloodTap, 'BloodTap')) and (( Runes <= 2 and DeathKnight:TimeToRunes(4) >gcd and cooldown[classtable.BloodTap].charges >= 1.8 ) or DeathKnight:TimeToRunes(3) >gcd) and cooldown[classtable.BloodTap].ready then
        MaxDps:GlowCooldown(classtable.BloodTap, cooldown[classtable.BloodTap].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.GorefiendsGrasp, 'GorefiendsGrasp')) and (talents[classtable.TighteningGrasp]) and cooldown[classtable.GorefiendsGrasp].ready then
        MaxDps:GlowCooldown(classtable.GorefiendsGrasp, cooldown[classtable.GorefiendsGrasp].ready)
    end
    --if (MaxDps:CheckSpellUsable(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (Runes <6 and RunicPowerDeficit >5) and cooldown[classtable.EmpowerRuneWeapon].ready then
    --    MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    --end
    if (MaxDps:CheckSpellUsable(classtable.AbominationLimb, 'AbominationLimb')) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:CheckSpellUsable(classtable.DancingRuneWeapon, 'DancingRuneWeapon')) and (not buff[classtable.DancingRuneWeaponBuff].up) and cooldown[classtable.DancingRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.DancingRuneWeapon, cooldown[classtable.DancingRuneWeapon].ready)
    end
    if (buff[classtable.DancingRuneWeaponBuff].up) then
        local drw_upCheck = Blood:drw_up()
        if drw_upCheck then
            return Blood:drw_up()
        end
    end
    local standardCheck = Blood:standard()
    if standardCheck then
        return standardCheck
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
    classtable.BloodPlagueDeBuff = 55078
    classtable.BoneShieldBuff = 195181
    classtable.DeathandDecayDebuff = 52212
    classtable.CoagulopathyBuff = 391481
    classtable.IcyTalonsBuff = 194879
    classtable.SoulReaperDeBuff = 343294
    classtable.HemostasisBuff = 273947
    classtable.DancingRuneWeaponBuff = 81256
    classtable.VampiricBloodBuff = 55233
    classtable.IceboundFortitudeBuff = 48792
    classtable.BloodShieldBuff = 77535
    classtable.CrimsonScourgeBuff = 81141
    classtable.BonestormBuff = 194844

    local precombatCheck = Blood:precombat()
    if precombatCheck then
        return Blood:precombat()
    end

    local callactionCheck = Blood:callaction()
    if callactionCheck then
        return Blood:callaction()
    end
end
