--Road of the King
local s,id=GetID()

local RED_DRAGON_ARCHFIEND=70902743

function s.initial_effect(c)
	--Track Quick-Play Spell activations
	aux.GlobalCheck(s,function()
		local ge=Effect.CreateEffect(c)
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_CHAINING)
		ge:SetOperation(s.qpcheck)
		Duel.RegisterEffect(ge,0)
	end)

	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--==================================================
-- Track Quick-Play Spell activations
--==================================================

function s.qpcheck(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()

	if re:IsActiveType(TYPE_SPELL)
		and rc:IsType(TYPE_QUICKPLAY) then
		Duel.RegisterFlagEffect(
			rp,
			id,
			RESET_PHASE+PHASE_END,
			0,
			1
		)
	end
end

--==================================================
-- Activation condition
-- Main Phase + no Quick-Play Spell activated
--==================================================

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()

	return (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
		and Duel.GetFlagEffect(tp,id)==0
end

--==================================================
-- Basic material
--==================================================

function s.matfilter(c)
	return c:IsMonster()
		and (c:IsRace(RACE_FIEND) or c:IsRace(RACE_ROCK))
		and c:IsAbleToRemoveAsCost()
end

--==================================================
-- Synchro checks
--==================================================

function s.getsynchrolevels(c,sc)
	local lv=c:GetSynchroLevel(sc)

	if lv<=0 then
		return {}
	end

	if lv>0xffff then
		return {
			lv&0xffff,
			(lv>>16)&0xffff
		}
	end

	return {lv}
end

function s.levelcheck(c1,c2,sc)
	local lv1=s.getsynchrolevels(c1,sc)
	local lv2=s.getsynchrolevels(c2,sc)

	for _,v1 in ipairs(lv1) do
		for _,v2 in ipairs(lv2) do
			if v1+v2==sc:GetLevel() then
				return true
			end
		end
	end

	return false
end

function s.synmatcheck(sc,g)
	if #g~=2 then
		return false
	end

	local c1=g:GetFirst()
	local c2=g:GetNext()

	if not c1 or not c2 then
		return false
	end

	--Must have exactly 1 Tuner and 1 non-Tuner
	if c1:IsType(TYPE_TUNER)==c2:IsType(TYPE_TUNER) then
		return false
	end

	--Check their Levels against the Synchro Monster
	return s.levelcheck(c1,c2,sc)
end

function s.synfilter(c,e,tp,g)
	return c:IsType(TYPE_SYNCHRO)
		and c:ListsCode(RED_DRAGON_ARCHFIEND)
		and s.synmatcheck(c,g)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_SYNCHRO,
			tp,
			false,
			false
		)
end

--==================================================
-- Fusion checks
--==================================================

function s.fusfilter(c,e,tp,g)
	return c:IsType(TYPE_FUSION)
		and (c:IsRace(RACE_ROCK) or c:IsRace(RACE_DRAGON))
		and c:CheckFusionMaterial(g,nil,tp,true)
		and c:IsCanBeSpecialSummoned(
			e,
			SUMMON_TYPE_FUSION,
			tp,
			false,
			false
		)
end

--==================================================
-- Does this exact pair produce a valid monster?
--==================================================

function s.hasoption(tp,e,g)
	local syn=Duel.IsExistingMatchingCard(
		s.synfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		nil,
		e,
		tp,
		g
	)

	local fus=Duel.IsExistingMatchingCard(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		nil,
		e,
		tp,
		g
	)

	return syn or fus
end

--==================================================
-- Field material validation
--==================================================

function s.fieldcheck(c,e,tp)
	if not s.matfilter(c) then
		return false
	end

	local gg=Duel.GetMatchingGroup(
		s.matfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil
	)

	for gc in aux.Next(gg) do
		local mg=Group.FromCards(c,gc)

		if s.hasoption(tp,e,mg) then
			return true
		end
	end

	return false
end

--==================================================
-- GY material validation
--==================================================

function s.gravecheck(c,e,tp,fc)
	if not s.matfilter(c) then
		return false
	end

	local mg=Group.FromCards(fc,c)

	return s.hasoption(tp,e,mg)
end

--==================================================
-- Cost
-- 1 from field + 1 from GY
--==================================================

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fieldcheck,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil,
			e,
			tp
		)
	end

	--Select field monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local fg=Duel.SelectMatchingCard(
		tp,
		s.fieldcheck,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	local fc=fg:GetFirst()
	if not fc then
		return
	end

	--Select compatible GY monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local gg=Duel.SelectMatchingCard(
		tp,
		s.gravecheck,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp,
		fc
	)

	local gc=gg:GetFirst()
	if not gc then
		return
	end

	local mg=Group.FromCards(fc,gc)

	--Remember exact pair
	mg:KeepAlive()
	e:SetLabelObject(mg)

	--Banish both as cost
	Duel.Remove(
		mg,
		POS_FACEUP,
		REASON_COST
	)
end

--==================================================
-- Target
--==================================================

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return true
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_EXTRA
	)
end

--==================================================
-- Synchro Summon
--==================================================

function s.dosynchro(e,tp,g)
	local sg=Duel.GetMatchingGroup(
		s.synfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		g
	)

	if #sg==0 then
		return false
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local tc=sg:Select(tp,1,1,nil):GetFirst()

	if not tc then
		return false
	end

	tc:SetMaterial(g)

	local res=Duel.SpecialSummon(
		tc,
		SUMMON_TYPE_SYNCHRO,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)

	if res>0 then
		tc:CompleteProcedure()
		return true
	end

	return false
end

--==================================================
-- Fusion Summon
--==================================================

function s.dofusion(e,tp,g)
	local fg=Duel.GetMatchingGroup(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		nil,
		e,
		tp,
		g
	)

	if #fg==0 then
		return false
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local tc=fg:Select(tp,1,1,nil):GetFirst()

	if not tc then
		return false
	end

	tc:SetMaterial(g)

	local res=Duel.SpecialSummon(
		tc,
		SUMMON_TYPE_FUSION,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)

	if res>0 then
		tc:CompleteProcedure()
		return true
	end

	return false
end

--==================================================
-- Resolution
--==================================================

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=e:GetLabelObject()

	if not g then
		return
	end

	local syn=Duel.IsExistingMatchingCard(
		s.synfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		nil,
		e,
		tp,
		g
	)

	local fus=Duel.IsExistingMatchingCard(
		s.fusfilter,
		tp,
		LOCATION_EXTRA,
		0,
		1,
		nil,
		e,
		tp,
		g
	)

	if not syn and not fus then
		g:DeleteGroup()
		return
	end

	--Synchro only
	if syn and not fus then
		s.dosynchro(e,tp,g)

	--Fusion only
	elseif fus and not syn then
		s.dofusion(e,tp,g)

	--Both are available
	else
		local op=Duel.SelectOption(
			tp,
			aux.Stringid(id,0),
			aux.Stringid(id,1),
			aux.Stringid(id,2)
		)

		if op==0 then
			--Synchro only
			s.dosynchro(e,tp,g)

		elseif op==1 then
			--Fusion only
			s.dofusion(e,tp,g)

		else
			--Both
			s.dosynchro(e,tp,g)

			if Duel.GetLocationCountFromEx(tp,tp,nil,nil)>0 then
				Duel.BreakEffect()
				s.dofusion(e,tp,g)
			end
		end
	end

	g:DeleteGroup()
end