--Metarion Geniustar
local s,id=GetID()
local CARD_IMAGINARY_ACTOR=800000205
local CARD_ATTRACTION_GOLEM=800000219
local SET_IMAGINARY_ARC=0x79b
local SET_METARION=0x80b

function s.initial_effect(c)
	c:EnableReviveLimit()

	--Fusion Materials
	Fusion.AddProcMix(c,true,true,CARD_IMAGINARY_ACTOR,s.rockfilter)

	--This card's Type is also always treated as Rock
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_RACE)
	e0:SetValue(RACE_ROCK)
	c:RegisterEffect(e0)

	--If Fusion Summoned using "Attraction Golem": banish 1 Rock monster opponent controls
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.rmcon)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	--Shuffle from GY and draw
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)

	--Sent to GY by opponent's card or battle
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,{id,3})
	e3:SetCondition(s.thcon)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

s.listed_names={CARD_IMAGINARY_ACTOR,CARD_ATTRACTION_GOLEM}
s.listed_series={SET_IMAGINARY_ARC,SET_METARION}

function s.rockfilter(c,fc,sumtype,tp)
	return c:IsRace(RACE_ROCK,fc,sumtype,tp)
end

--Check Attraction Golem material
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsFusionSummoned() then return false end
	local mg=c:GetMaterial()
	return mg and mg:IsExists(Card.IsCode,1,nil,CARD_ATTRACTION_GOLEM)
end

function s.rmfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_ROCK) and c:IsAbleToRemove()
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.rmfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.rmfilter,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	Duel.SelectTarget(tp,s.rmfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_MZONE)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
	end
end

--Quick condition
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()==tp then return true end
	return Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_GRAVE,0,1,nil,CARD_IMAGINARY_ACTOR)
end

function s.drfilter(c)
	return (c:IsSetCard(SET_IMAGINARY_ARC) or c:IsSetCard(SET_METARION))
		and c:IsAbleToDeck()
end

function s.metfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_METARION)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(s.metfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then
		return ct>0
			and Duel.IsPlayerCanDraw(tp,1)
			and Duel.IsExistingMatchingCard(s.drfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,ct,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,0)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(s.metfilter,tp,LOCATION_MZONE,0,nil)
	if ct<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.drfilter,tp,LOCATION_GRAVE,0,1,ct,nil)
	local sh=Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)

	local draw=math.floor(sh/2)
	if draw>0 then
		Duel.Draw(tp,draw,REASON_EFFECT)
	end
end

--Trigger condition (battle OR opponent effect)
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsPreviousControler(tp)
		and (
			(c:IsReason(REASON_EFFECT) and rp==1-tp)
			or c:IsReason(REASON_BATTLE)
		)
end

function s.thfilter(c)
	return c:IsRace(RACE_ROCK) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_GRAVE)
			and s.thfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.thfilter,tp,
			LOCATION_GRAVE,LOCATION_GRAVE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	Duel.SelectTarget(tp,s.thfilter,tp,
		LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,PLAYER_ALL,LOCATION_GRAVE)
end

--FINAL FIX: add to activating player's hand
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,tp,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end