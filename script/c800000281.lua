--Corona Resonator
local s,id=GetID()

function s.initial_effect(c)
	--Can be used as Synchro Material from the hand
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SYNCHRO_MAT_FROM_HAND)
	e1:SetRange(LOCATION_HAND)
	e1:SetValue(s.handmat)
	c:RegisterEffect(e1)

--Quick Effect: banish 1 DARK Fiend from GY; Special Summon this card
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,0))
e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
e2:SetType(EFFECT_TYPE_QUICK_O)
e2:SetCode(EVENT_FREE_CHAIN)
e2:SetRange(LOCATION_HAND)
e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
e2:SetCountLimit(1,id)
e2:SetCost(s.spcost)
e2:SetTarget(s.sptg)
e2:SetOperation(s.spop)
c:RegisterEffect(e2)

	--If Normal Summoned: lose 1 Level
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_UPDATE_LEVEL)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.nscon)
	e3:SetValue(-1)
	c:RegisterEffect(e3)

	--If Normal Summoned: gain 500 ATK
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetValue(500)
	c:RegisterEffect(e4)

	--If used as Synchro Material
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_BE_MATERIAL)
	e5:SetCondition(s.matcon)
	e5:SetOperation(s.matop)
	c:RegisterEffect(e5)
end

--==================================================
-- Use from hand as Synchro Material
--==================================================

function s.handmat(e,c,sc)
	return sc:IsAttribute(ATTRIBUTE_DARK)
		and sc:IsType(TYPE_SYNCHRO)
		and (sc:IsRace(RACE_DRAGON) or sc:IsRace(RACE_FIEND))
end

--==================================================
-- Quick Effect Special Summon
--==================================================

function s.costfilter(c)
	return c:IsAttribute(ATTRIBUTE_DARK)
		and c:IsRace(RACE_FIEND)
		and c:IsAbleToRemoveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,tp,LOCATION_GRAVE,0,1,nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(
		tp,s.costfilter,tp,LOCATION_GRAVE,0,1,1,nil
	)

	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(
			c,0,tp,tp,false,false,POS_FACEUP
		)
	end
end

--==================================================
-- Normal Summoned Corona Resonator
-- loses 1 Level and gains 500 ATK
--==================================================

function s.nscon(e)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_NORMAL)
		and c:GetLevel()>1
end

--==================================================
-- Synchro Monster summoned using this card
--==================================================

function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_SYNCHRO
end

function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sc=c:GetReasonCard()

	if not sc then return end
	if not sc:IsFaceup() then return end

	--Must be a DARK Dragon or Fiend Synchro Monster
	if not sc:IsAttribute(ATTRIBUTE_DARK)
		or not sc:IsType(TYPE_SYNCHRO)
		or not (sc:IsRace(RACE_DRAGON) or sc:IsRace(RACE_FIEND)) then
		return
	end

	--Lose 1 Level
	if sc:GetLevel()>1 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_LEVEL)
		e1:SetValue(-1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		sc:RegisterEffect(e1)
	end

	--Gain 500 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(500)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD)
	sc:RegisterEffect(e2)
end