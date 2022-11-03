local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end
local DeathKnight = addonTable.DeathKnight;
local MaxDps = MaxDps;

local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local RunicPower = Enum.PowerType.RunicPower;
local Runes = Enum.PowerType.Runes;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local BL = {
	BloodBoil             	= 50842,
	Blooddrinker          	= 206931,
	BloodTap              	= 221699,
	BoneShield            	= 195181,
	Bonestorm             	= 194844,
	Consumption           	= 274156,
	CrimsonScourge        	= 81141,
	DancingRuneWeapon     	= 49028,
	DancingRuneWeaponBuff 	= 81256,
	DeathsCaress			= 195292,
	Heartbreaker          	= 221536,
	HeartStrike           	= 206930,
	Hemostasis            	= 273947,
	Marrowrend            	= 195182,
	RapidDecomposition    	= 194662,
	RelishInBlood         	= 317610,
	ShackleTheUnworthy    	= 312202,
	SwarmingMist          	= 311648,
	Tombstone             	= 219809,
};

setmetatable(BL, DeathKnight.spellMeta);

function DeathKnight:Blood()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local currentSpell = fd.currentSpell;
	local talents = fd.talents;
	local covenantId = fd.covenant.covenantId;
	local runes = DeathKnight:Runes(fd.timeShift);
	local runicPower = UnitPower('player', RunicPower);
	local targets = MaxDps:SmartAoe();
	local targetHpPercent = MaxDps:TargetPercentHealth() * 100;
	fd.targetHpPercent = targetHpPercent;
	
	fd.targets = targets;
	fd.runes = runes;
	fd.runicPower = runicPower;

	DeathKnight:BloodGlowCooldowns();
	
	if talents[COMMON.SoulReaper] and targetHpPercent <= 35 and cooldown[COMMON.SoulReaper].ready then
		return COMMON.SoulReaper;
	end

	if buff[BL.DancingRuneWeaponBuff].up then
		return DeathKnight:DancingRuneWeaponUp();
	end
	if not buff[BL.DancingRuneWeaponBuff].up then
		return DeathKnight:DancingRuneWeaponNotUp();
	end

end

function DeathKnight:DancingRuneWeaponUp()
	local fd = MaxDps.FrameData;
	local buff = fd.buff;
	local runicPower = fd.runicPower;
	local debuff = fd.debuff;
	local cooldown = fd.cooldown;
	local runes = fd.runes;
	local covenantId = fd.covenant.covenantId;
	
	local deathAndDecay;
	
	if covenantId == NightFae then
		deathAndDecay = COMMON.DeathsDue;
	else
		deathAndDecay = COMMON.DeathAndDecay;
	end

	if buff[BL.DancingRuneWeaponBuff].remains < 4 and buff[BL.BoneShield].remains < 20 then
		return BL.Marrowrend;
	end
	
	if not debuff[COMMON.DeathAndDecay].up and cooldown[COMMON.DeathAndDecay].ready then
		return deathAndDecay;
	end
	
	if buff[BL.BoneShield].count <= 2 then
		return BL.DeathsCaress;
	end
	
	if runicPower >= 75 or buff[COMMON.IcyTalons].remains < 3 then
		return COMMON.DeathStrike;
	end
	
	if cooldown[BL.BloodBoil].charges >= 2 then
		return BL.BloodBoil;
	end
	
	if runes >= 3 then
		return BL.HeartStrike;
	end
end

function DeathKnight:DancingRuneWeaponNotUp()
	local fd = MaxDps.FrameData;
	local buff = fd.buff;
	local runicPower = fd.runicPower;
	local debuff = fd.debuff;
	local cooldown = fd.cooldown;
	local runes = fd.runes;
	local covenantId = fd.covenant.covenantId;
	
	local deathAndDecay;
	
	if covenantId == NightFae then
		deathAndDecay = COMMON.DeathsDue;
	else
		deathAndDecay = COMMON.DeathAndDecay;
	end
	
	if buff[BL.BoneShield].remains < 4 then
		return BL.DeathsCaress;
	end
	if not buff[COMMON.DeathAndDecayBuff].up and cooldown[COMMON.DeathAndDecay].ready then
		return deathAndDecay;
	end
	
	if runes >= 2 and buff[BL.BoneShield].count <= 4 then
		return BL.Marrowrend;
	end
	
	if runes < 2 and buff[BL.BoneShield].count <= 4 then
		return BL.DeathsCaress;
	end
	
	if runicPower >= 75 or buff[COMMON.IcyTalons].remains < 3 then
		return COMMON.DeathStrike;
	end
	
	if cooldown[BL.BloodBoil].charges >= 2 then
		return BL.BloodBoil;
	end
	
	if runes >= 3 then
		return BL.HeartStrike;
	end
