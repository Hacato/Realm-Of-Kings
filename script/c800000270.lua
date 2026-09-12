--Sillva, War Overlord of Dark World
local s,id=GetID()

function s.initial_effect(c)
	--Fusion procedure
	c:EnableReviveLimit()
	Fusion.AddProcMix(
		c,true,true,
		s.dwmat,
		aux.FilterBoolFunctionEx(Card.IsRace,RACE_FIEND)
	)

	--If Fusion Summoned: return 1 card to the hand,
	--then you can discard 1 card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_HANDES)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.bcon)
	e1:SetTarget(s.btg)
	e1:SetOperation(s.bop)
	c:RegisterEffect(e1)

	--If this Fusion Summoned card is sent from the field
	--to the GY by your opponent
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_HANDES+CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.rmcon)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Fusion Materials
-- 1 Level 5 or 6 "Dark World" monster
-- + 1 Fiend monster
--==================================================

function s.dwmat(c,fc,sumtype,tp)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsMonster()
		and (c:IsLevel(5) or c:IsLevel(6))
end

--==================================================
-- Effect 1
-- If Fusion Summoned:
-- Return 1 card to hand,
-- then you can discard 1 card
--==================================================

function s.bcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

function s.bfilter(c)
	return c:IsAbleToHand()
end

function s.disfilter(c)
	return c:IsDiscardable()
end

function s.btg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsOnField()
			and s.bfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.bfilter,
			tp,
			LOCATION_ONFIELD,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)

	local g=Duel.SelectTarget(
		tp,
		s.bfilter,
		tp,
		LOCATION_ONFIELD,
		LOCATION_ONFIELD,
		1,1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		g,
		1,
		0,
		0
	)
end

function s.bop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsAbleToHand() then
		return
	end

	--The card must successfully return to the hand
	--before the "then" portion can occur
	if Duel.SendtoHand(tc,nil,REASON_EFFECT)==0 then
		return
	end

	--Then you can discard 1 card
	if Duel.IsExistingMatchingCard(
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil
	)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2))
	then
		Duel.BreakEffect()

		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_DISCARD
		)

		local g=Duel.SelectMatchingCard(
			tp,
			s.disfilter,
			tp,
			LOCATION_HAND,
			0,
			1,1,
			nil
		)

		if #g>0 then
			--Discard by card effect
			Duel.SendtoGrave(
				g,
				REASON_EFFECT|REASON_DISCARD
			)
		end
	end
end

--==================================================
-- Effect 2
-- If this Fusion Summoned card is sent
-- from field to GY by your opponent
--==================================================

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsSummonType(SUMMON_TYPE_FUSION)
		and c:GetReasonPlayer()==1-tp
end

--Cards opponent controls that can be banished face-down
function s.rmfilter(c)
	return not c:IsType(TYPE_TOKEN)
		and c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.disfilter,
			tp,
			LOCATION_HAND,
			0,
			1,
			nil
		)
	end
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)

	--Need at least 1 card available to discard
	local hg=Duel.GetMatchingGroup(
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		nil
	)

	if #hg==0 then
		return
	end

	--Discard 1 or 2 cards
	local maxct=math.min(2,#hg)

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local dg=Duel.SelectMatchingCard(
		tp,
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		maxct,
		nil
	)

	if #dg==0 then
		return
	end

	local ct=Duel.SendtoGrave(
		dg,
		REASON_EFFECT|REASON_DISCARD
	)

	if ct==0 then
		return
	end

	--"then your opponent banishes cards they control,
	--face-down, up to the number discarded"
	local rg=Duel.GetMatchingGroup(
		s.rmfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		nil
	)

	if #rg==0 then
		return
	end

	Duel.BreakEffect()

	local maxremove=math.min(ct,#rg)

	--Opponent chooses their own cards
	Duel.Hint(
		HINT_SELECTMSG,
		1-tp,
		HINTMSG_REMOVE
	)

	local sg=rg:Select(
		1-tp,
		0,
		maxremove,
		nil
	)

	if #sg>0 then
		Duel.Remove(
			sg,
			POS_FACEDOWN,
			REASON_EFFECT
		)
	end
end