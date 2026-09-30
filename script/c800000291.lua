--Jushaddoll Catastor
local s,id=GetID()

function s.initial_effect(c)
	--FLIP: Set or activate 1 "Sinister Shadow Games" from Deck or GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_FLIP+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sgtg)
	e1:SetOperation(s.sgop)
	c:RegisterEffect(e1)

	--If sent to the GY by card effect:
	--Pay 1000 LP, reveal 1 Level 5 or lower "Shaddoll"
	--and apply its FLIP effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.gycon)
	e2:SetCost(s.gycost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end

s.listed_series={0x9d}
s.listed_names={77505534} --Sinister Shadow Games

--==================================================
-- FLIP EFFECT
-- Set or activate "Sinister Shadow Games"
--==================================================

function s.sgfilter(c)
	return c:IsCode(77505534) and c:IsSSetable()
end

function s.sgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.sgfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil
		)
	end
end

function s.sgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(
		tp,s.sgfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil
	)
	local tc=g:GetFirst()
	if not tc then return end

	--Set Sinister Shadow Games
	if Duel.SSet(tp,tc)==0 then return end

	--Ask whether to activate it immediately
	if not Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		return
	end

	local te=tc:GetActivateEffect()
	if not te then return end

	local con=te:GetCondition()
	local cost=te:GetCost()
	local tg=te:GetTarget()
	local op=te:GetOperation()

	if con and not con(te,tp,eg,ep,ev,re,r,rp) then
		return
	end

	if cost and not cost(te,tp,eg,ep,ev,re,r,rp,0) then
		return
	end

	if tg and not tg(te,tp,eg,ep,ev,re,r,rp,0) then
		return
	end

	Duel.BreakEffect()

	tc:CreateEffectRelation(te)

	if cost then
		cost(te,tp,eg,ep,ev,re,r,rp,1)
	end

	if tg then
		tg(te,tp,eg,ep,ev,re,r,rp,1)
	end

	if op then
		op(te,tp,eg,ep,ev,re,r,rp)
	end

	tc:ReleaseEffectRelation(te)

	--Send the activated Normal Trap to the GY
	Duel.SendtoGrave(tc,REASON_RULE)
end

--==================================================
-- GY EFFECT
--==================================================

--Must have been sent to the GY by a card effect
function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT)
end

--Pay 1000 LP
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.CheckLPCost(tp,1000)
	end
	Duel.PayLPCost(tp,1000)
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

--Valid monster:
--Level 5 or lower Shaddoll
--Not Jushaddoll Catastor
--Must actually possess a FLIP effect
function s.gyfilter(c)
	return c:IsSetCard(0x9d)
		and c:IsMonster()
		and c:IsLevelBelow(5)
		and not c:IsCode(id)
		and s.hasflipeffect(c)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.gyfilter,
			tp,
			LOCATION_HAND+LOCATION_DECK,
			0,
			1,
			nil
		)
	end
end

--==================================================
-- APPLY THE REVEALED SHADDOLL'S FLIP EFFECT
--==================================================

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	--Select a Level 5 or lower Shaddoll
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)

	local g=Duel.SelectMatchingCard(
		tp,
		s.gyfilter,
		tp,
		LOCATION_HAND+LOCATION_DECK,
		0,
		1,
		1,
		nil
	)

	local tc=g:GetFirst()
	if not tc then return end

	--Reveal the selected monster
	Duel.ConfirmCards(1-tp,tc)

	--Get the selected monster's own effects
	local effs={tc:GetOwnEffects()}
	local flips={}

	--Find its FLIP effect(s)
	for _,te in ipairs(effs) do
		if te:GetType()&EFFECT_TYPE_FLIP~=0 then
			table.insert(flips,te)
		end
	end

	if #flips==0 then
		return
	end

	local te=nil

	--Normally a Shaddoll has only one FLIP effect
	if #flips==1 then
		te=flips[1]
	else
		--If a monster somehow has multiple FLIP effects,
		--allow the player to choose one
		local opts={}

		for _,fe in ipairs(flips) do
			local desc=fe:GetDescription()
			if desc and desc~=0 then
				table.insert(opts,desc)
			else
				table.insert(opts,aux.Stringid(id,3))
			end
		end

		local sel=Duel.SelectOption(tp,table.unpack(opts))+1
		te=flips[sel]
	end

	if not te then return end

	--Get the copied FLIP effect's components
	local con=te:GetCondition()
	local cost=te:GetCost()
	local tg=te:GetTarget()
	local op=te:GetOperation()

	--The selected monster is not actually being flipped.
	--We are applying its FLIP effect through Catastor.
	--
	--Use Catastor's current effect (e) when running the
	--target and operation so effects which reference
	--e:GetHandler() still resolve through Catastor.

	--Check the copied effect's target requirements
	if tg and not tg(e,tp,eg,ep,ev,re,r,rp,0) then
		return
	end

	--Apply any cost belonging to the copied FLIP effect
	if cost then
		if not cost(e,tp,eg,ep,ev,re,r,rp,0) then
			return
		end
		cost(e,tp,eg,ep,ev,re,r,rp,1)
	end

	--Select targets / declare information
	if tg then
		tg(e,tp,eg,ep,ev,re,r,rp,1)
	end

	--Apply the FLIP effect
	if op then
		op(e,tp,eg,ep,ev,re,r,rp)
	end
end