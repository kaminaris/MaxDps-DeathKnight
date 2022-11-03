local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local DeathKnight = addonTable.DeathKnight;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local UnitPowerMax = UnitPowerMax;
local UnitExists = UnitExists;
local RunicPower = Enum.PowerType.RunicPower;
local GetTotemInfo = GetTotemInfo;

local Necrolord = Enum.CovenantType.Necrolord;
local Venthyr = Enum.CovenantType.Venthyr;
local NightFae = Enum.CovenantType.NightFae;
local Kyrian = Enum.CovenantType.Kyrian;

local UH = {			
	Apocalypse 			 = 275699,	
	ArmyOfTheDamned      = 276837,				
	ArmyOfTheDead        = 42650,				
	BloodPlague 		 = 55078,		
	ClawingShadows 		 = 207311,		
	ControlUndead		 = 111673,		
	ConvocationOfTheDead = 124,				
	DarkTransformation 	 = 63560,			
	DeadliestCoilBonusId = 6952,							
	Defile 				 = 152280,
	Epidemic 			 = 207317,	
	FesteringStrike 	 = 85948,			
	FesteringWound 		 = 194310,		
	FrostFever 			 = 55095,	
	ImprovedDeathCoil	 = 377580,
	LeadByExample	 	 = 342156,		
	Outbreak 			 = 77575,	
	PhearomonesBonusId 	 = 6954,	
	--talented raise dead uses a different spell id
	RaiseDeadUnholy      = 46584,	
	RunicCorruption 	 = 51462,						
	ScourgeStrike 		 = 55090,		
	ShackleTheUnworthy 	 = 312202,			
	SuddenDoom 			 = 81340,	
	SummonGargoyle 		 = 49206,		
	SuperstrainBonusId 	 = 6953,			
	SwarmingMist 		 = 311648,		
	UnholyAssault 		 = 207289,		
	UnholyBlight 		 = 115989,		
	UnholyBlightDot 	 = 115994,	
	VileContagion		 = 390279,
	VirulentPlague 		 = 191587,		

};

setmetatable(UH, DeathKnight.spellMeta);

function DeathKnight:Unholy()
	local fd = MaxDps.FrameData;
	local gcd = fd.gcd;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = MaxDps:SmartAoe();
	local runes = DeathKnight:Runes(fd.timeShift);
	local runeforge = fd.runeforge;
	local deathKnightFwoundedTargets = DeathKnight:WoundedTargets();
	local deathKnightDisableAotd = DeathKnight.db.unholyArmyOfTheDeadAsCooldown;
	local petExists = UnitExists('pet');
	local controlUndeadAura = MaxDps:IntUnitAura('pet', UH.ControlUndead, 'PLAYER', fd.timeShift);
	local darkTransformationAura = MaxDps:IntUnitAura('pet', UH.DarkTransformation, nil, fd.timeShift);
	local covenantId = fd.covenant.covenantId
	local runicPower = UnitPower('player', RunicPower);
	local runicPowerMax = UnitPowerMax('player', RunicPower);
	local targetHpPercent = MaxDps:TargetPercentHealth() * 100;
	local timeTo4Runes = DeathKnight:TimeToRunes(4);
	local deathCoilRP = 40;

	if talents[UH.ClawingShadows] then
		UH.WoundSpender = UH.ClawingShadows;
	else
		UH.WoundSpender = UH.ScourgeStrike;
	end

	if talents[UH.Defile] then
		UH.AnyDnd = UH.Defile;
	elseif covenantId == NightFae then
		UH.AnyDnd = COMMON.DeathsDue;
	else
		UH.AnyDnd = COMMON.DeathAndDecay;
	end

	-- variable,name=pooling_runic_power,value=cooldown.summon_gargoyle.remains<5&talent.summon_gargoyle
	local poolingRunicPower = talents[UH.SummonGargoyle] and
		(cooldown[UH.SummonGargoyle].remains < 5) and
		not DeathKnight.db.unholySummonGargoyleAsCooldown;

	-- variable,name=pooling_runes,value=talent.soul_reaper&rune<2&target.time_to_pct_35<5&fight_remains>5
	-- TODO: Implement time-to-percent logic
	-- TODO: Implement fight-remains logic
	local poolingRunes = talents[COMMON.SoulReaper] and
		runes < 2 and
		targetHpPercent <= 35;

	-- variable,name=st_planning,value=active_enemies=1&(!raid_event.adds.exists|raid_event.adds.in>15);
	local stPlanning = targets <= 1;

	fd.targets = targets;
	fd.runes = runes;
	fd.runicPower = runicPower;
	fd.runicPowerMax = runicPowerMax;
	fd.targetHpPercent = targetHpPercent;
	fd.deathKnightFwoundedTargets = deathKnightFwoundedTargets;
	fd.deathKnightDisableAotd = deathKnightDisableAotd;
	fd.petExists = petExists;
	fd.controlUndeadAura = controlUndeadAura;
	fd.darkTransformationAura = darkTransformationAura;
	fd.poolingRunicPower = poolingRunicPower;
	fd.poolingRunes = poolingRunes;
	fd.stPlanning = stPlanning;
	fd.timeTo4Runes = timeTo4Runes;
	fd.deathCoilRP = deathCoilRP;

	DeathKnight:UnolyGlowCooldowns();
	
	if not fd.petExists then
		return UH.RaiseDeadUnholy;
	end
	
	--outbreak or unholy blight
	if fd.debuff[UH.VirulentPlague].refreshable and fd.runes > 0 then
		if fd.targets < 2 then
			return UH.Outbreak;
		end
		if fd.targets > 1 then
			if (not fd.talents[UH.UnholyBlight] or (fd.talents[UH.UnholyBlight] and not fd.cooldown[UH.UnholyBlight].ready)) then
				return UH.Outbreak;
			end
			if fd.talents[UH.UnholyBlight] and fd.cooldown[UH.UnholyBlight].ready then
				return UH.UnholyBlight;
			end
		end
	end

	-- call_action_list,name=covenants;
	local result = DeathKnight:UnholyCovenants();
	if result then
		return result;
	end

	if targets <= 1 then
		result = DeathKnight:UnholySingleTargetRotation();
		if result then
			return result;
		end
	end
	
	if targets > 1 then
		result = DeathKnight:UnholyMultiTargetRotation();
		if result then
			return result;
		end
	end
