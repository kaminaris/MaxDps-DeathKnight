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

local trinket_1_buffs
local trinket_2_buffs
local trinket_1_exclude
local trinket_2_exclude
local damage_trinket_priority
local death_strike_dump_amount
local bone_shield_refresh_value
local heart_strike_rp_drw
local heart_strike_rp

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
    if (MaxDps:FindSpell(classtable.BloodBoil) and CheckSpellCosts(classtable.BloodBoil, 'BloodBoil')) and (not debuff[classtable.BloodPlagueDeBuff].up) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:FindSpell(classtable.Tombstone) and CheckSpellCosts(classtable.Tombstone, 'Tombstone')) and (buff[classtable.BoneShieldBuff].count >5 and Runes >= 2 and RunicPowerDeficit >= 30 and not talents[classtable.ShatteringBone] or ( talents[classtable.ShatteringBone] and debuff[classtable.DeathandDecayDebuff].up )) and cooldown[classtable.Tombstone].ready then
        MaxDps:GlowCooldown(classtable.Tombstone, cooldown[classtable.Tombstone].ready)
    end
    if (MaxDps:FindSpell(classtable.DeathStrike) and CheckSpellCosts(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd or buff[classtable.IcyTalonsBuff].remains <= gcd) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:FindSpell(classtable.Marrowrend) and CheckSpellCosts(classtable.Marrowrend, 'Marrowrend')) and (( buff[classtable.BoneShieldBuff].remains <= 4 or buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value ) and RunicPowerDeficit >20) and cooldown[classtable.Marrowrend].ready then
        return classtable.Marrowrend
    end
    if (MaxDps:FindSpell(classtable.SoulReaper) and CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (targets == 1 and MaxDps:GetTimeToPct(35) <5 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:FindSpell(classtable.SoulReaper) and CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (MaxDps:GetTimeToPct(35) <5 and targets >= 2 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:FindSpell(classtable.DeathandDecay) and CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (not debuff[classtable.DeathandDecayDebuff].up and ( talents[classtable.SanguineGround] or talents[classtable.UnholyGround] )) and cooldown[classtable.DeathandDecay].charges >= cooldown[classtable.DeathandDecay].maxCharges and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (MaxDps:FindSpell(classtable.BloodBoil) and CheckSpellCosts(classtable.BloodBoil, 'BloodBoil')) and (targets >2 and cooldown[classtable.BloodBoil].charges >= 1.1) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    heart_strike_rp_drw = ( 25 + targets * (talents[classtable.Heartbreaker] and talents[classtable.Heartbreaker] or 0) * 2 )
    if (MaxDps:FindSpell(classtable.DeathStrike) and CheckSpellCosts(classtable.DeathStrike, 'DeathStrike')) and (RunicPowerDeficit <= heart_strike_rp_drw or RunicPower >= death_strike_dump_amount) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:FindSpell(classtable.Consumption) and CheckSpellCosts(classtable.Consumption, 'Consumption')) and cooldown[classtable.Consumption].ready then
        return classtable.Consumption
    end
    if (MaxDps:FindSpell(classtable.BloodBoil) and CheckSpellCosts(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.1 and buff[classtable.HemostasisBuff].count <5) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:FindSpell(classtable.HeartStrike) and CheckSpellCosts(classtable.HeartStrike, 'HeartStrike')) and (DeathKnight:TimeToRunes(2) <gcd or RunicPowerDeficit >= heart_strike_rp_drw) and cooldown[classtable.HeartStrike].ready then
        return classtable.HeartStrike
    end
end
local function racials()
end
function Blood:standard()
    if (MaxDps:FindSpell(classtable.Tombstone) and CheckSpellCosts(classtable.Tombstone, 'Tombstone')) and (buff[classtable.BoneShieldBuff].count >5 and Runes >= 2 and RunicPowerDeficit >= 30 and not talents[classtable.ShatteringBone] or ( talents[classtable.ShatteringBone] and debuff[classtable.DeathandDecayDebuff].up ) and cooldown[classtable.DancingRuneWeapon].remains >= 25) and cooldown[classtable.Tombstone].ready then
        MaxDps:GlowCooldown(classtable.Tombstone, cooldown[classtable.Tombstone].ready)
    end
    heart_strike_rp = ( 10 + targets * (talents[classtable.Heartbreaker] and talents[classtable.Heartbreaker] or 0) * 2 )
    if (MaxDps:FindSpell(classtable.DeathStrike) and CheckSpellCosts(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd or buff[classtable.IcyTalonsBuff].remains <= gcd or RunicPower >= death_strike_dump_amount or RunicPowerDeficit <= heart_strike_rp or ttd <10) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:FindSpell(classtable.DeathsCaress) and CheckSpellCosts(classtable.DeathsCaress, 'DeathsCaress')) and (( buff[classtable.BoneShieldBuff].remains <= 4 or ( buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value + 1 ) ) and RunicPowerDeficit >10 and not ( talents[classtable.InsatiableBlade] and cooldown[classtable.DancingRuneWeapon].remains <buff[classtable.BoneShieldBuff].remains ) and not talents[classtable.Consumption] and not talents[classtable.Blooddrinker] and DeathKnight:TimeToRunes(3) >gcd) and cooldown[classtable.DeathsCaress].ready then
        return classtable.DeathsCaress
    end
    if (MaxDps:FindSpell(classtable.Marrowrend) and CheckSpellCosts(classtable.Marrowrend, 'Marrowrend')) and (( buff[classtable.BoneShieldBuff].remains <= 4 or buff[classtable.BoneShieldBuff].count <bone_shield_refresh_value ) and RunicPowerDeficit >20 and not ( talents[classtable.InsatiableBlade] and cooldown[classtable.DancingRuneWeapon].remains <buff[classtable.BoneShieldBuff].remains )) and cooldown[classtable.Marrowrend].ready then
        return classtable.Marrowrend
    end
    if (MaxDps:FindSpell(classtable.Consumption) and CheckSpellCosts(classtable.Consumption, 'Consumption')) and cooldown[classtable.Consumption].ready then
        return classtable.Consumption
    end
    if (MaxDps:FindSpell(classtable.SoulReaper) and CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (targets == 1 and MaxDps:GetTimeToPct(35) <5 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:FindSpell(classtable.SoulReaper) and CheckSpellCosts(classtable.SoulReaper, 'SoulReaper')) and (MaxDps:GetTimeToPct(35) <5 and targets >= 2 and ttd >( debuff[classtable.SoulReaperDeBuff].remains + 5 )) and cooldown[classtable.SoulReaper].ready then
        return classtable.SoulReaper
    end
    if (MaxDps:FindSpell(classtable.Bonestorm) and CheckSpellCosts(classtable.Bonestorm, 'Bonestorm')) and (buff[classtable.BoneShieldBuff].count >= 5) and cooldown[classtable.Bonestorm].ready then
        return classtable.Bonestorm
    end
    if (MaxDps:FindSpell(classtable.BloodBoil) and CheckSpellCosts(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.8 and ( buff[classtable.HemostasisBuff].count <= ( 5 - targets ) or targets >2 )) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:FindSpell(classtable.HeartStrike) and CheckSpellCosts(classtable.HeartStrike, 'HeartStrike')) and (DeathKnight:TimeToRunes(4) <gcd) and cooldown[classtable.HeartStrike].ready then
        return classtable.HeartStrike
    end
    if (MaxDps:FindSpell(classtable.BloodBoil) and CheckSpellCosts(classtable.BloodBoil, 'BloodBoil')) and (cooldown[classtable.BloodBoil].charges >= 1.1) and cooldown[classtable.BloodBoil].ready then
        return classtable.BloodBoil
    end
    if (MaxDps:FindSpell(classtable.HeartStrike) and CheckSpellCosts(classtable.HeartStrike, 'HeartStrike')) and (( Runes >1 and ( DeathKnight:TimeToRunes(3) <gcd or buff[classtable.BoneShieldBuff].count >7 ) )) and cooldown[classtable.HeartStrike].ready then
        return classtable.HeartStrike
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
    classtable.BloodPlagueDeBuff = 55078
    classtable.BoneShieldBuff = 195181
    classtable.DeathandDecayDebuff = 52212
    classtable.CoagulopathyBuff = 391481
    classtable.IcyTalonsBuff = 194879
    classtable.SoulReaperDeBuff = 343294
    classtable.HemostasisBuff = 273947

    for spellId in pairs(MaxDps.Flags) do
        self.Flags[spellId] = false
        self:ClearGlowIndependent(spellId, spellId)
    end

    death_strike_dump_amount = 65
    if talents[classtable.Consumption] or talents[classtable.Blooddrinker] then
        bone_shield_refresh_value = 4
    else
        bone_shield_refresh_value = 5
    end
    if (MaxDps:FindSpell(classtable.MindFreeze) and CheckSpellCosts(classtable.MindFreeze, 'MindFreeze')) and (UnitCastingInfo('target') and select(8,UnitCastingInfo('target')) == false) and cooldown[classtable.MindFreeze].ready then
        MaxDps:GlowCooldown(classtable.MindFreeze, select(8,UnitCastingInfo('target') == false) and cooldown[classtable.MindFreeze].ready)
    end
    if (MaxDps:FindSpell(classtable.RaiseDead) and CheckSpellCosts(classtable.RaiseDead, 'RaiseDead')) and cooldown[classtable.RaiseDead].ready then
        MaxDps:GlowCooldown(classtable.RaiseDead, cooldown[classtable.RaiseDead].ready)
    end
    if (MaxDps:FindSpell(classtable.ReapersMark) and CheckSpellCosts(classtable.ReapersMark, 'ReapersMark')) and cooldown[classtable.ReapersMark].ready then
        MaxDps:GlowCooldown(classtable.ReapersMark, cooldown[classtable.ReapersMark].ready)
    end
    if (MaxDps:FindSpell(classtable.IceboundFortitude) and CheckSpellCosts(classtable.IceboundFortitude, 'IceboundFortitude')) and (not ( buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.VampiricBloodBuff].up )) and cooldown[classtable.IceboundFortitude].ready then
        MaxDps:GlowCooldown(classtable.IceboundFortitude, cooldown[classtable.IceboundFortitude].ready)
    end
    if (MaxDps:FindSpell(classtable.VampiricBlood) and CheckSpellCosts(classtable.VampiricBlood, 'VampiricBlood')) and (not ( buff[classtable.DancingRuneWeaponBuff].up or buff[classtable.IceboundFortitudeBuff].up or buff[classtable.VampiricBloodBuff].up )) and cooldown[classtable.VampiricBlood].ready then
        MaxDps:GlowCooldown(classtable.VampiricBlood, cooldown[classtable.VampiricBlood].ready)
    end
    if (MaxDps:FindSpell(classtable.DeathsCaress) and CheckSpellCosts(classtable.DeathsCaress, 'DeathsCaress')) and (not buff[classtable.BoneShieldBuff].up) and cooldown[classtable.DeathsCaress].ready then
        return classtable.DeathsCaress
    end
    if (MaxDps:FindSpell(classtable.DeathandDecay) and CheckSpellCosts(classtable.DeathandDecay, 'DeathandDecay')) and (not debuff[classtable.DeathandDecayDebuff].up and ( talents[classtable.UnholyGround] or talents[classtable.SanguineGround] or targets >3 or buff[classtable.CrimsonScourgeBuff].up )) and cooldown[classtable.DeathandDecay].charges >= cooldown[classtable.DeathandDecay].maxCharges and cooldown[classtable.DeathandDecay].ready then
        return classtable.DeathandDecay
    end
    if (MaxDps:FindSpell(classtable.DeathStrike) and CheckSpellCosts(classtable.DeathStrike, 'DeathStrike')) and (buff[classtable.CoagulopathyBuff].remains <= gcd or buff[classtable.IcyTalonsBuff].remains <= gcd or RunicPower >= death_strike_dump_amount or RunicPowerDeficit <= heart_strike_rp or ttd <10) and cooldown[classtable.DeathStrike].ready then
        return classtable.DeathStrike
    end
    if (MaxDps:FindSpell(classtable.Blooddrinker) and CheckSpellCosts(classtable.Blooddrinker, 'Blooddrinker')) and (not buff[classtable.DancingRuneWeaponBuff].up) and cooldown[classtable.Blooddrinker].ready then
        MaxDps:GlowCooldown(classtable.Blooddrinker, cooldown[classtable.Blooddrinker].ready)
    end
    if (MaxDps:FindSpell(classtable.SacrificialPact) and CheckSpellCosts(classtable.SacrificialPact, 'SacrificialPact')) and (not buff[classtable.DancingRuneWeaponBuff].up and ( GetTotemDuration('Risen Ghoul') <2 or ttd <gcd )) and cooldown[classtable.SacrificialPact].ready then
        MaxDps:GlowCooldown(classtable.SacrificialPact, cooldown[classtable.SacrificialPact].ready)
    end
    if (MaxDps:FindSpell(classtable.BloodTap) and CheckSpellCosts(classtable.BloodTap, 'BloodTap')) and (( Runes <= 2 and DeathKnight:TimeToRunes(4) >gcd and cooldown[classtable.BloodTap].charges >= 1.8 ) or DeathKnight:TimeToRunes(3) >gcd) and cooldown[classtable.BloodTap].ready then
        MaxDps:GlowCooldown(classtable.BloodTap, cooldown[classtable.BloodTap].ready)
    end
    if (MaxDps:FindSpell(classtable.GorefiendsGrasp) and CheckSpellCosts(classtable.GorefiendsGrasp, 'GorefiendsGrasp')) and (talents[classtable.TighteningGrasp]) and cooldown[classtable.GorefiendsGrasp].ready then
        MaxDps:GlowCooldown(classtable.GorefiendsGrasp, cooldown[classtable.GorefiendsGrasp].ready)
    end
    if (MaxDps:FindSpell(classtable.EmpowerRuneWeapon) and CheckSpellCosts(classtable.EmpowerRuneWeapon, 'EmpowerRuneWeapon')) and (Runes <6 and RunicPowerDeficit >5) and cooldown[classtable.EmpowerRuneWeapon].ready then
        MaxDps:GlowCooldown(classtable.EmpowerRuneWeapon, cooldown[classtable.EmpowerRuneWeapon].ready)
    end
    if (MaxDps:FindSpell(classtable.AbominationLimb) and CheckSpellCosts(classtable.AbominationLimb, 'AbominationLimb')) and cooldown[classtable.AbominationLimb].ready then
        MaxDps:GlowCooldown(classtable.AbominationLimb, cooldown[classtable.AbominationLimb].ready)
    end
    if (MaxDps:FindSpell(classtable.DancingRuneWeapon) and CheckSpellCosts(classtable.DancingRuneWeapon, 'DancingRuneWeapon')) and (not buff[classtable.DancingRuneWeaponBuff].up) and cooldown[classtable.DancingRuneWeapon].ready then
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
