--Table Flip
local s,id=GetID()

function s.initial_effect(c)
	--Send 1 Flip monster from your hand or Deck to the GY,
	--then apply that monster's Flip Effect
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

--==================================================
-- VALID MONSTER
--==================================================

function s.filter(c)
	return c:IsMonster()
		and c:IsType(TYPE_FLIP)
		and c:IsAbleToGrave()
end

--==================================================
-- ACTIVATION
--
--The Spell can activate as long as a Flip monster
--can be sent.
--
--We deliberately do NOT require that monster's
--FLIP effect to currently have a valid target.
--
--If the copied FLIP effect cannot apply after the
--monster is sent, that portion simply fizzles.
--==================================================

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.filter,
			tp,
			LOCATION_HAND|LOCATION_DECK,
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
		LOCATION_HAND|LOCATION_DECK
	)
end

--==================================================
-- FIND THE ACTUAL REGISTERED FLIP EFFECT
--==================================================

function s.getflip(c)

	--Normal registered FLIP effects.
	local effects={c:GetOwnEffects()}

	for _,te in ipairs(effects) do
		if te then
			local typ=te:GetType()

			if typ and (typ&EFFECT_TYPE_FLIP)~=0 then
				return te
			end
		end
	end

	--==================================================
	-- FALLBACK FOR CUSTOM_REGISTER_FLIP
	--==================================================

	local marked={c:GetMarkedEffects(CUSTOM_REGISTER_FLIP)}

	for _,te in ipairs(marked) do
		if te then
			--Some custom registrations may use the
			--marker itself while others may store the
			--real effect in LabelObject.
			local lo=te:GetLabelObject()

			if lo then
				return lo
			end

			return te
		end
	end

	return nil
end

--==================================================
-- CAN THE COPIED FLIP EFFECT CURRENTLY APPLY?
--
--We intentionally DO NOT check the FLIP condition.
--
--The whole purpose of Table Flip is to bypass:
--
--"when this card is flipped face-up"
--
--and directly apply the FLIP payload.
--==================================================

function s.canapply(e,te,tp,eg,ep,ev,re,r,rp)

	if not te then
		return false
	end

	local cost=te:GetCost()
	local tg=te:GetTarget()

	--==================================================
	-- CHECK COPIED EFFECT'S OWN COST
	--==================================================

	if cost then
		local canpay=cost(
			e,
			tp,
			eg,
			ep,
			ev,
			re,
			r,
			rp,
			0
		)

		if canpay==false then
			return false
		end
	end

	--==================================================
	-- CHECK TARGET / ACTIVATION REQUIREMENTS
	--
	--THIS fixes cards such as Shaddoll Ariel.
	--
	--If Ariel has no valid banished Shaddoll:
	--
	--tg(...,0) -> false
	--
	--and Table Flip simply stops instead of running
	--Ariel's operation with a nil target.
	--==================================================

	if tg then
		local canapply=tg(
			e,
			tp,
			eg,
			ep,
			ev,
			re,
			r,
			rp,
			0
		)

		if canapply==false then
			return false
		end
	end

	return true
end

--==================================================
-- APPLY COPIED FLIP EFFECT
--==================================================

function s.applyflip(e,te,tp,eg,ep,ev,re,r,rp)

	if not te then
		return
	end

	--==================================================
	-- SAFETY CHECK FIRST
	--
	--Do this BEFORE calling target(...,1) or operation.
	--==================================================

	if not s.canapply(
		e,
		te,
		tp,
		eg,
		ep,
		ev,
		re,
		r,
		rp
	) then
		return
	end

	local cost=te:GetCost()
	local tg=te:GetTarget()
	local op=te:GetOperation()

	--==================================================
	-- PRESERVE TABLE FLIP STATE
	--==================================================

	local oldlabel=e:GetLabel()
	local oldobject=e:GetLabelObject()

	--Copy internal information used by the FLIP effect.
	e:SetLabel(te:GetLabel())
	e:SetLabelObject(te:GetLabelObject())

	--==================================================
	-- COPIED FLIP EFFECT'S OWN COST
	--
	--This has NOTHING to do with sending the monster.
	--
	--The monster has already been sent by:
	--
	--Duel.SendtoGrave(tc,REASON_EFFECT)
	--==================================================

	if cost then

		--Recheck immediately before execution.
		local canpay=cost(
			e,
			tp,
			eg,
			ep,
			ev,
			re,
			r,
			rp,
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
			eg,
			ep,
			ev,
			re,
			r,
			rp,
			1
		)
	end

	--==================================================
	-- COPIED TARGET / SETUP
	--==================================================

	if tg then

		--One last check before target selection/setup.
		local canapply=tg(
			e,
			tp,
			eg,
			ep,
			ev,
			re,
			r,
			rp,
			0
		)

		if canapply==false then
			e:SetLabel(oldlabel)
			e:SetLabelObject(oldobject)
			return
		end

		tg(
			e,
			tp,
			eg,
			ep,
			ev,
			re,
			r,
			rp,
			1
		)
	end

	--==================================================
	-- TARGET SAFETY
	--
	--If this FLIP effect explicitly targets cards but
	--no target was established, DO NOT run operation.
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
	-- APPLY COPIED FLIP OPERATION
	--
	--Table Flip is executing the effect.
	--
	--The sent Flip monster itself is NOT activating.
	--==================================================

	if op then
		op(
			e,
			tp,
			eg,
			ep,
			ev,
			re,
			r,
			rp
		)
	end

	--==================================================
	-- RESTORE TABLE FLIP STATE
	--==================================================

	e:SetLabel(oldlabel)
	e:SetLabelObject(oldobject)
end

--==================================================
-- RESOLUTION
--==================================================

function s.operation(e,tp,eg,ep,ev,re,r,rp)

	--==================================================
	-- SELECT FLIP MONSTER DURING RESOLUTION
	--==================================================

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.filter,
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

	--==================================================
	-- CAPTURE FLIP EFFECT BEFORE MOVING CARD
	--
	--This is important because after changing location
	--we don't want to rely on recovering the registered
	--FLIP effect from the card again.
	--==================================================

	local te=s.getflip(tc)

	--==================================================
	-- SEND BY CARD EFFECT
	--
	--NOT COST.
	--
	--This means effects such as Shaddolls that trigger
	--when sent to the GY by a card effect can trigger.
	--==================================================

	if Duel.SendtoGrave(
		tc,
		REASON_EFFECT
	)==0 then
		return
	end

	--The card must actually reach the GY.
	if not tc:IsLocation(LOCATION_GRAVE) then
		return
	end

	--==================================================
	-- NO FLIP PAYLOAD FOUND
	--
	--The send still happened.
	--Just stop here safely.
	--==================================================

	if not te then
		return
	end

	--==================================================
	-- APPLY CAPTURED FLIP EFFECT
	--
	--If its targets/requirements are no longer valid,
	--s.applyflip simply returns without throwing an
	--error.
	--==================================================

	s.applyflip(
		e,
		te,
		tp,
		eg,
		ep,
		ev,
		re,
		r,
		rp
	)
end