end

function DeathKnight:UnholySingleTargetRotation()
	local fd = MaxDps.FrameData;

	--soul reaper if health <= 35
	if fd.talents[COMMON.SoulReaper] and fd.targetHpPercent <= 35 and fd.cooldown[COMMON.SoulReaper].ready then
		return COMMON.SoulReaper;
	end
	
	--dark transformation whenever available
	if fd.petExists and not fd.controlUndeadAura.up and fd.cooldown[UH.DarkTransformation].ready then 
		return UH.DarkTransformation;
	end
	
	--apocalypse if 4 wounds and off cd
	if fd.cooldown[UH.Apocalypse].ready and fd.debuff[UH.FesteringWound].count >= 4	then
		return UH.Apocalypse;
	end
	
	--if runic power >= 80 or sudden doom or gargoyle up cast coil
	if fd.runicPower >= 80 or fd.buff[UH.SuddenDoom].up then
		return COMMON.DeathCoil;
	end
	--festering strike when 3 or below festering wounds
	if fd.runes > 1 and fd.debuff[UH.FesteringWound].count < 4 then
		return UH.FesteringStrike;
	end

	-- scourge strike or UH.WoundSpender when 4 or more wounds
	if fd.runes > 1 and fd.debuff[UH.FesteringWound].count > 3 then
		return UH.WoundSpender;
	end
	--filler
	return COMMON.DeathCoil;
end

function DeathKnight:UnholyMultiTargetRotation()
	local fd = MaxDps.FrameData;
	--dark transformation whenever available
	if fd.petExists and not fd.controlUndeadAura.up and fd.cooldown[UH.DarkTransformation].ready then 
		return UH.DarkTransformation;
	end
	
	--festering strike when 3 or below festering wounds
	if fd.runes > 1 and fd.debuff[UH.FesteringWound].count < 4 then
		return UH.FesteringStrike;
	end
	
	--vile contagion
	if fd.talents[UH.VileContagion] and fd.cooldown[UH.VileContagion].ready then
		return UH.VileContagion;
	end
	
	--apocalypse if 4 wounds and off cd
	if fd.cooldown[UH.Apocalypse].ready and fd.debuff[UH.FesteringWound].count >= 4	then
		return UH.Apocalypse;
	end

	--gargoyle
	if fd.talents[UH.SummonGargoyle] and fd.cooldown[UH.SummonGargoyle].ready then
		return UH.SummonGargoyle;
	end
	--if runic power >= 30 or sudden doom or gargoyle up cast epidemic
	if fd.runicPower >= 30 or fd.buff[UH.SuddenDoom].up then
		return UH.Epidemic;
	end
	
	--death and decay
	if not fd.buff[COMMON.DeathAndDecayBuff].up and fd.cooldown[UH.AnyDnd].ready then
		return UH.AnyDnd;
	end
	-- scourge strike or UH.WoundSpender when 4 or more wounds
	if fd.runes > 1 and fd.debuff[UH.FesteringWound].count > 0 then
		return UH.WoundSpender;
	end
	
	--festering strike when out of wounds
	if fd.runes > 1 and fd.debuff[UH.FesteringWound].count < 1 then
		return UH.FesteringStrike;
	end
