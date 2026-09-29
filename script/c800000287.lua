--Apophis Shaddoll Python
local s,id=GetID()

function s.initial_effect(c)
	--Fusion Materials:
	--1 "Shaddoll" monster + 1 Wyrm monster
	c:EnableReviveLimit()
	Fusion.AddProcMix(
		c,
		true,
		true,
		aux.FilterBoolFunctionEx(Card.IsSetCard,SET_SHADDOLL),
		aux.FilterBoolFunctionEx(Card.IsRace,RACE_WYRM)
	)

	--Each time a "Shaddoll" monster(s) is sent to the GY
	--by a card effect: Draw 1 card.
	--If this effect has drawn 3 or more cards while
	--this card is face-up, destroy this card.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	--If this card is sent to the GY:
	--Target 1 "Shaddoll" monster in your GY;
	--Special Summon it in face-down Defense Position.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_SHADDOLL}

--==================================================
-- DRAW EFFECT
--==================================================

--A "Shaddoll" monster was sent to the GY
--by a card effect.
function s.drfilter(c)
	return c:IsMonster()
		and c:IsSetCard(SET_SHADDOLL)
		and c:IsReason(REASON_EFFECT)
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.drfilter,1,nil)
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
	local c=e:GetHandler()

	--Python must still be face-up on the field.
	if not (c:IsFaceup() and c:IsRelateToEffect(e)) then
		return
	end

	local p,d=Duel.GetChainInfo(
		0,
		CHAININFO_TARGET_PLAYER,
		CHAININFO_TARGET_PARAM
	)

	--Draw 1.
	if Duel.Draw(p,d,REASON_EFFECT)==0 then
		return
	end

	--==================================================
	-- COUNT DRAWS MADE BY THIS COPY
	--==================================================

	local ct=c:GetFlagEffectLabel(id)

	if not ct then
		ct=0
	end

	ct=ct+1

	--Replace the previous counter with the new value.
	c:ResetFlagEffect(id)

	c:RegisterFlagEffect(
		id,
		RESET_EVENT+RESETS_STANDARD,
		0,
		1,
		ct
	)

	--==================================================
	-- THIRD DRAW
	--
	--Once this effect has successfully drawn
	--3 cards, destroy Python.
	--==================================================

	if ct>=3
		and c:IsFaceup()
		and c:IsRelateToEffect(e) then

		Duel.BreakEffect()
		Duel.Destroy(c,REASON_EFFECT)
	end
end

--==================================================
-- GY SPECIAL SUMMON EFFECT
--==================================================

function s.spfilter(c,e,tp)
	return c:IsMonster()
		and c:IsSetCard(SET_SHADDOLL)
		and c:IsCanBeSpecialSummoned(
			e,
			0,
			tp,
			false,
			false,
			POS_FACEDOWN_DEFENSE
		)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.spfilter(chkc,e,tp)
	end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(
				s.spfilter,
				tp,
				LOCATION_GRAVE,
				0,
				1,
				nil,
				e,
				tp
			)
	end

	Duel.Hint(
		HINT_SELECTMSG,
		tp,
		HINTMSG_SPSUMMON
	)

	local g=Duel.SelectTarget(
		tp,
		s.spfilter,
		tp,
		LOCATION_GRAVE,
		0,
		1,
		1,
		nil,
		e,
		tp
	)

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		g,
		1,
		0,
		0
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	--Need an available Monster Zone.
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	local tc=Duel.GetFirstTarget()

	if not tc then
		return
	end

	if tc:IsRelateToEffect(e)
		and s.spfilter(tc,e,tp) then

		Duel.SpecialSummon(
			tc,
			0,
			tp,
			tp,
			false,
			false,
			POS_FACEDOWN_DEFENSE
		)
	end
end