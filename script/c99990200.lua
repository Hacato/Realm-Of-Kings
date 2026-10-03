--SAO Sinon - ALO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--Synchro Summon
	--1 Tuner + 1 non-Tuner "SAO" monster
	----------------------------------------------------------
	Synchro.AddProcedure(
		c,
		nil,1,1,
		Synchro.NonTuner(Card.IsSetCard,0x999),1,1
	)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) Target 1 other "SAO" monster you control;
	--shuffle it into the Deck, and if you do,
	--Special Summon 1 "SAO" monster from your hand,
	--except an "SAO Boss" monster.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tdtg)
	e1:SetOperation(s.tdop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) When opponent adds exactly 1 card from Deck to hand,
	--except by drawing it during their normal draw:
	--Remove 1 En-Counter;
	--banish that card face-down until their next Standby Phase.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.bancon)
	e2:SetCost(s.bancost)
	e2:SetTarget(s.bantg)
	e2:SetOperation(s.banop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999,0x1999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) SHUFFLE ANOTHER "SAO" INTO DECK
----------------------------------------------------------

function s.tdfilter(c)
	return c:IsFaceup()
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c:IsAbleToDeck()
end

----------------------------------------------------------
--"SAO" monster in hand,
--except an "SAO Boss" monster
----------------------------------------------------------

function s.spfilter(c,e,tp)
	return c:IsMonster()
		and c:IsSetCard(0x999)
		and not c:IsSetCard(0x1999)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false
		)
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()

	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and chkc~=c
			and s.tdfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.tdfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			c
		)
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
		HINT_SELECTMSG,
		tp,
		HINTMSG_TODECK
	)

	local g=Duel.SelectTarget(
		tp,
		s.tdfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		c
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		g,
		1,
		0,
		0
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

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e) then
		return
	end

	------------------------------------------------------
	--Shuffle the targeted monster into the Main Deck.
	------------------------------------------------------
	if Duel.SendtoDeck(
		tc,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)==0 then
		return
	end

	------------------------------------------------------
	--"and if you do"
	--It must actually reach the Deck.
	------------------------------------------------------
	if not tc:IsLocation(LOCATION_DECK) then
		return
	end

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
--(2) OPPONENT ADDS EXACTLY 1 CARD FROM DECK TO HAND
----------------------------------------------------------

function s.banfilter(c,tp)
	return c:IsControler(1-tp)
		and c:IsPreviousLocation(LOCATION_DECK)
		and not c:IsReason(REASON_RULE)
end

function s.bancon(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--Exactly one card must have been added to the hand
	--by this event.
	------------------------------------------------------
	if #eg~=1 then
		return false
	end

	local tc=eg:GetFirst()

	if not tc
		or not s.banfilter(tc,tp) then
		return false
	end

	------------------------------------------------------
	--Do not trigger for the opponent's normal draw
	--during their Draw Phase.
	------------------------------------------------------
	if Duel.GetTurnPlayer()==1-tp
		and Duel.GetCurrentPhase()==PHASE_DRAW
		and tc:IsReason(REASON_RULE) then
		return false
	end

	return true
end

----------------------------------------------------------
--REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.bancost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			0x1994,
			1,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		0x1994,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--THE EXACT CARD ADDED TO THE HAND
----------------------------------------------------------

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=eg:GetFirst()

	if chk==0 then
		return tc
			and tc:IsLocation(LOCATION_HAND)
			and tc:IsControler(1-tp)
			and tc:IsAbleToRemove()
	end

	------------------------------------------------------
	--Keep a reference to the exact card.
	------------------------------------------------------
	e:SetLabelObject(tc)
	tc:CreateEffectRelation(e)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		tc,
		1,
		1-tp,
		LOCATION_HAND
	)
end

----------------------------------------------------------
--BANISH IT FACE-DOWN TEMPORARILY
----------------------------------------------------------

function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsLocation(LOCATION_HAND)
		or not tc:IsControler(1-tp) then
		return
	end

	if Duel.Remove(
		tc,
		POS_FACEDOWN,
		REASON_EFFECT|REASON_TEMPORARY
	)==0 then
		return
	end

	------------------------------------------------------
	--Mark this exact temporarily banished card.
	------------------------------------------------------
	tc:RegisterFlagEffect(
		id,
		RESET_EVENT|RESETS_STANDARD,
		0,
		1
	)

	------------------------------------------------------
	--Return it during the opponent's NEXT Standby Phase.
	------------------------------------------------------
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetCountLimit(1)
	e1:SetLabelObject(tc)
	e1:SetCondition(s.retcon)
	e1:SetOperation(s.retop)
	e1:SetReset(RESET_PHASE|PHASE_STANDBY,2)
	Duel.RegisterEffect(e1,tp)
end

----------------------------------------------------------
--WAIT FOR OPPONENT'S STANDBY PHASE
----------------------------------------------------------

function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()

	if not tc
		or tc:GetFlagEffect(id)==0 then
		e:Reset()
		return false
	end

	return Duel.GetTurnPlayer()==1-tp
end

----------------------------------------------------------
--RETURN THE TEMPORARILY BANISHED CARD TO THE HAND
----------------------------------------------------------

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()

	if tc
		and tc:GetFlagEffect(id)>0
		and tc:IsLocation(LOCATION_REMOVED) then

		Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)
	end

	e:Reset()
end