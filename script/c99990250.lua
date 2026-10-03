--SAO Death Gun - GGO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--Xyz Summon
	--2 Level 4 "SAO" monsters
	----------------------------------------------------------
	Xyz.AddProcedure(
		c,
		aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SAO),
		4,2
	)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) During the turn this card was Xyz Summoned:
	--Remove 1 En-Counter, target 1 face-up card
	--opponent controls; destroy it, then send all cards
	--with that name from opponent's hand/Deck/Extra Deck
	--to the GY.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Quick Effect:
	--Detach 1 material, target 1 card in opponent's GY;
	--banish it, then add 1 "SAO" card of the same
	--Monster/Spell/Trap type from your GY to your hand.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCost(s.bancost)
	e2:SetTarget(s.bantg)
	e2:SetOperation(s.banop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) ONLY DURING THE TURN THIS CARD WAS XYZ SUMMONED
----------------------------------------------------------

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	return c:IsSummonType(SUMMON_TYPE_XYZ)
		and c:GetTurnID()==Duel.GetTurnCount()
end

----------------------------------------------------------
--REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--TARGET 1 FACE-UP CARD OPPONENT CONTROLS
----------------------------------------------------------

function s.desfilter(c)
	return c:IsFaceup()
		and c:IsDestructable()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_ONFIELD)
			and s.desfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.desfilter,
			tp,
			0,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DESTROY
	)

	local g=Duel.SelectTarget(
		tp,
		s.desfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DESTROY,
		g,
		1,
		0,
		0
	)
end

----------------------------------------------------------
--DESTROY IT, THEN SEND ALL CARDS WITH THAT NAME
--FROM OPPONENT'S HAND, DECK AND EXTRA DECK TO GY
----------------------------------------------------------

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e) then
		return
	end

	------------------------------------------------------
	--Remember the original card code before destruction.
	------------------------------------------------------
	local code=tc:GetCode()

	------------------------------------------------------
	--"destroy it, then..."
	--The second part only happens if destruction succeeds.
	------------------------------------------------------
	if Duel.Destroy(tc,REASON_EFFECT)==0 then
		return
	end

	------------------------------------------------------
	--Find every card with that name in opponent's:
	--Hand
	--Deck
	--Extra Deck
	------------------------------------------------------
	local g=Duel.GetMatchingGroup(
		Card.IsCode,
		tp,
		0,
		LOCATION_HAND|LOCATION_DECK|LOCATION_EXTRA,
		nil,
		code
	)

	if #g==0 then
		return
	end

	Duel.BreakEffect()

	Duel.SendtoGrave(
		g,
		REASON_EFFECT
	)
end

----------------------------------------------------------
--(2) DETACH 1 MATERIAL
----------------------------------------------------------

function s.bancost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:CheckRemoveOverlayCard(
			tp,
			1,
			REASON_COST
		)
	end

	c:RemoveOverlayCard(
		tp,
		1,
		1,
		REASON_COST
	)
end

----------------------------------------------------------
--DETERMINE WHETHER A CARD IS
--MONSTER / SPELL / TRAP
----------------------------------------------------------

function s.gettype(c)
	if c:IsType(TYPE_MONSTER) then
		return TYPE_MONSTER
	elseif c:IsType(TYPE_SPELL) then
		return TYPE_SPELL
	elseif c:IsType(TYPE_TRAP) then
		return TYPE_TRAP
	end

	return 0
end

----------------------------------------------------------
--"SAO" CARD IN YOUR GY OF THE SAME BASIC CARD TYPE
----------------------------------------------------------

function s.thfilter(c,ctype)
	return c:IsSetCard(SET_SAO)
		and c:IsType(ctype)
		and c:IsAbleToHand()
end

----------------------------------------------------------
--OPPONENT'S GY TARGET
--
--It must have a corresponding "SAO" Monster/Spell/Trap
--in your GY, otherwise resolving the "and if you do"
--recovery would be impossible from activation.
----------------------------------------------------------

function s.banfilter(c,tp)
	if not c:IsAbleToRemove() then
		return false
	end

	local ctype=s.gettype(c)

	if ctype==0 then
		return false
	end

	return Duel.IsExistingMatchingCard(
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil,
		ctype
	)
end

----------------------------------------------------------
--TARGET OPPONENT'S GY CARD
----------------------------------------------------------

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.banfilter(chkc,tp)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.banfilter,
			tp,
			0,
			LOCATION_GRAVE,
			1,
			nil,
			tp
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_REMOVE
	)

	local g=Duel.SelectTarget(
		tp,
		s.banfilter,
		tp,
		0,
		LOCATION_GRAVE,
		1,
		1,
		nil,
		tp
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_REMOVE,
		g,
		1,
		0,
		0
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_GRAVE
	)
end

----------------------------------------------------------
--BANISH TARGET, THEN RECOVER SAME-TYPE "SAO" CARD
----------------------------------------------------------

function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e) then
		return
	end

	------------------------------------------------------
	--Remember whether it was a Monster, Spell or Trap
	--before moving it.
	------------------------------------------------------
	local ctype=s.gettype(tc)

	if ctype==0 then
		return
	end

	------------------------------------------------------
	--Banish opponent's card.
	------------------------------------------------------
	if Duel.Remove(
		tc,
		POS_FACEUP,
		REASON_EFFECT
	)==0 then
		return
	end

	------------------------------------------------------
	--"and if you do"
	--Now select an SAO card of the same type.
	------------------------------------------------------
	if not Duel.IsExistingMatchingCard(
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		nil,
		ctype
	) then
		return
	end

	Duel.BreakEffect()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		ctype
	)

	if #g>0 then
		Duel.SendtoHand(
			g,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			g
		)
	end
end