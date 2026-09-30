--Shaddoll Divani
local s,id=GetID()

function s.initial_effect(c)
	--Activate the Continuous Spell
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--If this card is activated: Set 1 "Sinister Shadow Games"
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_CHAIN_SOLVED)
	e1:SetRange(LOCATION_SZONE)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.setcon)
	e1:SetTarget(s.settg)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)

	--If exactly 1 Shaddoll Flip monster is Normal Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetRange(LOCATION_SZONE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.flipcon)
	e2:SetTarget(s.fliptg)
	e2:SetOperation(s.flipop)
	c:RegisterEffect(e2)

	--If exactly 1 Shaddoll Flip monster is Special Summoned
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

s.listed_series={0x9d}
s.listed_names={77505534} --Sinister Shadow Games

--==================================================
-- SET SINISTER SHADOW GAMES
--==================================================

function s.sgfilter(c)
	return c:IsCode(77505534) and c:IsSSetable()
end

--Trigger when this copy of Divani's activation resolves
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return re
		and re:IsHasType(EFFECT_TYPE_ACTIVATE)
		and re:GetHandler()==c
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.sgfilter,
			tp,
			LOCATION_DECK+LOCATION_GRAVE,
			0,
			1,
			nil
		)
	end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)

	local g=Duel.SelectMatchingCard(
		tp,
		s.sgfilter,
		tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SSet(tp,tc)>0 then
		--It can be activated this turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

--==================================================
-- CHECK FOR A FLIP EFFECT
--==================================================

function s.hasflipeffect(c)
	local effs={c:GetOwnEffects()}

	for _,te in ipairs(effs) do
		if te:GetType()&EFFECT_TYPE_FLIP~=0 then
			return true
		end
	end

	return false
end

--==================================================
-- VALID SUMMONED MONSTER
--==================================================

function s.flipfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsFaceup()
		and c:IsSetCard(0x9d)
		and c:IsType(TYPE_FLIP)
		and s.hasflipeffect(c)
end

--==================================================
-- SUMMON CONDITION
--==================================================

function s.flipcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsDamageStep() then
		return false
	end

	local g=eg:Filter(s.flipfilter,nil,tp)
	return #g==1
end

--==================================================
-- TARGET
--==================================================

function s.fliptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=eg:Filter(s.flipfilter,nil,tp)
	local tc=g:GetFirst()

	if chk==0 then
		return tc~=nil
	end

	e:SetLabelObject(tc)
end

--==================================================
-- APPLY SUMMONED MONSTER'S FLIP EFFECT
--==================================================

function s.flipop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()

	if not tc then return end

	--The monster must still be face-up on your field
	if not tc:IsFaceup()
		or not tc:IsControler(tp)
		or not tc:IsLocation(LOCATION_MZONE) then
		return
	end

	--Get that monster's own effects
	local effs={tc:GetOwnEffects()}
	local flips={}

	--Find its FLIP effect
	for _,te in ipairs(effs) do
		if te:GetType()&EFFECT_TYPE_FLIP~=0 then
			table.insert(flips,te)
		end
	end

	if #flips==0 then return end

	local te=nil

	--Normally a Shaddoll only has one FLIP effect
	if #flips==1 then
		te=flips[1]
	else
		local opts={}

		for _,fe in ipairs(flips) do
			local desc=fe:GetDescription()

			if desc and desc~=0 then
				table.insert(opts,desc)
			else
				table.insert(opts,aux.Stringid(id,2))
			end
		end

		local sel=Duel.SelectOption(tp,table.unpack(opts))+1
		te=flips[sel]
	end

	if not te then return end

	--Get copied FLIP effect components
	local cost=te:GetCost()
	local tg=te:GetTarget()
	local op=te:GetOperation()

	--Do NOT check the original FLIP condition.
	--The monster was Summoned, not actually flipped.

	--Check copied cost
	if cost and not cost(e,tp,eg,ep,ev,re,r,rp,0) then
		return
	end

	--Check copied target
	if tg and not tg(e,tp,eg,ep,ev,re,r,rp,0) then
		return
	end

	--Pay copied cost
	if cost then
		cost(e,tp,eg,ep,ev,re,r,rp,1)
	end

	--Select copied targets
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end

	--Apply copied FLIP effect
	if op then
		op(e,tp,eg,ep,ev,re,r,rp)
	end

	--==================================================
	-- SHUFFLE IT INTO THE DECK WHEN IT LEAVES THE FIELD
	--==================================================

	if tc:IsFaceup()
		and tc:IsControler(tp)
		and tc:IsLocation(LOCATION_MZONE) then

		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_LEAVE_FIELD_REDIRECT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(LOCATION_DECKSHF)
		e1:SetReset(RESET_EVENT+RESETS_REDIRECT)
		tc:RegisterEffect(e1)
	end
end