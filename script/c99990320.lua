--SAO Bits of Sorrow
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local SET_SAO_BOSS=0x1999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) If an SAO monster you control is destroyed by
	--battle or an opponent's card effect:
	--Special Summon 1 non-Boss SAO from hand/Deck.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) GY effect
	--During your Main Phase, except the turn this card
	--was sent to the GY:
	--Banish this card + remove 1 En-Counter;
	--shuffle 3 SAO monsters from GY into Deck,
	--then draw 1 card.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.tdcon)
	e2:SetCost(s.tdcost)
	e2:SetTarget(s.tdtg)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO,SET_SAO_BOSS}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) SPECIAL SUMMON EFFECT
----------------------------------------------------------

----------------------------------------------------------
--Destroyed SAO monster:
-- • Was controlled by you
-- • Was in your Monster Zone
-- • Was destroyed by battle
--   OR by opponent's card effect
----------------------------------------------------------

function s.desfilter(c,tp)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:GetPreviousControler()==tp
		and (
			c:IsReason(REASON_BATTLE)
			or (
				c:IsReason(REASON_EFFECT)
				and c:GetReasonPlayer()==1-tp
			)
		)
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.desfilter,
		1,
		nil,
		tp
	)
end

----------------------------------------------------------
--Monster that can be Special Summoned.
--Must be SAO but NOT SAO Boss.
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
--TARGET / REMEMBER DESTROYED MONSTER'S ORIGINAL ATK
----------------------------------------------------------

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local dg=eg:Filter(
		s.desfilter,
		nil,
		tp
	)

	if chk==0 then
		return #dg>0
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,
				tp,
				LOCATION_HAND+LOCATION_DECK,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	------------------------------------------------------
	--If multiple SAO monsters were destroyed at once,
	--choose which destroyed monster supplies the
	--original ATK value.
	------------------------------------------------------

	local tc

	if #dg>1 then
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_FACEUP
		)

		tc=dg:Select(
			tp,
			1,
			1,
			nil
		):GetFirst()
	else
		tc=dg:GetFirst()
	end

	if tc then
		--------------------------------------------------
		--Remember half its original ATK.
		--------------------------------------------------
		e:SetLabel(
			math.floor(tc:GetBaseAttack()/2)
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		nil,
		1,
		tp,
		LOCATION_HAND+LOCATION_DECK
	)
end

----------------------------------------------------------
--SPECIAL SUMMON
----------------------------------------------------------

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	local g=Duel.GetMatchingGroup(
		s.spfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		nil,
		e,
		tp
	)

	if #g==0 then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local sg=g:Select(
		tp,
		1,
		1,
		nil
	)

	local tc=sg:GetFirst()

	if not tc then
		return
	end

	if Duel.SpecialSummon(
		tc,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP
	)==0 then
		return
	end

	local val=e:GetLabel()

	------------------------------------------------------
	--Gain ATK equal to half the original ATK
	--of the destroyed monster.
	------------------------------------------------------

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(val)
	e1:SetReset(
		RESET_EVENT+RESETS_STANDARD+
		RESET_PHASE+PHASE_END
	)
	tc:RegisterEffect(e1)

	------------------------------------------------------
	--Gain the same amount of DEF.
	------------------------------------------------------

	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	tc:RegisterEffect(e2)

	------------------------------------------------------
	--Cannot be destroyed by battle this turn.
	------------------------------------------------------

	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e3:SetValue(1)
	e3:SetReset(
		RESET_EVENT+RESETS_STANDARD+
		RESET_PHASE+PHASE_END
	)
	tc:RegisterEffect(e3)

	------------------------------------------------------
	--Cannot be destroyed by card effects this turn.
	------------------------------------------------------

	local e4=e3:Clone()
	e4:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	tc:RegisterEffect(e4)
end

----------------------------------------------------------
--(2) GY EFFECT
----------------------------------------------------------

----------------------------------------------------------
--Except the turn this card was sent to the GY.
----------------------------------------------------------

function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetTurnID()~=Duel.GetTurnCount()
end

----------------------------------------------------------
--COST:
--Banish this card and remove 1 En-Counter.
----------------------------------------------------------

function s.tdcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
			and Duel.IsCanRemoveCounter(
				tp,
				1,
				0,
				COUNTER_EN,
				1,
				REASON_COST
			)
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)

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
--Any SAO monster in your GY.
--Boss monsters ARE legal here because the effect
--does not exclude them.
----------------------------------------------------------

function s.tdfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:IsAbleToDeck()
end

----------------------------------------------------------
--Target exactly 3 SAO monsters.
----------------------------------------------------------

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.tdfilter(chkc)
	end

	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
			and Duel.IsExistingTarget(
				s.tdfilter,
				tp,
				LOCATION_GRAVE,
				0,
				3,
				nil
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
		LOCATION_GRAVE,
		0,
		3,
		3,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TODECK,
		g,
		3,
		tp,
		LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

----------------------------------------------------------
--Shuffle all 3 into the Deck, THEN draw 1.
----------------------------------------------------------

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_CARDS
	)

	if not g then
		return
	end

	------------------------------------------------------
	--All 3 targets must still be related to the effect.
	------------------------------------------------------

	local tg=g:Filter(
		Card.IsRelateToEffect,
		nil,
		e
	)

	if #tg~=3 then
		return
	end

	------------------------------------------------------
	--Return all 3.
	--Extra Deck monsters will naturally return to
	--the Extra Deck.
	------------------------------------------------------

	if Duel.SendtoDeck(
		tg,
		nil,
		SEQ_DECKSHUFFLE,
		REASON_EFFECT
	)~=3 then
		return
	end

	------------------------------------------------------
	--Verify that all three actually reached either
	--the Main Deck or Extra Deck.
	------------------------------------------------------

	local og=Duel.GetOperatedGroup()

	local ct=og:FilterCount(
		Card.IsLocation,
		nil,
		LOCATION_DECK+LOCATION_EXTRA
	)

	if ct~=3 then
		return
	end

	------------------------------------------------------
	--"then draw 1 card"
	------------------------------------------------------

	Duel.BreakEffect()

	Duel.Draw(
		tp,
		1,
		REASON_EFFECT
	)
end