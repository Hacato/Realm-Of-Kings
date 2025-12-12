--Mastery of the Monado Arts
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	
	--Only control 1
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetCondition(s.uniquecon)
	c:RegisterEffect(e2)
	
	--Draw by shuffling "Monado" Spells from hand
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.drtg1)
	e3:SetOperation(s.drop1)
	c:RegisterEffect(e3)
	
	--Draw by banishing "Monado" Spells from GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_REMOVE+CATEGORY_DRAW)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1,id)
	e4:SetTarget(s.drtg2)
	e4:SetOperation(s.drop2)
	c:RegisterEffect(e4)
	
	--Only use 1 effect per turn
	aux.GlobalCheck(s,function()
		local ge1=Effect.CreateEffect(c)
		ge1:SetType(EFFECT_TYPE_FIELD)
		ge1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		ge1:SetTargetRange(1,1)
		ge1:SetCode(EFFECT_CANNOT_ACTIVATE)
		ge1:SetValue(s.actlimit)
		Duel.RegisterEffect(ge1,0)
	end)
end

s.listed_names={50000425}
s.listed_series={0x712} --"Monado" archetype ID (placeholder)

--Check if already controlling a copy
function s.uniquecon(e)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,id),e:GetHandlerPlayer(),LOCATION_ONFIELD,0,1,e:GetHandler())
end

--Filter for "Monado" Spells in hand
function s.tdfilter(c)
	return c:IsSpell() and c:IsSetCard(0x712) and c:IsAbleToDeck()
end

--Target for the first effect (shuffle from hand)
function s.drtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_HAND,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

--Operation for the first effect (shuffle from hand)
function s.drop1(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	
	--Activated effect flag
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	
	--Select cards to shuffle
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_HAND,0,1,99,nil)
	
	if #g>0 then
		--Reveal selected cards
		Duel.ConfirmCards(1-tp,g)
		
		--Shuffle them into deck and draw
		local ct=Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		if ct>0 then
			Duel.ShuffleDeck(tp)
			Duel.BreakEffect()
			Duel.Draw(tp,ct,REASON_EFFECT)
		end
	end
end

--Filter for "Monado" Spells in GY except "Monado Sword"
function s.rmfilter(c)
	return c:IsSpell() and c:IsSetCard(0x712) and c:IsAbleToRemove() and not c:IsCode(50000425)
end

--Target for the second effect (banish from GY)
function s.drtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.rmfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

--Operation for the second effect (banish from GY)
function s.drop2(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	
	--Activated effect flag
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	
	--Select cards to banish
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.rmfilter,tp,LOCATION_GRAVE,0,1,99,nil)
	
	if #g>0 then
		--Banish them and draw
		local ct=Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
		if ct>0 then
			Duel.BreakEffect()
			Duel.Draw(tp,ct,REASON_EFFECT)
		end
	end
end

--Global check to ensure only 1 effect per turn
function s.actlimit(e,re,tp)
	return re:GetHandler():IsCode(id) and Duel.GetFlagEffect(tp,id)>0
end