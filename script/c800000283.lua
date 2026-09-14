--Aurora Resonator
local s,id=GetID()

function s.initial_effect(c)
	--Link Summon: 1 "Resonator" Tuner
	Link.AddProcedure(c,s.matfilter,1,1)
	c:EnableReviveLimit()

	--Cannot be used as Link Material
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	--If Link Summoned:
	--Immediately gain an additional Normal Summon
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.nscon)
	e2:SetOperation(s.nsop)
	c:RegisterEffect(e2)

	--GY: Banish this card; Set 1 listed Trap directly from Deck
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,id)
	e3:SetCost(s.setcost)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

--==================================================
-- Link Material
--==================================================

function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(SET_RESONATOR)
		and c:IsType(TYPE_TUNER)
end

--==================================================
-- Additional Normal Summon
--==================================================

function s.nscon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

function s.exsummonfilter(e,c)
	return c:IsRace(RACE_FIEND)
		and (c:IsLevel(2) or c:IsLevel(4) or c:IsLevel(6))
end

function s.nsop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Immediately grant 1 additional Normal Summon
	--for Level 2, 4, or 6 Fiend monsters
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e1:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e1:SetTarget(s.exsummonfilter)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

--==================================================
-- GY Set Effect
--==================================================

--King's Consonance
--King's Synchro
--Synchro Call
function s.setfilter(c)
	return c:IsCode(
		24590232,
		27503418,
		89974904
	)
		and c:IsSSetable()
end

function s.setcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(
				s.setfilter,
				tp,
				LOCATION_DECK,
				0,
				1,
				nil
			)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SET
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.setfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then
		return
	end

	Duel.SSet(tp,tc)
end