end

function DeathKnight:UnolyGlowCooldowns()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local buff = fd.buff;
	local runes = fd.runes;
	local runicPowerDeficit = fd.runicPowerDeficit;
	local targets = fd.targets;
	local covenant = fd.covenant;
	local covenantId = fd.covenant.covenantId;
	local stPlanning = fd.stPlanning;
	local timeTo4Runes = fd.timeTo4Runes;
	local ghoulActive = fd.petExists;
	local controlUndeadAura = fd.controlUndeadAura;
	local runicPower = fd.runicPower;
	local darkTransformationAura = fd.darkTransformationAura;

	local armyOfTheDeadReady = DeathKnight.db.unholyArmyOfTheDeadAsCooldown and
		cooldown[UH.ArmyOfTheDead].ready and
		runes >= 1;

	local summonGargoyleReady = DeathKnight.db.unholySummonGargoyleAsCooldown and
		talents[UH.SummonGargoyle] and
		cooldown[UH.SummonGargoyle].ready;

	local abominationLimbReady = DeathKnight.db.abominationLimbAsCooldown and
		covenantId == Necrolord and
		cooldown[COMMON.AbominationLimb].ready;
		
	local abominationLimbTalentReady = DeathKnight.db.abominationLimbAsCooldown and
		covenantId == Necrolord and
		cooldown[COMMON.AbominationLimbTalent].ready;

	local sacrificialPactReady = DeathKnight.db.unholySacrificialPactAsCooldown and
		cooldown[COMMON.SacrificialPact].ready and
		runicPower >= 20 and
		ghoulActive and
		not controlUndeadAura.up;
		
	local empowerRuneweaponReady = talents[COMMON.EmpowerRuneWeapon] and cooldown[COMMON.EmpowerRuneWeapon].ready;

	if DeathKnight.db.alwaysGlowCooldowns then
		MaxDps:GlowCooldown(UH.ArmyOfTheDead, armyOfTheDeadReady);
		MaxDps:GlowCooldown(UH.SummonGargoyle, summonGargoyleReady);
		MaxDps:GlowCooldown(COMMON.AbominationLimb, abominationLimbReady);
		MaxDps:GlowCooldown(COMMON.AbominationLimbTalent, abominationLimbTalentReady);
		MaxDps:GlowCooldown(COMMON.SacrificialPact, sacrificialPactReady);
		MaxDps:GlowCooldown(COMMON.EmpowerRuneWeapon, empowerRuneweaponReady);
	else
		-- Gather up all of the triggers from the main rotation.
		local armyOfTheDeadCooldownTrigger =
		armyOfTheDeadReady and
			runes >= 1 and
			(
				(
					(
						talents[UH.UnholyBlight] and
						cooldown[UH.UnholyBlight].remains < 3 and
						cooldown[UH.DarkTransformation].remains < 3 and
						not covenant.soulbindAbilities[UH.LeadByExample]
					) or
					not talents[UH.UnholyBlight]
				) or
				(
					talents[UH.UnholyBlight] and
					cooldown[UH.UnholyBlight].remains < 3 and
					covenantId == Necrolord and
					(cooldown[COMMON.AbominationLimb].ready or DeathKnight.db.abominationLimbAsCooldown) and
					covenant.soulbindAbilities[UH.LeadByExample]
				)
			);

		local summonGargoyleCooldownTrigger =
			summonGargoyleReady and
			talents[UH.UnholyBlight] and
			runicPowerDeficit < 14 and
			(cooldown[UH.UnholyBlight].remains < 10 or debuff[UH.UnholyBlightDot].remains);

		local abominationLimbCooldownTrigger =
		abominationLimbReady and
			(
				(
					stPlanning and
					not covenant.soulbindAbilities[UH.LeadByExample] and
					not cooldown[UH.Apocalypse].ready and
					timeTo4Runes > ( 3 + buff[UH.RunicCorruption].remains )
				) or
				(
					stPlanning and
					covenant.soulbindAbilities[UH.LeadByExample] and
					(
						(talents[UH.UnholyBlight] and not cooldown[UH.UnholyBlight].ready) or
							(not talents[UH.UnholyBlight] and not cooldown[UH.DarkTransformation].ready )
					)
				) or
				(
					targets >= 2 and
					timeTo4Runes > ( 3 + buff[UH.RunicCorruption].remains )
				)
			);

			local sacrificialPactTrigger =
				sacrificialPactReady and
				cooldown[UH.RaiseDeadUnholy].ready and
				not darkTransformationAura.up and
				not cooldown[UH.DarkTransformation].ready and
				targets >= 2;

		MaxDps:GlowCooldown(UH.ArmyOfTheDead, armyOfTheDeadCooldownTrigger);
		MaxDps:GlowCooldown(UH.SummonGargoyle, summonGargoyleCooldownTrigger);
		MaxDps:GlowCooldown(COMMON.AbominationLimb, abominationLimbCooldownTrigger);
		MaxDps:GlowCooldown(COMMON.SacrificialPact, sacrificialPactTrigger);
		MaxDps:GlowCooldown(COMMON.EmpowerRuneWeapon, empowerRuneweaponReady);
	end
