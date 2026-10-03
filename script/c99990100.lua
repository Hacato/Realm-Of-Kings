--SAO Silica - SAO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) If Normal or Special Summoned:
	--Equip 1 "SAO Pina" from your hand or Deck
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.eqtg)
	e1:SetOperation(s.eqop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--(2) Once per turn:
	--Remove 1 EN-Counter, then target 1 Set card
	--your opponent controls; return it to the hand.
	--The targeted card cannot be activated in response.
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.rthcost)
	e3:SetTarget(s.rthtg)
	e3:SetOperation(s.rthop)
	c:RegisterEffect(e3)
end

s.listed_names={99990110}
s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) EQUIP "SAO PINA"
----------------------------------------------------------

function s.eqfilter(c)
	return c:IsCode(99990110)
		and c:IsMonster()
		and not c:IsForbidden()
end

function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(
				s.eqfilter,
				tp,
				LOCATION_HAND|LOCATION_DECK,
				0,
				1,
				nil
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_EQUIP,
		nil,
		1,
		tp,
		LOCATION_HAND|LOCATION_DECK
	)
end

function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsFaceup()
		or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)

	local g=Duel.SelectMatchingCard(
		tp,
		s.eqfilter,
		tp,
		LOCATION_HAND|LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then
		return
	end

	if Duel.Equip(tp,tc,c,true) then
		--------------------------------------------------
		--Pina can only remain equipped to this Silica
		--------------------------------------------------
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(c)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

----------------------------------------------------------
--(2) REMOVE 1 EN-COUNTER
----------------------------------------------------------

function s.rthcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--TARGET 1 SET CARD YOUR OPPONENT CONTROLS
----------------------------------------------------------

function s.rthfilter(c)
	return c:IsFacedown()
		and c:IsAbleToHand()
end

function s.rthtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_ONFIELD)
			and s.rthfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.rthfilter,
			tp,
			0,
			LOCATION_ONFIELD,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)

	local g=Duel.SelectTarget(
		tp,
		s.rthfilter,
		tp,
		0,
		LOCATION_ONFIELD,
		1,
		1,
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

	------------------------------------------------------
	--Night Beam-style chain restriction.
	--
	--The selected Set card itself cannot be activated
	--in response to this effect.
	--
	--Other cards/effects can still respond.
	------------------------------------------------------
	local tc=g:GetFirst()

	if tc then
		Duel.SetChainLimit(s.limit(tc))
	end
end

----------------------------------------------------------
--TARGETED CARD CANNOT RESPOND
----------------------------------------------------------

function s.limit(c)
	return function(e,lp,tp)
		return e:GetHandler()~=c
	end
end

----------------------------------------------------------
--RETURN TARGET TO HAND
----------------------------------------------------------

function s.rthop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)
	end
end