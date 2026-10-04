--SAO Halloween Dungeon Party
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local SET_SAO_BOSS=0x1999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) Reveal 3 "SAO" monsters with different names,
	--randomly add 1 to hand.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.revtg)
	e1:SetOperation(s.revop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) GY effect
	--Except the turn this card was sent to the GY:
	--Banish it + remove 1 En-Counter;
	--add 1 non-Boss "SAO" monster from GY to hand.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO,SET_SAO_BOSS}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) REVEAL EFFECT
----------------------------------------------------------

function s.revfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
end

----------------------------------------------------------
--Need at least 3 differently named "SAO" monsters.
----------------------------------------------------------

function s.revtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(
		s.revfilter,
		tp,
		LOCATION_DECK,
		0,
		nil
	)

	if chk==0 then
		return g:GetClassCount(Card.GetCode)>=3
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

----------------------------------------------------------
--Reveal exactly 3 SAO monsters with different names.
----------------------------------------------------------

function s.revop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(
		s.revfilter,
		tp,
		LOCATION_DECK,
		0,
		nil
	)

	if g:GetClassCount(Card.GetCode)<3 then
		return
	end

	local rg=Group.CreateGroup()

	------------------------------------------------------
	--Select the first monster.
	------------------------------------------------------

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_CONFIRM
	)

	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()

	if not tc then
		return
	end

	rg:AddCard(tc)

	------------------------------------------------------
	--Remove all monsters with the same name from the
	--selection pool.
	------------------------------------------------------

	g:Remove(Card.IsCode,nil,tc:GetCode())

	------------------------------------------------------
	--Select the second monster.
	------------------------------------------------------

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_CONFIRM
	)

	sg=g:Select(tp,1,1,nil)
	tc=sg:GetFirst()

	if not tc then
		return
	end

	rg:AddCard(tc)
	g:Remove(Card.IsCode,nil,tc:GetCode())

	------------------------------------------------------
	--Select the third monster.
	------------------------------------------------------

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_CONFIRM
	)

	sg=g:Select(tp,1,1,nil)
	tc=sg:GetFirst()

	if not tc then
		return
	end

	rg:AddCard(tc)

	------------------------------------------------------
	--Reveal all 3 to the opponent.
	------------------------------------------------------

	Duel.ConfirmCards(
		1-tp,
		rg
	)

	------------------------------------------------------
	--Opponent RANDOMLY picks 1.
	--
	--Because the effect specifically says "randomly",
	--we do not use opponent Select() here.
	------------------------------------------------------

	local result=rg:RandomSelect(
		1-tp,
		1
	)

	local rc=result:GetFirst()

	if not rc then
		return
	end

	------------------------------------------------------
	--Add the randomly selected monster to your hand.
	------------------------------------------------------

	if Duel.SendtoHand(
		rc,
		nil,
		REASON_EFFECT
	)~=0 then
		Duel.ConfirmCards(
			1-tp,
			rc
		)
	end

	------------------------------------------------------
	--The other revealed cards remain in the Deck.
	--Shuffle the Deck afterward.
	------------------------------------------------------

	Duel.ShuffleDeck(tp)
end

----------------------------------------------------------
--(2) GY RECOVERY EFFECT
----------------------------------------------------------

----------------------------------------------------------
--Cannot activate during the turn this card was sent
--to the GY.
----------------------------------------------------------

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetTurnID()~=Duel.GetTurnCount()
end

----------------------------------------------------------
--COST:
--Banish this card + remove 1 En-Counter.
----------------------------------------------------------

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--Non-Boss SAO monster in your GY.
----------------------------------------------------------

function s.thfilter(c)
	return c:IsSetCard(SET_SAO)
		and not c:IsSetCard(SET_SAO_BOSS)
		and c:IsMonster()
		and c:IsAbleToHand()
end

----------------------------------------------------------
--Target
----------------------------------------------------------

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.thfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.thfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectTarget(
		tp,
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

----------------------------------------------------------
--Add targeted monster to hand.
----------------------------------------------------------

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
	then
		return
	end

	if Duel.SendtoHand(
		tc,
		nil,
		REASON_EFFECT
	)~=0 then
		Duel.ConfirmCards(
			1-tp,
			tc
		)
	end
end