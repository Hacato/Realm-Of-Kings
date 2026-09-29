--Renshaddoll Winda
local s,id=GetID()
local params={aux.FilterBoolFunction(Card.IsSetCard,SET_SHADDOLL)}

function s.initial_effect(c)
	--FLIP: Fusion Summon 1 "Shaddoll" Fusion Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_FLIP+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(Fusion.SummonEffTG(table.unpack(params)))
	e1:SetOperation(Fusion.SummonEffOP(table.unpack(params)))
	c:RegisterEffect(e1,false,CUSTOM_REGISTER_FLIP)

	--If sent to the GY by a card effect:
	--Target 1 "Shaddoll" Fusion Monster you control;
	--it gains the listed Quick Effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.effcon)
	e2:SetTarget(s.efftg)
	e2:SetOperation(s.effop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SHADDOLL}

--==================================================
-- SENT TO GY EFFECT
--==================================================

function s.effcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT)
end

function s.efffilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SHADDOLL)
		and c:IsType(TYPE_FUSION)
end

function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.efffilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.efffilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(
		tp,
		s.efffilter,
		tp,
		LOCATION_MZONE,
		0,
		1,
		1,
		nil
	)
end

--==================================================
-- GRANT QUICK EFFECT
--==================================================

function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not (tc and tc:IsFaceup() and tc:IsRelateToEffect(e)) then
		return
	end

	Duel.HintSelection(tc)

	local e1=Effect.CreateEffect(tc)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.copytg)
	e1:SetOperation(s.copyop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

--==================================================
-- VALID SHADDOLL FLIP MONSTER
--==================================================

function s.copyfilter(c)
	return c:IsSetCard(SET_SHADDOLL)
		and c:IsMonster()
		and c:IsType(TYPE_FLIP)
		and c:IsAbleToGrave()
end

--==================================================
-- QUICK EFFECT TARGET
--
--Nothing is sent as cost.
--
--We only check that a valid Shaddoll Flip monster
--exists in the Deck.
--==================================================

function s.copytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.copyfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOGRAVE,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

--==================================================
-- FIND ACTUAL REGISTERED FLIP EFFECT
--==================================================

function s.getflip(c)
	local effects={c:GetOwnEffects()}

	for _,te in ipairs(effects) do
		if te then
			local typ=te:GetType()

			if typ and (typ&EFFECT_TYPE_FLIP)~=0 then
				return te
			end
		end
	end

	return nil
end

--==================================================
-- QUICK EFFECT RESOLUTION
--==================================================

function s.copyop(e,tp,eg,ep,ev,re,r,rp)

	--==================================================
	-- SELECT SHADDOLL FLIP MONSTER
	--
	--Selection happens during resolution.
	--==================================================

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.copyfilter,
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

	--==================================================
	-- CAPTURE FLIP EFFECT BEFORE MOVING THE CARD
	--==================================================

	local te=s.getflip(tc)

	--==================================================
	-- SEND BY CARD EFFECT
	--
	--THIS IS THE IMPORTANT CHANGE.
	--
	--REASON_EFFECT means Shaddoll effects that trigger
	--when sent to the GY by a card effect can activate.
	--==================================================

	if Duel.SendtoGrave(tc,REASON_EFFECT)==0 then
		return
	end

	--The monster must actually reach the GY.
	if not tc:IsLocation(LOCATION_GRAVE) then
		return
	end

	--No FLIP payload found.
	if not te then
		return
	end

	--==================================================
	-- GET FLIP EFFECT PAYLOAD
	--==================================================

	local cost=te:GetCost()
	local tg=te:GetTarget()
	local op=te:GetOperation()

	--==================================================
	-- CHECK WHETHER COPIED EFFECT CAN APPLY
	--
	--Example:
	--Ariel with no banished Shaddoll should stop here
	--instead of producing a Lua error.
	--==================================================

	if tg then
		local canapply=tg(
			e,
			tp,
			Group.CreateGroup(),
			PLAYER_NONE,
			0,
			e,
			REASON_EFFECT,
			tp,
			0
		)

		if not canapply then
			return
		end
	end

	--==================================================
	-- SAVE QUICK EFFECT STATE
	--==================================================

	local oldlabel=e:GetLabel()
	local oldobject=e:GetLabelObject()

	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())

	--==================================================
	-- COPIED FLIP EFFECT COST/SETUP
	--
	--This is NOT the Deck send.
	--
	--The Deck send already occurred above by effect.
	--==================================================

	if cost then
		local canpay=cost(
			e,
			tp,
			Group.CreateGroup(),
			PLAYER_NONE,
			0,
			e,
			REASON_EFFECT,
			tp,
			0
		)

		if canpay==false then
			e:SetLabel(oldlabel)
			e:SetLabelObject(oldobject)
			return
		end

		cost(
			e,
			tp,
			Group.CreateGroup(),
			PLAYER_NONE,
			0,
			e,
			REASON_EFFECT,
			tp,
			1
		)
	end

	--==================================================
	-- COPIED TARGET / SETUP
	--==================================================

	if tg then
		tg(
			e,
			tp,
			Group.CreateGroup(),
			PLAYER_NONE,
			0,
			e,
			REASON_EFFECT,
			tp,
			1
		)
	end

	--==================================================
	-- TARGET SAFETY
	--
	--If the copied effect requires a card target but
	--failed to establish one, stop before its operation.
	--==================================================

	if te:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		local targets=Duel.GetChainInfo(
			0,
			CHAININFO_TARGET_CARDS
		)

		if not targets or #targets==0 then
			e:SetLabel(oldlabel)
			e:SetLabelObject(oldobject)
			return
		end
	end

	--==================================================
	-- APPLY THE FLIP EFFECT
	--
	--"e" is the Shaddoll Fusion's Quick Effect.
	--
	--The sent monster supplies only its FLIP payload.
	--==================================================

	if op then
		op(
			e,
			tp,
			Group.CreateGroup(),
			PLAYER_NONE,
			0,
			e,
			REASON_EFFECT,
			tp
		)
	end

	--==================================================
	-- RESTORE EFFECT STATE
	--==================================================

	e:SetLabel(oldlabel)
	e:SetLabelObject(oldobject)
end