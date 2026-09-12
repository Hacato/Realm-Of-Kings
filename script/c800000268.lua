--Charco, Evil Lord of Dark World
local s,id=GetID()
function s.initial_effect(c)
	--Discard 1 "Dark World" monster, then Special Summon this card
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_HANDES+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--If discarded: return 1 card to the hand
	--Opponent bonus: Special Summon 1 monster from either GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

s.listed_series={SET_DARK_WORLD}

--==================================================
-- Effect 1
-- Discard another "Dark World", then Special Summon
--==================================================

function s.disfilter(c)
	return c:IsSetCard(SET_DARK_WORLD)
		and not c:IsCode(id)
		and c:IsDiscardable()
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(
				s.disfilter,tp,LOCATION_HAND,0,1,c
			)
	end
	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,c,1,tp,
		c:IsLocation(LOCATION_HAND) and LOCATION_HAND or LOCATION_GRAVE
	)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e)
		or not c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		or Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(
		tp,s.disfilter,tp,LOCATION_HAND,0,1,1,c
	)

	if #g>0 and Duel.SendtoGrave(
		g,REASON_EFFECT+REASON_DISCARD
	)>0 then
		Duel.SpecialSummon(
			c,0,tp,tp,false,false,POS_FACEUP
		)
	end
end

--==================================================
-- Effect 2
-- Dark World discard trigger
--==================================================

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	--Remember Charco's previous controller for
	--the opponent-discard bonus
	e:SetLabel(c:GetPreviousControler())

	return c:IsPreviousLocation(LOCATION_HAND)
		and r&(REASON_DISCARD|REASON_EFFECT)
			==REASON_DISCARD|REASON_EFFECT
end

--Card to return to hand
function s.thfilter(c)
	return c:IsAbleToHand()
end

--Monster in either GY that can be Special Summoned
function s.spfilter(c,e,tp)
	return c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false
		)
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local oppdiscard=
		tp~=rp and tp==e:GetLabel()

	if chkc then
		--Main target: any card on field
		if chkc:IsOnField() then
			return s.thfilter(chkc)
		end

		--Bonus target: monster in either GY
		if oppdiscard
			and chkc:IsLocation(LOCATION_GRAVE) then
			return s.spfilter(chkc,e,tp)
		end

		return false
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.thfilter,tp,
			LOCATION_ONFIELD,LOCATION_ONFIELD,
			1,nil
		)
	end

	--Select the main bounce target
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g1=Duel.SelectTarget(
		tp,s.thfilter,tp,
		LOCATION_ONFIELD,LOCATION_ONFIELD,
		1,1,nil
	)

	Duel.SetOperationInfo(
		0,CATEGORY_TOHAND,g1,1,0,0
	)

	--==================================================
	-- Opponent-discard bonus
	--==================================================

	if oppdiscard
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(
			s.spfilter,tp,
			LOCATION_GRAVE,LOCATION_GRAVE,
			1,nil,e,tp
		)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2))
	then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

		local g2=Duel.SelectTarget(
			tp,s.spfilter,tp,
			LOCATION_GRAVE,LOCATION_GRAVE,
			1,1,nil,e,tp
		)

		e:SetCategory(
			CATEGORY_TOHAND+CATEGORY_SPECIAL_SUMMON
		)

		Duel.SetOperationInfo(
			0,CATEGORY_SPECIAL_SUMMON,
			g2,1,0,LOCATION_GRAVE
		)
	else
		e:SetCategory(CATEGORY_TOHAND)
	end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)

	--Separate field target from GY bonus target
	local tc=g:Filter(Card.IsLocation,nil,LOCATION_ONFIELD):GetFirst()
	local sc=g:Filter(Card.IsLocation,nil,LOCATION_GRAVE):GetFirst()

	--Main Dark World effect
	if tc and tc:IsRelateToEffect(e)
		and tc:IsAbleToHand() then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end

	--Opponent-discard bonus
	if sc and sc:IsRelateToEffect(e)
		and sc:IsLocation(LOCATION_GRAVE)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and sc:IsCanBeSpecialSummoned(
			e,0,tp,false,false
		) then

		Duel.BreakEffect()

		Duel.SpecialSummon(
			sc,0,tp,tp,false,false,POS_FACEUP
		)
	end
end