--SAO Pitohui - GGO
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
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SAO),4,2)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) Quick Effect:
	--Detach 1 material, then target 1 SAO Spell/Trap
	--in your GY; banish it, then add another copy
	--from the Deck.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.bancost)
	e1:SetTarget(s.bantg)
	e1:SetOperation(s.banop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Remove 2 En-Counters;
	--target another SAO Xyz Monster.
	--Add all of its materials to the hand,
	--then equip that monster to Pitohui.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(s.eqcost)
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) BANISH SAO SPELL/TRAP + SEARCH SAME NAME
----------------------------------------------------------

function s.bancost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:CheckRemoveOverlayCard(tp,1,REASON_COST)
	end

	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

----------------------------------------------------------
--Check Deck for another card with the same original code.
----------------------------------------------------------

function s.copyfilter(c,code)
	return c:IsCode(code)
		and c:IsAbleToHand()
end

----------------------------------------------------------
--SAO Spell/Trap in GY.
--
--It must have another copy in the Deck, otherwise
--"banish it, and if you do, add..." cannot successfully
--perform the search.
----------------------------------------------------------

function s.banfilter(c,tp)
	return c:IsSetCard(SET_SAO)
		and c:IsSpellTrap()
		and c:IsAbleToRemove()
		and Duel.IsExistingMatchingCard(
			s.copyfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil,
			c:GetCode()
		)
end

function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.banfilter(chkc,tp)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.banfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil,
			tp
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectTarget(
		tp,
		s.banfilter,
		tp,
		LOCATION_GRAVE,
		0,
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
		tp,
		LOCATION_GRAVE
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.banop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
	then
		return
	end

	------------------------------------------------------
	--Save the name/code before banishing it.
	------------------------------------------------------
	local code=tc:GetCode()

	if Duel.Remove(
		tc,
		POS_FACEUP,
		REASON_EFFECT
	)==0 then
		return
	end

	------------------------------------------------------
	--"and if you do"
	--The target must actually have been banished.
	------------------------------------------------------
	if not tc:IsLocation(LOCATION_REMOVED) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.copyfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil,
		code
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

----------------------------------------------------------
--(2) REMOVE 2 EN-COUNTERS
----------------------------------------------------------

function s.eqcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			2,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		2,
		REASON_COST
	)
end

----------------------------------------------------------
--Another SAO Xyz Monster you control.
--
--It must have at least 1 Xyz Material because the effect
--must add its material(s) to the hand before equipping it.
----------------------------------------------------------

function s.eqfilter(c,handler)
	return c~=handler
		and c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_XYZ)
		and c:GetOverlayCount()>0
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()

	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.eqfilter(chkc,c)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingTarget(
				s.eqfilter,
				tp,
				LOCATION_MZONE,
				0,
				1,
				c,
				c
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_TARGET
	)

	local g=Duel.SelectTarget(
		tp,
		s.eqfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		c,
		c
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_OVERLAY
	)
end

----------------------------------------------------------
--ADD MATERIALS TO HAND, THEN EQUIP TARGET
----------------------------------------------------------

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not c:IsFaceup()
		or not c:IsRelateToEffect(e)
	then
		return
	end

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or not tc:IsControler(tp)
	then
		return
	end

	------------------------------------------------------
	--The target must still have material.
	------------------------------------------------------
	local og=tc:GetOverlayGroup()

	if #og==0 then
		return
	end

	------------------------------------------------------
	--Add ALL of its Xyz Materials to the hand.
	------------------------------------------------------
	local ct=Duel.SendtoHand(
		og,
		nil,
		REASON_EFFECT
	)

	if ct==0 then
		return
	end

	------------------------------------------------------
	--"and if you do"
	--
	--At least one material successfully reached the hand.
	------------------------------------------------------
	local rg=Duel.GetOperatedGroup()

	if not rg:IsExists(
		Card.IsLocation,
		1,
		nil,
		LOCATION_HAND
	) then
		return
	end

	------------------------------------------------------
	--Need an available Spell/Trap Zone to equip.
	------------------------------------------------------
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	if not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
		or not tc:IsControler(tp)
	then
		return
	end

	------------------------------------------------------
	--Save the monster's current ATK before it becomes
	--an Equip Card.
	------------------------------------------------------
	local atk=tc:GetAttack()

	if atk<0 then
		atk=0
	end

	------------------------------------------------------
	--Equip the targeted Xyz Monster to Pitohui.
	------------------------------------------------------
	if not Duel.Equip(
		tp,
		tc,
		c,
		true
	) then
		return
	end

	------------------------------------------------------
	--Equip Limit:
	--This monster can only remain equipped to Pitohui.
	------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(s.eqlimit)
	e1:SetLabelObject(c)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)

	------------------------------------------------------
	--Pitohui gains ATK equal to half the ATK the
	--equipped monster had when equipped.
	------------------------------------------------------
	if atk>0 then
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_EQUIP)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(math.floor(atk/2))
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end

----------------------------------------------------------
--EQUIP LIMIT
----------------------------------------------------------

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end