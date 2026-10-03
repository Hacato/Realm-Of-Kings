--SAO Lisbeth - SAO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	--(1) If Normal or Special Summoned:
	--Place 1 EN-Counter on your "SAO" Field Spell
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	--(2) Set 1 "SAO" Spell/Trap directly from your Deck,
	--except a Field Spell
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

s.listed_series={0x999}
s.counter_place_list={0x1994}

----------------------------------------------------------
--(1) PLACE 1 EN-COUNTER
----------------------------------------------------------

function s.fieldfilter(c)
	return c:IsFaceup()
		and c:IsType(TYPE_FIELD)
		and c:IsSetCard(0x999)
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.fieldfilter,
			tp,
			LOCATION_FZONE,
			0,
			1,
			nil
		)
	end
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstMatchingCard(
		s.fieldfilter,
		tp,
		LOCATION_FZONE,
		0,
		nil
	)

	if tc then
		tc:AddCounter(0x1994,1)
	end
end

----------------------------------------------------------
--(2) SET 1 "SAO" SPELL/TRAP FROM DECK
----------------------------------------------------------

function s.setfilter(c)
	return c:IsSetCard(0x999)
		and c:IsSpellTrap()
		and not c:IsType(TYPE_FIELD)
		and c:IsSSetable()
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

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

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

	if Duel.SSet(tp,tc)>0 then
		Duel.ConfirmCards(1-tp,tc)
	end
end