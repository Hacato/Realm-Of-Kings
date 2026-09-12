--Latinum, Exarch Lord of Dark World
local s,id=GetID()

function s.initial_effect(c)
	--Fusion procedure
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,s.fusfilter,
		aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK))

	--The activation of your "Dark World" card effects cannot be negated
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_INACTIVATE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.dwactfilter)
	c:RegisterEffect(e1)

	--The activated effects of your "Dark World" cards cannot be negated
	local e2=e1:Clone()
	e2:SetCode(EFFECT_CANNOT_DISEFFECT)
	c:RegisterEffect(e2)

	--The activation of your monster effects in the GY cannot be negated
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_INACTIVATE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.gyactfilter)
	c:RegisterEffect(e3)

	--The activated effects of your monsters in the GY cannot be negated
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_DISEFFECT)
	c:RegisterEffect(e4)

	--Discard 1 card, then banish 1 card from opponent's GY
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,0))
	e5:SetCategory(CATEGORY_REMOVE)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id)
	e5:SetTarget(s.rmtg)
	e5:SetOperation(s.rmop)
	c:RegisterEffect(e5)

	--If this Fusion Summoned card leaves the field by an opponent's effect
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,1))
	e6:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e6:SetProperty(EFFECT_FLAG_DELAY)
	e6:SetCode(EVENT_LEAVE_FIELD)
	e6:SetCondition(s.thcon)
	e6:SetTarget(s.thtg)
	e6:SetOperation(s.thop)
	c:RegisterEffect(e6)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Fusion Materials
-- 1 Level 5 or 6 "Dark World" monster
-- + 1 DARK monster
--==================================================

function s.fusfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsMonster()
		and (c:IsLevel(5) or c:IsLevel(6))
end

--==================================================
-- Continuous protection
-- "Dark World" activated effects
--==================================================

function s.dwactfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	local tp=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_PLAYER)
	if not te then return false end

	local tc=te:GetHandler()
	return tp==e:GetHandlerPlayer()
		and tc
		and tc:IsSetCard(SET_DARK_WORLD)
end

--==================================================
-- Continuous protection
-- Monster effects activated in your GY
--==================================================

function s.gyactfilter(e,ct)
	local te=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_EFFECT)
	local tp=Duel.GetChainInfo(ct,CHAININFO_TRIGGERING_PLAYER)
	if not te then return false end

	local tc=te:GetHandler()
	return tp==e:GetHandlerPlayer()
		and tc
		and tc:IsMonster()
		and te:GetActivateLocation()==LOCATION_GRAVE
end

--==================================================
-- Quick Effect
-- Target 1 card in opponent's GY;
-- discard 1 card, then banish that target
--==================================================

function s.rmfilter(c)
	return c:IsAbleToRemove()
end

function s.disfilter(c)
	return c:IsDiscardable()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.rmfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.rmfilter,tp,0,LOCATION_GRAVE,1,nil
		)
			and Duel.IsExistingMatchingCard(
				s.disfilter,tp,LOCATION_HAND,0,1,nil
			)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectTarget(
		tp,s.rmfilter,tp,
		0,LOCATION_GRAVE,
		1,1,nil
	)

	Duel.SetOperationInfo(
		0,CATEGORY_REMOVE,
		g,1,1-tp,LOCATION_GRAVE
	)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	--Discard is part of the EFFECT, not a cost.
	--This allows "Dark World" discard effects to trigger.
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(
		tp,s.disfilter,tp,
		LOCATION_HAND,0,
		1,1,nil
	)

	if #g==0 then return end

	if Duel.SendtoGrave(
		g,REASON_EFFECT+REASON_DISCARD
	)==0 then
		return
	end

	--"then banish that target"
	if tc
		and tc:IsRelateToEffect(e)
		and tc:IsLocation(LOCATION_GRAVE)
		and tc:IsAbleToRemove()
	then
		Duel.Remove(
			tc,
			POS_FACEUP,
			REASON_EFFECT
		)
	end
end

--==================================================
-- If this Fusion Summoned card leaves the field
-- by an opponent's effect
--==================================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_ONFIELD)
		and c:IsPreviousPosition(POS_FACEUP)
		and c:IsSummonType(SUMMON_TYPE_FUSION)
		and c:IsReason(REASON_EFFECT)
		and rp==1-tp
end

function s.thfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,tp,
			LOCATION_DECK+LOCATION_GRAVE,
			0,1,nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK+LOCATION_GRAVE
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,s.thfilter,tp,
		LOCATION_DECK+LOCATION_GRAVE,
		0,1,1,nil
	)

	if #g>0 then
		Duel.SendtoHand(
			g,nil,REASON_EFFECT
		)
		Duel.ConfirmCards(1-tp,g)
	end
end