end

function DeathKnight:BloodGlowCooldowns()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local covenantId = fd.covenant.covenantId;

	local abominationLimbReady = covenantId == Necrolord and cooldown[COMMON.AbominationLimb].ready;
	local abominationLimbTalentReady = talents[COMMON.AbominationLimbTalent] and cooldown[COMMON.AbominationLimbTalent].ready;
	local dancingRuneWeaponReady = talents[BL.DancingRuneWeapon] and cooldown[BL.DancingRuneWeapon].ready;
	local boneStormReady = talents[BL.Bonestorm] and cooldown[BL.Bonestorm].ready;
	local empowerRuneweaponReady = talents[COMMON.EmpowerRuneWeapon] and cooldown[COMMON.EmpowerRuneWeapon].ready;

	if DeathKnight.db.alwaysGlowCooldowns then
		MaxDps:GlowCooldown(COMMON.AbominationLimb, abominationLimbReady);
		MaxDps:GlowCooldown(COMMON.AbominationLimbTalent, abominationLimbTalentReady);
		MaxDps:GlowCooldown(BL.Bonestorm, boneStormReady);
		MaxDps:GlowCooldown(COMMON.EmpowerRuneWeapon, empowerRuneweaponReady);
		MaxDps:GlowCooldown(BL.DancingRuneWeapon, dancingRuneWeaponReady);
	else
		MaxDps:GlowCooldown(BL.Bonestorm, boneStormReady);
		MaxDps:GlowCooldown(COMMON.EmpowerRuneWeapon, empowerRuneweaponReady);
		MaxDps:GlowCooldown(COMMON.AbominationLimb, abominationLimbReady);
		MaxDps:GlowCooldown(COMMON.AbominationLimbTalent, abominationLimbTalentReady);
		MaxDps:GlowCooldown(BL.DancingRuneWeapon, dancingRuneWeaponReady);
	end
end

function DeathKnight:BloodCovenants()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local covenantId = fd.covenant.covenantId;
	local runes = fd.runes;
	local runicPower = fd.runicPower;
	local ghoulRemains = cooldown[COMMON.RaiseDead].remains - (cooldown[COMMON.RaiseDead].duration - 60);

	-- death_strike,if=covenant.night_fae&buff.deaths_due.remains>6&runic_power>70;
	if runicPower >= 45 and
		covenantId == NightFae and
		buff[BL.DeathsDueBuff].remains > 6 and
		runicPower > 70
	then
		return COMMON.DeathStrike;
	end

	-- heart_strike,if=covenant.night_fae&death_and_decay.ticking&((buff.deaths_due.up|buff.dancing_rune_weapon.up)&buff.deaths_due.remains<6);
	if runes >= 1 and
		covenantId == NightFae and
		debuff[BL.DeathAndDecay].up and
		(
			(buff[BL.DeathsDueBuff].up or buff[BL.DancingRuneWeapon].up) and
				buff[BL.DeathsDueBuff].remains < 6
		)
	then
		return BL.HeartStrike;
	end

	-- deaths_due,if=!buff.deaths_due.up|buff.deaths_due.remains<4|buff.crimson_scourge.up;
	if covenantId == NightFae and
		cooldown[BL.DeathsDue].ready and
		(runes >= 1 or  buff[BL.CrimsonScourge].up) and
		(not buff[BL.DeathsDueBuff].up or buff[BL.DeathsDueBuff].remains < 4 or buff[BL.CrimsonScourge].up)
	then
		return BL.DeathsDue;
	end

	-- sacrificial_pact,if=(!covenant.night_fae|buff.deaths_due.remains>6)&!buff.dancing_rune_weapon.up&(pet.ghoul.remains<10|target.time_to_die<gcd);
	if cooldown[COMMON.SacrificialPact].ready and ghoulRemains > 0 and runicPower >= 20 and
		(
			(covenantId ~= NightFae or buff[BL.DeathsDueBuff].remains > 6) and
				not buff[BL.DancingRuneWeapon].up and
				(ghoulRemains < 10 or timeToDie < gcd)
		) then
		return COMMON.SacrificialPact;
	end

	-- death_strike,if=covenant.venthyr&runic_power>70&cooldown.swarming_mist.remains<3;
	if covenantId == Venthyr and
		runicPower > 70 and
		cooldown[BL.SwarmingMist].remains < 3
	then
		return COMMON.DeathStrike;
	end

	-- swarming_mist,if=!buff.dancing_rune_weapon.up;
	if covenantId == Venthyr and
		cooldown[BL.SwarmingMist].ready and
		runes >= 1 and
		not buff[BL.DancingRuneWeapon].up
	then
		return BL.SwarmingMist;
	end

	-- marrowrend,if=covenant.necrolord&buff.bone_shield.stack<=0;
	if runes >= 2 and
		covenantId == Necrolord and
		buff[BL.BoneShield].count <= 0
	then
		return BL.Marrowrend;
	end

	-- abomination_limb,if=!buff.dancing_rune_weapon.up;
	if covenantId == Necrolord and
		cooldown[BL.AbominationLimb].ready and
		not DeathKnight.db.abominationLimbAsCooldown and
		not buff[BL.DancingRuneWeapon].up
	then
		return BL.AbominationLimb;
	end

	-- shackle_the_unworthy,if=cooldown.dancing_rune_weapon.remains<3|!buff.dancing_rune_weapon.up;
	if covenantId == Kyrian and
		cooldown[BL.ShackleTheUnworthy].ready and
		(cooldown[BL.DancingRuneWeapon].remains < 3 or not buff[BL.DancingRuneWeapon].up)
	then
		return BL.ShackleTheUnworthy;
	end
