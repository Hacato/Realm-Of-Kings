--SAO Swordland
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) When activated:
	--You can place 1 En-Counter on your "SAO" Field Spell.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.cttg)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Search:
	--Discard 1 SAO monster OR remove 2 En-Counters;
	--add 1 SAO monster from Deck to hand.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	----------------------------------------------------------
	--(3) Once per turn, when your SAO monster destroys
	--an opponent's monster by battle: Draw 1.
	----------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) PLACE EN-COUNTER
----------------------------------------------------------

function s.fieldfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsType(TYPE_FIELD)
		and c:IsCanAddCounter(COUNTER_EN,1)
end

function s.cttg(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)

	if chk==0 then
		--The Spell can still be activated even if
		--there is no valid SAO Field Spell.
		return true
	end

	if tc
		and s.fieldfilter(tc)
		and Duel.SelectYesNo(tp,aux.Stringid(id,0))
	then
		e:SetLabel(1)

		Duel.SetOperationInfo(
			0,
			CATEGORY_COUNTER,
			tc,
			1,
			tp,
			COUNTER_EN
		)
	else
		e:SetLabel(0)
	end
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()~=1 then
		return
	end

	--Swordland itself must have successfully resolved.
	if not e:GetHandler():IsRelateToEffect(e) then
		return
	end

	local tc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)

	if tc
		and s.fieldfilter(tc)
	then
		tc:AddCounter(COUNTER_EN,1)
	end
end

----------------------------------------------------------
--(2) SEARCH
----------------------------------------------------------

function s.costfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:IsDiscardable()
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local can_discard=Duel.IsExistingMatchingCard(
		s.costfilter,
		tp,
		LOCATION_HAND,
		0,
		1,
		nil
	)

	local can_counter=Duel.IsCanRemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		2,
		REASON_COST
	)

	if chk==0 then
		return can_discard or can_counter
	end

	------------------------------------------------------
	--Both costs available.
	------------------------------------------------------
	if can_discard and can_counter then
		local op=Duel.SelectOption(
			tp,
			aux.Stringid(id,3),
			aux.Stringid(id,4)
		)

		if op==0 then
			Duel.Hint(
				HINT_SELECTMSG,
				tp,
				HINTMSG_DISCARD
			)

			Duel.DiscardHand(
				tp,
				s.costfilter,
				1,
				1,
				REASON_COST+REASON_DISCARD,
				nil
			)
		else
			Duel.RemoveCounter(
				tp,
				1,
				0,
				COUNTER_EN,
				2,
				REASON_COST
			)
		end

	------------------------------------------------------
	--Only discard available.
	------------------------------------------------------
	elseif can_discard then
		Duel.Hint(
			HINT_SELECTMSG,
			tp,
			HINTMSG_DISCARD
		)

		Duel.DiscardHand(
			tp,
			s.costfilter,
			1,
			1,
			REASON_COST+REASON_DISCARD,
			nil
		)

	------------------------------------------------------
	--Only counters available.
	------------------------------------------------------
	else
		Duel.RemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			2,
			REASON_COST
		)
	end
end

function s.thfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.thfilter,
			tp,
			LOCATION_DECK,
			0,
			1,
			nil
		)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		nil,
		1,
		tp,
		LOCATION_DECK
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then
		return
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectMatchingCard(
		tp,
		s.thfilter,
		tp,
		LOCATION_DECK,
		0,
		1,
		1,
		nil
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
--(3) DRAW WHEN SAO DESTROYS BY BATTLE
----------------------------------------------------------

function s.drfilter(c,tp)
	return c:IsControler(tp)
		and c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(
		s.drfilter,
		1,
		nil,
		tp
	)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsPlayerCanDraw(tp,1)
	end

	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(1)

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1
	)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then
		return
	end

	local p,d=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_PLAYER,
		CHAININFO_TARGET_PARAM
	)

	Duel.Draw(
		p,
		d,
		REASON_EFFECT
	)
end