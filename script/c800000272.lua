--Readen, Abyss Lord of Dark World
local s,id=GetID()

function s.initial_effect(c)
	--Xyz Summon: 2 Level 8 DARK monsters
	Xyz.AddProcedure(
		c,
		aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK),
		8,
		2
	)
	c:EnableReviveLimit()

	--During your turn, cannot be destroyed by battle
	--while this card has a "Dark World" monster as material
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.indcon)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	--During your turn, cannot be destroyed by card effects
	local e2=e1:Clone()
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	c:RegisterEffect(e2)

	--During your opponent's turn,
	--unaffected by your opponent's card effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.immcon)
	e3:SetValue(s.immfilter)
	c:RegisterEffect(e3)

	--Once per turn: detach 1; draw 1, then discard 1
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_DRAW+CATEGORY_HANDES)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCost(s.drcost)
	e4:SetTarget(s.drtg)
	e4:SetOperation(s.drop)
	c:RegisterEffect(e4)

	--If a "Dark World" monster is sent to your GY
	--while this card is already in your GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,1))
	e5:SetCategory(CATEGORY_TOHAND+CATEGORY_HANDES)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetProperty(EFFECT_FLAG_DELAY)
	e5:SetCode(EVENT_TO_GRAVE)
	e5:SetRange(LOCATION_GRAVE)
	e5:SetCountLimit(1,id)
	e5:SetCondition(s.gycon)
	e5:SetCost(s.gycost)
	e5:SetTarget(s.gytg)
	e5:SetOperation(s.gyop)
	c:RegisterEffect(e5)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Check for a "Dark World" Xyz Material
--==================================================

function s.dwmatfilter(c)
	return c:IsMonster()
		and c:IsSetCard(SET_DARK_WORLD)
end

function s.hasdwmat(c)
	return c:GetOverlayGroup():IsExists(
		s.dwmatfilter,
		1,
		nil
	)
end

--==================================================
-- Your turn protection
--==================================================

function s.indcon(e)
	local c=e:GetHandler()

	return Duel.GetTurnPlayer()==c:GetControler()
		and s.hasdwmat(c)
end

--==================================================
-- Opponent's turn immunity
--==================================================

function s.immcon(e)
	local c=e:GetHandler()

	return Duel.GetTurnPlayer()~=c:GetControler()
		and s.hasdwmat(c)
end

function s.immfilter(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end

--==================================================
-- Draw 1, then discard 1
--==================================================

function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
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

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.disfilter(c)
	return c:IsDiscardable()
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Draw(tp,1,REASON_EFFECT)==0 then
		return
	end

	if not Duel.IsExistingMatchingCard(
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil
	) then
		return
	end

	Duel.BreakEffect()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	if #g>0 then
		Duel.SendtoGrave(
			g,
			REASON_EFFECT|REASON_DISCARD
		)
	end
end

--==================================================
-- GY Effect
--==================================================

--Dark World monster just sent to your GY
function s.eventfilter(c,tp)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_GRAVE)
		and c:IsMonster()
		and c:IsSetCard(SET_DARK_WORLD)
end

function s.gycon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Readen must already have been in the GY.
	--If Readen itself was sent by this event,
	--it cannot trigger.
	if eg:IsContains(c) then
		return false
	end

	return eg:IsExists(
		s.eventfilter,
		1,
		nil,
		tp
	)
end

--==================================================
-- Banish Readen as cost
--==================================================

function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsAbleToRemoveAsCost()
	end

	Duel.Remove(
		c,
		POS_FACEUP,
		REASON_COST
	)
end

--==================================================
-- Recovery filter
--
-- Excludes:
-- 1. Readen itself
-- 2. The monster(s) sent by the triggering event
--==================================================

function s.thfilter(c,eg,rc)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsAbleToHand()
		and c~=rc
		and not eg:IsContains(c)
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil,
			eg,
			c
		)
	end

	local g=eg:Clone()
	g:KeepAlive()
	e:SetLabelObject(g)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_GRAVE
	)
end

--==================================================
-- Resolve:
-- add another Dark World card,
-- then you can discard 1
--==================================================

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local eventg=e:GetLabelObject()

	if not eventg then
		return
	end

	local rc=e:GetHandler()

	local g=Duel.GetMatchingGroup(
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		nil,
		eventg,
		rc
	)

	if #g==0 then
		eventg:DeleteGroup()
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local sg=g:Select(
		tp,
		1,
		1,
		nil
	)

	if #sg==0 then
		eventg:DeleteGroup()
		return
	end

	if Duel.SendtoHand(
		sg,
		nil,
		REASON_EFFECT
	)==0 then
		eventg:DeleteGroup()
		return
	end

	Duel.ConfirmCards(1-tp,sg)

	eventg:DeleteGroup()

	--Then you can discard 1 card
	if not Duel.IsExistingMatchingCard(
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil
	) then
		return
	end

	if not Duel.SelectYesNo(
		tp,
		aux.Stringid(id,2)
	) then
		return
	end

	Duel.BreakEffect()

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_DISCARD
	)

	local dg=Duel.SelectMatchingCard(
		tp,
		s.disfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		1,
		nil
	)

	if #dg>0 then
		Duel.SendtoGrave(
			dg,
			REASON_EFFECT|REASON_DISCARD
		)
	end
end