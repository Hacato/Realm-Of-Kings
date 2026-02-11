--Qlient Re-Access
--Scripted by: Assistant
local s,id=GetID()
function s.initial_effect(c)
	--Activate: Discard 1 card, then apply 1 of 3 effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0xaa}

--Cost: Discard 1 card
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

--Filters for each effect
--Effect 1: Add up to 2 "Qli" monsters from GY to hand
function s.thfilter(c)
	return c:IsSetCard(0xaa) and c:IsMonster() and c:IsAbleToHand()
end

--Effect 2: Target up to 2 "Qli" cards in Pendulum Zones to Special Summon
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xaa) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.spcheck(tp)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end

--Effect 3: Place up to 2 face-up "Qli" Pendulum Monsters from Extra Deck to Pendulum Zones
function s.penfilter(c)
	return c:IsSetCard(0xaa) and c:IsType(TYPE_PENDULUM) and c:IsMonster() and c:IsFaceup()
end

function s.checkzone(tp)
	local zone=0
	if Duel.CheckLocation(tp,LOCATION_PZONE,0) then zone=zone+1 end
	if Duel.CheckLocation(tp,LOCATION_PZONE,1) then zone=zone+1 end
	return zone
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_PZONE) and s.spfilter(chkc,e,tp) end
	local b1=Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
	local b2=Duel.IsExistingTarget(s.spfilter,tp,LOCATION_PZONE,0,1,nil,e,tp)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local b3=Duel.IsExistingMatchingCard(s.penfilter,tp,LOCATION_EXTRA,0,1,nil)
		and s.checkzone(tp)>0
	if chk==0 then return b1 or b2 or b3 end
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)},
		{b2,aux.Stringid(id,1)},
		{b3,aux.Stringid(id,2)})
	e:SetLabel(op)
	if op==1 then
		--Add from GY
		e:SetCategory(CATEGORY_TOHAND)
		e:SetProperty(0)
		Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
	elseif op==2 then
		--Special Summon from Pendulum Zones
		e:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
		local ct=math.min(ft,2)
		local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_PZONE,0,1,ct,nil,e,tp)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,#g,0,0)
	elseif op==3 then
		--Place from Extra Deck to Pendulum Zones
		e:SetCategory(0)
		e:SetProperty(0)
	end
	--Apply restriction: Cannot Special Summon except "Qli" monsters this turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,3))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.splimit(e,c)
	return not c:IsSetCard(0xaa)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	if op==1 then
		--Effect 1: Add up to 2 "Qli" monsters from GY to hand
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.thfilter),tp,LOCATION_GRAVE,0,1,2,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	elseif op==2 then
		--Effect 2: Special Summon targeted "Qli" cards from Pendulum Zones
		local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS):Filter(Card.IsRelateToEffect,nil,e)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	elseif op==3 then
		--Effect 3: Place up to 2 face-up "Qli" Pendulum Monsters from Extra Deck to Pendulum Zones
		local ft=s.checkzone(tp)
		if ft==0 then return end
		ft=math.min(ft,2)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local g=Duel.SelectMatchingCard(tp,s.penfilter,tp,LOCATION_EXTRA,0,1,ft,nil)
		if #g>0 then
			for tc in aux.Next(g) do
				Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
			end
		end
	end
end