end

function DeathKnight:UnholyCovenants()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = fd.targets;
	local runicPower = fd.runicPower;
	local runicPowerMax = fd.runicPowerMax;
	local runicPowerDeficit = runicPowerMax - runicPower;
	local runes = fd.runes;
	local stPlanning = fd.stPlanning
	local covenant = fd.covenant;
	local covenantId = fd.covenant.covenantId
	local timeTo4Runes = fd.timeTo4Runes;

	-- swarming_mist,if=variable.st_planning&runic_power.deficit>16|fight_remains<11;
	if covenantId == Venthyr and
		cooldown[UH.SwarmingMist].ready and
		runes >= 1 and
		stPlanning and
		runicPowerDeficit > 16
	then
		return UH.SwarmingMist;
	end

	-- swarming_mist,if=cooldown.apocalypse.remains&(active_enemies>=2&active_enemies<=5&runic_power.deficit>10+(active_enemies*6)|active_enemies>5&runic_power.deficit>40);
	if covenantId == Venthyr and
		cooldown[UH.SwarmingMist].ready and
		runes >= 1 and
		not cooldown[UH.Apocalypse].ready and
		(
			(targets >= 2 and targets <= 5 and runicPowerDeficit > 10 + ( targets * 6 )) or
				(targets > 5 and runicPowerDeficit > 40 )
		)
	then
		return UH.SwarmingMist;
	end

	-- abomination_limb,if=variable.st_planning&!soulbind.lead_by_example&cooldown.apocalypse.remains&rune.time_to_4>(3+buff.runic_corruption.remains)|fight_remains<21;
	if covenantId == Necrolord and
		cooldown[COMMON.AbominationLimb].ready and
		not DeathKnight.db.abominationLimbAsCooldown and
		stPlanning and
		not covenant.soulbindAbilities[UH.LeadByExample] and
		not cooldown[UH.Apocalypse].ready and
		timeTo4Runes > ( 3 + buff[UH.RunicCorruption].remains )
	then
		return COMMON.AbominationLimb;
	end

	-- abomination_limb,if=variable.st_planning&soulbind.lead_by_example&(dot.unholy_blight_dot.remains>11|!talent.unholy_blight&cooldown.dark_transformation.remains)
	if covenantId == Necrolord and
		cooldown[COMMON.AbominationLimb].ready and
		not DeathKnight.db.abominationLimbAsCooldown and
		stPlanning and
		covenant.soulbindAbilities[UH.LeadByExample] and
		(
			(talents[UH.UnholyBlight] and debuff[UH.UnholyBlightDot].remains > 11) or
			(not talents[UH.UnholyBlight] and not cooldown[UH.DarkTransformation].ready)
		)
	then
		return COMMON.AbominationLimb;
	end

	-- abomination_limb,if=active_enemies>=2&rune.time_to_4>(3+buff.runic_corruption.remains);
	if covenantId == Necrolord and
		cooldown[COMMON.AbominationLimb].ready and
		not DeathKnight.db.abominationLimbAsCooldown and
		targets >= 2 and
		timeTo4Runes > (3 + buff[UH.RunicCorruption].remains)
	then
		return COMMON.AbominationLimb;
	end

	-- shackle_the_unworthy,if=variable.st_planning&cooldown.apocalypse.remains|fight_remains<15;
	if covenantId == Kyrian and
		cooldown[UH.ShackleTheUnworthy].ready and
		stPlanning and
		not cooldown[UH.Apocalypse].ready
	then
		return UH.ShackleTheUnworthy;
	end

	-- shackle_the_unworthy,if=active_enemies>=2&(death_and_decay.ticking|raid_event.adds.remains<=14);
	if covenantId == Kyrian and
		cooldown[UH.ShackleTheUnworthy].ready and
		targets >= 2 and
		debuff[COMMON.DeathAndDecay].up
	then
		return UH.ShackleTheUnworthy;
	end
end

function DeathKnight:WoundedTargets()
	local fd = MaxDps.FrameData;
	local _, units = MaxDps:ThreatCounter();
	local count = 0;

	for i = 1, #units do
		local festeringWound = MaxDps:IntUnitAura(tostring(units[i]), UH.FesteringWound, 'PLAYER', fd.timeShift)
		if festeringWound.remains > fd.gcd then
			count = count + 1;
		end
	end
	return count;
end