--SAO Agil - SAO
--Scripted by Raivost
--Updated for current Project Ignis/EDOPro
local s,id=GetID()

local SET_SAO=0x999
local COUNTER_EN=0x1994

function s.initial_effect(c)
	----------------------------------------------------------
	--(1) If added to hand, except by normal draw,
	--while all monsters you control are SAO monsters:
	--Reveal this card; Special Summon it.
	----------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	----------------------------------------------------------
	--(2) Remove 1 En-Counter;
	--target 1 SAO monster in GY except this card;
	--add it to hand.
	----------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id+1)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SAO}
s.counter_list={COUNTER_EN}

----------------------------------------------------------
--(1) SPECIAL SUMMON FROM HAND
----------------------------------------------------------

function s.fieldfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(SET_SAO)
		and c:IsMonster()
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	------------------------------------------------------
	--Must actually still be in the hand.
	------------------------------------------------------
	if not c:IsLocation(LOCATION_HAND) then
		return false
	end

	------------------------------------------------------
	--Do not trigger from the normal draw.
	------------------------------------------------------
	if Duel.GetCurrentPhase()==PHASE_DRAW
		and Duel.GetTurnPlayer()==tp
		and c:IsReason(REASON_DRAW)
	then
		return false
	end

	------------------------------------------------------
	--Must control at least 1 monster.
	------------------------------------------------------
	local g=Duel.GetFieldGroup(
		tp,
		LOCATION_MZONE,
		0
	)

	if #g==0 then
		return false
	end

	------------------------------------------------------
	--Every monster you control must be a face-up
	--SAO monster.
	------------------------------------------------------
	return g:FilterCount(
		s.fieldfilter,
		nil
	)==#g
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(
				e,
				0,
				tp,
				false,
				false
			)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		c,
		1,
		tp,
		LOCATION_HAND
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsLocation(LOCATION_HAND)
	then
		return
	end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	------------------------------------------------------
	--"You can reveal this card"
	------------------------------------------------------
	Duel.ConfirmCards(
		1-tp,
		Group.FromCards(c)
	)

	------------------------------------------------------
	--Special Summon it from the hand.
	------------------------------------------------------
	if c:IsCanBeSpecialSummoned(
		e,
		0,
		tp,
		false,
		false
	) then
		Duel.SpecialSummon(
			c,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEUP
		)
	end
end

----------------------------------------------------------
--(2) RECOVER SAO MONSTER
----------------------------------------------------------

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(
			tp,
			1,
			0,
			COUNTER_EN,
			1,
			REASON_COST
		)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		COUNTER_EN,
		1,
		REASON_COST
	)
end

function s.thfilter(c)
	return c:IsSetCard(SET_SAO)
		and c:IsMonster()
		and not c:IsCode(id)
		and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.thfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.thfilter,
			tp,
			LOCATION_GRAVE,
			0,
			1,
			nil
		)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_ATOHAND
	)

	local g=Duel.SelectTarget(
		tp,
		s.thfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_TOHAND,
		g,
		1,
		tp,
		LOCATION_GRAVE
	)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if tc
		and tc:IsRelateToEffect(e)
		and tc:IsAbleToHand()
	then
		Duel.SendtoHand(
			tc,
			nil,
			REASON_EFFECT
		)

		Duel.ConfirmCards(
			1-tp,
			Group.FromCards(tc)
		)
	end
end