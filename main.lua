local _Marrowrend = 195182;
local _BoneShield = 195181;
local _BloodBoil = 50842;
local _BloodPlague = 195740;
local _DeathandDecay = 43265;
local _CrimsonScourge = 81136;
local _RapidDecomposition = 194662;
local _DeathStrike = 49998;
local _HeartStrike = 206930;
local _Ossuary = 219786;
local _Consumption = 205223;
local _DarkCommand = 56222;
local _DeathGrip = 49576;
local _AntiMagicShell = 48707;
local _DancingRuneWeapon = 49028;
local _MouthofHell = 192570;
local _VampiricBlood = 55233;
local _IceboundFortitude = 48792;
local _AntiMagicBarrier = 205727;
local _RedThirst = 205723;
local _WebofPain = 215288;
local _MasteryBloodShield = 77513;
local _BloodDrinker = 206931;

-- Frost
local _IcyTalons = 194878;
local _RunicAttenuation = 207104;
local _Avalanche = 207142;
local _Obliteration = 207256;
local _FrostStrike = 49143;
local _FrostFever = 55095;
local _HowlingBlast = 49184;
local _Rime = 59057;
local _Obliterate = 49020;
local _KillingMachine = 51128;
local _RemorselessWinter = 196770;
local _FrozenPulse = 194909;
local _Frostscythe = 207230;
local _GlacialAdvance = 194913;
local _RunicEmpowerment = 81229;
local _PillarofFrost = 51271;
local _EmpowerRuneWeapon = 47568;
local _SindragosasFury = 190778;
local _MasteryFrozenHeart = 77514;
local _AntiMagicShell = 48707;
local _VolatileShielding = 207188;
local _BreathofSindragosa = 152279;
local _CrystallineSwords = 189186;

-- Unholy
local _SoulReaper = 130736;
local _VirulentPlague = 191587;
local _Outbreak = 77575;
local _DarkTransformation = 63560;
local _FesteringStrike = 85948;
local _FesteringWound = 197147;
local _Castigator = 207305;
local _Apocalypse = 220143;
local _ScourgeStrike = 55090;
local _ClawingShadows = 207311;
local _DeathCoil = 47541;
local _ShadowInfusion = 198943;
local _ScourgeofWorlds = 191747;
local _DeathandDecay = 43265;
local _Defile = 152280;
local _Epidemic = 207317;
local _ArmyoftheDead = 42650;
local _PortaltotheUnderworld = 191637;
local _ArmiesoftheDamned = 191731;
local _SummonGargoyle = 49206;
local _Heroism = 32182;
local _Bloodlust = 2825;
local _TimeWarp = 80353;
local _DarkArbiter = 207349;
local _AntiMagicShell = 48707;
local _SpellEater = 207321;
local _Necrosis = 207346;
local _EbonFever = 207269;
local _ArcaneTorrent = 28730;
local _SuddenDoom = 49530;
local _DeathStrike = 49998;

MaxDps.DeathKnight = {};

function MaxDps.DeathKnight.CheckTalents()
end

function MaxDps:EnableRotationModule(mode)
	mode = mode or 1;
	MaxDps.Description = 'Death Knight Module [Blood]';
	MaxDps.ModuleOnEnable = MaxDps.DeathKnight.CheckTalents;
	if mode == 1 then
		MaxDps.NextSpell = MaxDps.DeathKnight.Blood;
	end;
	if mode == 2 then
		MaxDps.NextSpell = MaxDps.DeathKnight.Frost;
	end;
	if mode == 3 then
		MaxDps.NextSpell = MaxDps.DeathKnight.Unholy;
	end;
end

function MaxDps.DeathKnight.Blood(_, timeShift, currentSpell, gcd, talents)

	local runic = UnitPower('player', SPELL_POWER_RUNIC_POWER);
	local runicMax = UnitPowerMax('player', SPELL_POWER_RUNIC_POWER);
	local runes, runeCd = MaxDps.DeathKnight.Runes();

	local bb, bbCharges = MaxDps:SpellCharges(_BloodBoil, timeShift);
	local dad, dadCharges = MaxDps:SpellAvailable(_DeathandDecay, timeShift);
	local cons = MaxDps:SpellAvailable(_Consumption, timeShift);

	local bs, bsCharges = MaxDps:Aura(_BoneShield, timeShift + 6);
	local bp = MaxDps:TargetAura(_BloodPlague, timeShift);

	if bsCharges <= 6 and runes >= 2 then
		return _Marrowrend;
	end

	if MaxDps:Aura(_CrimsonScourge, timeShift) then
		return _DeathandDecay;
	end

	if dad and runes >= 2 then
		return _DeathandDecay;
	end

	if talents[_BloodDrinker] and MaxDps:SpellAvailable(_BloodDrinker, timeShift) then
		return _BloodDrinker;
	end

	if runicMax - runic <= 20 then
		return _DeathStrike;
	end

	if not bp and bbCharges >= 2 then
		return _BloodBoil;
	end

	if dad and runes >= 2 then
		return _DeathandDecay;
	end

	if cons then
		return _Consumption;
	end

	if not bp and bbCharges >= 1 then
		return _BloodBoil;
	end

	if runes > 2 then
		return _HeartStrike;
	end

	-- comment this out if survival is a problem
	if runic >= 60 then
		return _DeathStrike;
	end
	-- comment out the above if survival is a problem

	if bbCharges >= 1 then
		return _BloodBoil;
	else
		return nil;
	end
end

