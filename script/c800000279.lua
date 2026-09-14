--Resonant Rushdown
local s,id=GetID()

function s.initial_effect(c)
	--Add 1 Resonator support Spell, then optionally Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--Resonator Call / Resonator Command / Resonant Destruction
function s.thfilter(c)
	return c:IsCode(23008320,08559524,59593925)
		and c:IsAbleToHand()
end

--Level 3 or lower Fiend monster
function s.spfilter(c,e,tp)
	return c:IsRace(RACE_FIEND)
		and c:IsLevelBelow(3)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,LOCATION_DECK,0,1,nil
		)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK
	)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Add 1 of the listed cards
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	if #g==0 then return end

	if Duel.SendtoHand(g,nil,REASON_EFFECT)==0 then
		return
	end

	Duel.ConfirmCards(1-tp,g)

	--"and if you do"
	--Optionally Special Summon 1 Level 3 or lower Fiend from hand
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.spfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil,
		e,
		tp
	) then
		return
	end

	if Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

		local sg=Duel.SelectMatchingCard(
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

		if #sg>0 then
			Duel.SpecialSummon(
				sg,
				0,
				tp,
				tp,
				false,
				false,
				POS_FACEUP
			)
		end
	end
end