local _, addonTable = ...;

--- @type MaxDps
if not MaxDps then return end

local DeathKnight = addonTable.DeathKnight;
local MaxDps = MaxDps;
local UnitPower = UnitPower;
local RunicPower = Enum.PowerType.RunicPower;
local Runes = Enum.PowerType.Runes;

local UH = {
	-- Debuffs
	FesteringWound     = 194310,
	VirulentPlague     = 191587,

	-- Talents
	ClawingShadows     = 207311,
	UnholyBlight       = 115989,
	HarbingerOfDoom    = 276023,  -- TODO: Modify rotation to handle two stacks of Sudden Doom
	SoulReaper         = 343294,
	Pestilence         = 277234,
	Defile             = 152280,
	SummonGargoyle     = 49206,
	UnholyAssault      = 207289,

	-- Core Death Knight abiliies
	DeathAndDecay      = 43265,
	DeathCoil          = 47541,

	-- Unholy Death Knight abilities
	Apocalypse         = 275699,
	ArmyOfTheDead      = 42650,
	DarkTransformation = 63560,
	Epidemic           = 207317,
	FesteringStrike    = 85948,
	Outbreak           = 77575,
	RaiseDead          = 46584,
	ScourgeStrike      = 55090,

	-- Procs
	SuddenDoom         = 81340,

	-- Shadowlands covenant abilities
	ShackleTheUnworthy = 312202,
	AbominationLimb    = 315443,
	SwarmingMist       = 311648,
	DeathsDue          = 324128,
};

function DeathKnight:Unholy()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local debuff = fd.debuff;
	local talents = fd.talents;
	local targets = MaxDps:SmartAoe();
	local gcd = fd.gcd;
	local buff = fd.buff;
	local runes = DeathKnight:Runes(fd.timeShift);
	local runicPower = UnitPower('player', RunicPower);
	local targetHpPercent = MaxDps:TargetPercentHealth() * 100;

	local covenantId = fd.covenant.covenantId;
	local Necrolord = Enum.CovenantType.Necrolord;
	local Venthyr = Enum.CovenantType.Venthyr;
	local NightFae = Enum.CovenantType.NightFae;
	local Kyrian = Enum.CovenantType.Kyrian;

	fd.targets = targets;
	fd.runes = runes;
	fd.runesDeficit = runesDeficit;
	fd.runicPower = runicPower;

	------------------------
	-- Replacement spells --
	------------------------
	local deathAndDecay = UH.DeathAndDecay;
	if covenantId == NightFae then 
		deathAndDecay = UH.DeathsDue; -- TODO: This is currently untested.  Make sure Death's Due and Defile play nice together
	elseif talents[UH.Defile] then 
		deathAndDecay = UH.Defile;
	end

	local scourgeStrike = UH.ScourgeStrike;
	if talents[UH.ClawingShadows] then
		scourgeStrike = UH.ClawingShadows;
	end
	
	--------------------
	-- Glow cooldowns --
	--------------------
	MaxDps:GlowCooldown(UH.ArmyOfTheDead, cooldown[UH.ArmyOfTheDead].ready);

	if talents[UH.SummonGargoyle] then
		MaxDps:GlowCooldown(UH.SummonGargoyle, cooldown[UH.SummonGargoyle].ready);
	end

	if talents[UH.UnholyAssault] then
		MaxDps:GlowCooldown(UH.UnholyAssault, cooldown[UH.UnholyAssault].ready and debuff[UH.FesteringWound].count <= 2);
	end
	
	-- This should technically be a standard part of the rotation, but gripping mobs isn't always the best idea, so use situationally
	if covenantId == Necrolord then
		MaxDps:GlowCooldown(UH.AbominationLimb, cooldown[UH.AbominationLimb].ready);
	end 
	
	--------------
	-- Rotation --
	--------------
	-- Maintain Virulent Plague
	if debuff[UH.VirulentPlague].remains <= gcd and runes >= 1 then
		if talents[UH.UnholyBlight] and cooldown[UH.UnholyBlight].ready then 
			return UH.UnholyBlight;
		else 
			return UH.Outbreak;
		end
	end

	-- Use covenant abilities off cooldown
	if covenantId == Kyrian and cooldown[UH.ShackleTheUnworthy].ready then
		return UH.ShackleTheUnworthy;
	end

	if covenantId == Venthyr and cooldown[UH.SwarmingMist].ready then
		return UH.SwarmingMist;
	end
	
	-- Use Dark Transformation off cooldown
	if cooldown[UH.DarkTransformation].ready then
		return UH.DarkTransformation;
	end

	-- Use Apocalypse off cooldown, and apply more Festering Wounds if necessary
	if cooldown[UH.Apocalypse].ready then
		if debuff[UH.FesteringWound].count >= 4 then
			return UH.Apocalypse;
		elseif fd.runes >= 2 then
			return UH.FesteringStrike;
		end 
	end

	-- Execute when runes are on cooldown
	if talents[UH.SoulReaper] and cooldown[UH.SoulReaper].ready and targetHpPercent < 35 and runes < 2 then
		return UH.SoulReaper;
	end

	-- Use Sudden Doom procs, and burn runic power when close to cap
	-- TODO: Harbinger Of Doom talent
	if buff[UH.SuddenDoom].up or fd.runicPower > 80 then
		if targets > 2 then
			return UH.Epidemic;
		else
			return UH.DeathCoil;
		end
	end

	-- Use Death and Decay in AoE situations, or off cooldown with the Pestilence talent
	if (targets >=3 or talents[UH.Pestilence]) and cooldown[deathAndDecay].ready and fd.runes >= 1 then
		return deathAndDecay;
	end
	
	-- Burst Festering Wounds if able and Apocalypse not ready (don't want to reduce count until after Apocalypse is cast)
	if debuff[UH.FesteringWound].count >= 1 and fd.runes >= 1 and not cooldown[UH.Apocalypse].ready then
		return scourgeStrike;
	end

	-- Apply Festering Wounds
	if debuff[UH.FesteringWound].count <= 3 and fd.runes >= 2 then
		return UH.FesteringStrike;
	end

	-- Dump runic power 
	if fd.runicPower >= 40 then
		if targets > 2 then
			return UH.Epidemic;
		else
			return UH.DeathCoil;
		end
	end
end
