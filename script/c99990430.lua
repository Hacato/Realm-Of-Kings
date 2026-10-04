--SAO Yuna - OS
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local SET_SAO_BOSS=0x1999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--Link Summon
	--2 "SAO" monsters, except Tuners
	----------------------------------------------------------
	Link.AddProcedure(c,s.linkmatfilter,2,2)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) Special Summon
	--Remove 1 En-Counter;
	--Special Summon 1 SAO monster from hand,
	--except an SAO Boss monster.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Targeting protection
	--SAO monsters this card points to cannot be
	--targeted by the opponent's card effects.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--LINK MATERIAL
--2 "SAO" monsters, except Tuners
----------------------------------------------------------
function s.linkmatfilter(c,lc,sumtype,tp)
	return c:IsSetCard(SET_SAO,lc,sumtype,tp)
		and not c:IsType(TYPE_TUNER,lc,sumtype,tp)
end

----------------------------------------------------------
--(1) SPECIAL SUMMON FROM HAND
----------------------------------------------------------

--Remove 1 En-Counter
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			1,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--SAO monster, except SAO Boss
----------------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SAO)
		and not c:IsSetCard(SET_SAO_BOSS)
		and c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

----------------------------------------------------------
--Check that a monster can actually be summoned
----------------------------------------------------------
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_HAND,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.Hint(
		HINT_OPSELECTED,
		1-tp,
		aux.Stringid(id,0)
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_HAND
	)
end

----------------------------------------------------------
--Special Summon the selected SAO monster
----------------------------------------------------------
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.spfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	if #g>0 then
		Duel.SpecialSummon(
			g,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

----------------------------------------------------------
--(2) TARGETING PROTECTION
----------------------------------------------------------

--Only your face-up SAO monsters that Yuna currently
--points to receive the targeting protection.
function s.tgtg(e,c)
	local hc=e:GetHandler()

	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and hc:GetLinkedGroup():IsContains(c)
end