function MaxDps.DeathKnight.Unholy(_, timeShift, currentSpell, gcd, talents)
	--Get runic power and runes
	local runic = UnitPower('player', SPELL_POWER_RUNIC_POWER);
	local runicMax = UnitPowerMax('player',SPELL_POWER_RUNIC_POWER);

	local runes, runeCd = MaxDps.DeathKnight.Runes();

	--Get wounds on target.
	local festering, festeringCd, festeringCharges = MaxDps:TargetAura(_FesteringWound, timeShift);

	local scourgeStrike = _ScourgeStrike;
	if talents[207311] then
		scourgeStrike = 207311;
	end

	local deathanddecay = (talents[_Defile] and _Defile) or _DeathandDecay;
	local summongargoyle = (talents[_DarkArbiter] and _DarkArbiter) or _SummonGargoyle;

	MaxDps:GlowCooldown(_ArmyoftheDead, MaxDps:SpellAvailable(_ArmyoftheDead , timeShift) and runes >= 3);
	MaxDps:GlowCooldown(summongargoyle, MaxDps:SpellAvailable(summongargoyle , timeShift));

	--Check if Necrosis is active
	if MaxDps:Aura(_Necrosis, timeShift) then
		-- If more then 2 wounds
		if festeringCharges > 2 then
			return  scourgeStrike;
		end
	end

	--Check if Plague is on
	if not MaxDps:TargetAura(_VirulentPlague, timeShift) then
		return _Outbreak;
	end

	--Dark transformation ready
	if MaxDps:SpellAvailable(_DarkTransformation , timeShift) then
		return _DarkTransformation ;
	end

	-- If less then 3 charges use festering wound
	if festeringCharges < 4 then
		if runes >=2 then
			return _FesteringStrike;
		end
	end

	--Check for use of apocalypse and soulreaper.
	if MaxDps:SpellAvailable(_Apocalypse , timeShift) then
		if talents[_SoulReaper] and MaxDps:SpellAvailable(_SoulReaper, timeShift) then
			if festeringCharges >= 3 then
				return _SoulReaper;
			end
		end
		if festeringCharges <=4 then
			if runes >= 2 then
				return _FesteringStrike;
			end
		end
		if festeringCharges >= 6 then
			return _Apocalypse;
		end
	end

	if talents[_SoulReaper] and MaxDps:SpellAvailable(_SoulReaper, timeShift) then
		if festeringCharges >= 3 then
			return _SoulReaper;
		end
	end

	--Check to run other and stuff
	if runes <= 2 then
		if MaxDps:SpellAvailable(deathanddecay , timeShift) then
			return deathanddecay;
		end
		if MaxDps:SpellAvailable(_DeathStrike , timeShift) then
			if runic > 85 then
				return _DeathStrike;
			end
		end
	end

	--Check power and run DeathCoil
	if runic > 50 then
		return _DeathCoil;
	end

	return _FesteringStrike;
end

function MaxDps.DeathKnight.Frost(_, timeShift, currentSpell, gcd, talents)

	local runic = UnitPower('player', SPELL_POWER_RUNIC_POWER);
	local runicMax = UnitPowerMax('player', SPELL_POWER_RUNIC_POWER);
	local runes, runeCd = MaxDps.DeathKnight.Runes();

	local it, itCharges = MaxDps:Aura(_IcyTalons, timeShift + 2);
	local oblit = MaxDps:Aura(_Obliteration, timeShift);
	local km = MaxDps:Aura(_KillingMachine, timeShift);
	local FSCost = 25;

	MaxDps:GlowCooldown(_Obliteration, talents[_Obliteration] and MaxDps:SpellAvailable(_Obliteration, timeShift) and runes <= 1);
	MaxDps:GlowCooldown(_BreathofSindragosa, talents[_BreathofSindragosa] and MaxDps:SpellAvailable(_BreathofSindragosa, timeShift));

	MaxDps:GlowCooldown(_SindragosasFury, MaxDps:SpellAvailable(_SindragosasFury, timeShift));
	MaxDps:GlowCooldown(_PillarofFrost, MaxDps:SpellAvailable(_PillarofFrost, timeShift));
	MaxDps:GlowCooldown(_EmpowerRuneWeapon, MaxDps:SpellAvailable(_EmpowerRuneWeapon, timeShift) and runes <= 1 and runic <= (runicMax - FSCost));

	if not MaxDps:TargetAura(_FrostFever, timeShift + 2) and runes > 0 then
		return _HowlingBlast;
	end

	if runic > (runicMax - FSCost) then
		return _FrostStrike;
	end

	if oblit then
		if km and runes >= 1 then
			return _Obliterate;
		elseif runic >= FSCost then
			return _FrostStrike;
		end
	end

	--RW before Rime/Oblit casts for best use of Gathering Storm
	if MaxDps:SpellAvailable(_RemorselessWinter, timeShift) and runes >= 1 then
		return _RemorselessWinter;
	end

	if MaxDps:Aura(_Rime, timeShift) then
		return _HowlingBlast;
	end

	if km and runes >= 1 then
		return _Obliterate;
	end

	if runes >= 2 then
		return _Obliterate;
	end

	if runic >= FSCost then
		return _FrostStrike;
	else
		return nil;
	end
end

function MaxDps.DeathKnight.Runes()
	local count = 0;
	local cd = 0;
	local time = GetTime();
	for i = 1, 10 do
		local start, duration, runeReady = GetRuneCooldown(i);
		if start and start > 0 then
			local rcd = duration + start - time;
			if cd == 0 or cd > rcd then
				cd = rcd;
			end
		end

		if runeReady then
			count = count + 1;
		end
	end

	return count, cd;
end