end

function DeathKnight:BloodStandard()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local timeToDie = fd.timeToDie;
	local covenantId = fd.covenant.covenantId;
	local runes = fd.runes;
	local runicPower = fd.runicPower;
	local runicPowerMax = UnitPowerMax('player', RunicPower);
	local runicPowerDeficit = runicPowerMax - runicPower;
	local timeTo3Runes = DeathKnight:TimeToRunes(3);
	local timeTo4Runes = DeathKnight:TimeToRunes(4);

	-- blood_tap,if=rune<=2&rune.time_to_4>gcd&charges_fractional>=1.8;
	if talents[BL.BloodTap] and
		runes <= 2 and
		timeTo4Runes > gcd and
		cooldown[BL.BloodTap].charges >= 1.8
	then
		return BL.BloodTap;
	end

	-- dancing_rune_weapon,if=!talent.blooddrinker.enabled|!cooldown.blooddrinker.ready;
	if cooldown[BL.DancingRuneWeapon].ready and
		not DeathKnight.db.bloodDancingRuneWeaponAsCooldown and
		(not talents[BL.Blooddrinker] or not cooldown[BL.Blooddrinker].ready)
	then
		return BL.DancingRuneWeapon;
	end

	-- tombstone,if=buff.bone_shield.stack>=7&rune>=2;
	if talents[BL.Tombstone] and
		cooldown[BL.Tombstone].ready and
		buff[BL.BoneShield].count >= 7 and
		runes >= 2
	then
		return BL.Tombstone;
	end

	-- marrowrend,if=(!covenant.necrolord|buff.abomination_limb.up)&(buff.bone_shield.remains<=rune.time_to_3|buff.bone_shield.remains<=(gcd+cooldown.blooddrinker.ready*talent.blooddrinker.enabled*2)|buff.bone_shield.stack<3)&runic_power.deficit>=20;
	if runes >= 2 and
		(covenantId ~= Necrolord or buff[BL.AbominationLimb].up) and
		(
			buff[BL.BoneShield].remains <= timeTo3Runes or
				buff[BL.BoneShield].remains <= ( gcd + cooldown[BL.Blooddrinker].remains * (talents[BL.Blooddrinker] and 1 or 0) * 2 ) or
				buff[BL.BoneShield].count < 3
		) and
		runicPowerDeficit >= 20
	then
		return BL.Marrowrend;
	end

	-- death_strike,if=runic_power.deficit<=70;
	if runicPower >= 45 and
		runicPowerDeficit <= 70
	then
		return COMMON.DeathStrike;
	end

	-- marrowrend,if=buff.bone_shield.stack<6&runic_power.deficit>=15&(!covenant.night_fae|buff.deaths_due.remains>5);
	if runes >= 2 and
		buff[BL.BoneShield].count < 6 and
		runicPowerDeficit >= 15 and
		(covenantId ~= NightFae or buff[BL.DeathsDueBuff].remains > 5 )
	then
		return BL.Marrowrend;
	end

	-- heart_strike,if=!talent.blooddrinker.enabled&death_and_decay.remains<5&runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2);
	if runes >= 1 and
		not talents[BL.Blooddrinker] and
		debuff[BL.DeathAndDecay].remains < 5 and
		runicPowerDeficit <= ( 15 + (buff[BL.DancingRuneWeapon].up and 1 or 0) * 5 + targets * (talents[BL.Heartbreaker] and 1 or 0) * 2 )
	then
		return BL.HeartStrike;
	end

	-- blood_boil,if=charges_fractional>=1.8&(buff.hemostasis.stack<=(5-spell_targets.blood_boil)|spell_targets.blood_boil>2);
	if cooldown[BL.BloodBoil].charges >= 1.8 and
		(
			buff[BL.Hemostasis].count <= ( 5 - targets ) or
				targets > 2
		)
	then
		return BL.BloodBoil;
	end

	-- death_and_decay,if=(buff.crimson_scourge.up&talent.relish_in_blood.enabled)&runic_power.deficit>10;
	if cooldown[BL.DeathAndDecay].ready and
		buff[BL.CrimsonScourge].up and
		talents[BL.RelishInBlood] and
		runicPowerDeficit > 10
	then
		return BL.DeathAndDecay;
	end

	-- bonestorm,if=runic_power>=100&!buff.dancing_rune_weapon.up;
	if talents[BL.Bonestorm] and
		cooldown[BL.Bonestorm].ready and
		runicPower >= 100 and
		not buff[BL.DancingRuneWeapon].up
	then
		return BL.Bonestorm;
	end

	-- death_strike,if=runic_power.deficit<=(15+buff.dancing_rune_weapon.up*5+spell_targets.heart_strike*talent.heartbreaker.enabled*2)|target.1.time_to_die<10;
	if runicPower >= 45 and
		(
			runicPowerDeficit <= ( 15 + (buff[BL.DancingRuneWeapon].up and 1 or 0) * 5 + targets * (talents[BL.Heartbreaker] and 1 or 0) * 2 ) or
				timeToDie < 10
		)
	then
		return COMMON.DeathStrike;
	end

	-- death_and_decay,if=spell_targets.death_and_decay>=3;
	if cooldown[BL.DeathAndDecay].ready and
		runes >= 1 and
		targets >= 3
	then
		return BL.DeathAndDecay;
	end

	-- heart_strike,if=buff.dancing_rune_weapon.up|rune.time_to_4<gcd;
	if runes >= 1 and
		(buff[BL.DancingRuneWeapon].up or timeTo4Runes < gcd)
	then
		return BL.HeartStrike;
	end

	-- blood_boil,if=buff.dancing_rune_weapon.up;
	if buff[BL.DancingRuneWeapon].up then
		return BL.BloodBoil;
	end

	-- blood_tap,if=rune.time_to_3>gcd;
	if talents[BL.BloodTap] and
		cooldown[BL.BloodTap].charges >= 1 and
		timeTo3Runes > gcd
	then
		return BL.BloodTap;
	end

	-- death_and_decay,if=buff.crimson_scourge.up|talent.rapid_decomposition.enabled|spell_targets.death_and_decay>=2;
	if cooldown[BL.DeathAndDecay].ready and
		(runes >= 1 or  buff[BL.CrimsonScourge].up) and
		(
			buff[BL.CrimsonScourge].up or
				talents[BL.RapidDecomposition] or
				targets >= 2
		)
	then
		return BL.DeathAndDecay;
	end

	-- consumption;
	if talents[BL.Consumption] and
		cooldown[BL.Consumption].ready
	then
		return BL.Consumption;
	end

	-- blood_boil,if=charges_fractional>=1.1;
	if cooldown[BL.BloodBoil].charges >= 1.1 then
		return BL.BloodBoil;
	end

	-- heart_strike,if=(rune>1&(rune.time_to_3<gcd|buff.bone_shield.stack>7));
	if runes > 1 and
		(timeTo3Runes < gcd  or buff[BL.BoneShield].count > 7)
	then
		return BL.HeartStrike;
	end
end