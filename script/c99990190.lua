--SAO Kirito - GGO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

function s.initial_effect(c)
	----------------------------------------------------------
	--Xyz Summon
	--2 Level 4 "SAO" monsters
	----------------------------------------------------------
	Xyz.AddProcedure(
		c,
		aux.FilterBoolFunctionEx(Card.IsSetCard,0x999),
		4,2
	)
	c:EnableReviveLimit()

	----------------------------------------------------------
	--(1) When a card/effect targets exactly 1 OTHER
	--"SAO" monster you control:
	--Remove 1 En-Counter, then target 1 card
	--your opponent controls; destroy it.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_CHAINING)
	e1:SetProperty(
		EFFECT_FLAG_DAMAGE_STEP
		|EFFECT_FLAG_DAMAGE_CAL
		|EFFECT_FLAG_CARD_TARGET
	)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.descon)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Once per turn, at the start of the Damage Step,
	--if this card attacks an opponent's monster:
	--Detach 1 material; return that monster to the hand.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_START)
	e2:SetCountLimit(1)
	e2:SetCondition(s.thcon)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={0x999}
s.counter_list={0x1994}

----------------------------------------------------------
--(1) TARGETING RESPONSE
----------------------------------------------------------

--The card being targeted must be:
-- • controlled by us
-- • in our Monster Zone
-- • an "SAO" monster
-- • NOT this Kirito
function s.tgfilter(c,tp,sc)
	return c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsMonster()
		and c:IsSetCard(0x999)
		and c~=sc
end

function s.descon(e,tp,eg,ep,ev,re,r,rp)
	------------------------------------------------------
	--The activating effect must target cards.
	------------------------------------------------------
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		return false
	end

	local g=Duel.GetChainInfo(
		ev,
		CHAININFO_TARGET_CARDS
	)

	------------------------------------------------------
	--It must target EXACTLY 1 card.
	------------------------------------------------------
	if not g or #g~=1 then
		return false
	end

	local tc=g:GetFirst()

	------------------------------------------------------
	--That one target must be another "SAO" monster
	--we control.
	------------------------------------------------------
	return tc
		and s.tgfilter(
			tc,
			tp,
			e:GetHandler()
		)
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
--TARGET 1 CARD OPPONENT CONTROLS
----------------------------------------------------------

function s.desfilter(c)
	return c:IsDestructable()
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

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e) then
		Duel.Destroy(
			tc,
			REASON_EFFECT
		)
	end
end

----------------------------------------------------------
--(2) START OF DAMAGE STEP
----------------------------------------------------------

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()

	return c==Duel.GetAttacker()
		and tc
		and tc:IsControler(1-tp)
		and tc:IsMonster()
end

----------------------------------------------------------
--DETACH 1 MATERIAL
----------------------------------------------------------

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
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
--RETURN THE MONSTER BEING ATTACKED
----------------------------------------------------------

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()

	if chk==0 then
		return tc
			and tc:IsRelateToBattle()
			and tc:IsAbleToHand()
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		tc,
		1,
		0,
		0
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()

	if tc
		and tc:IsRelateToBattle()
		and tc:IsAbleToHand() then

		Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)
	end
end