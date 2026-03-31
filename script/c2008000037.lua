--Magical Labyrinth Wall
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMING_END_PHASE)
	e1:SetCountLimit(1)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Add 1 "Sanga of the Thunder", "Kazejin", or "Suijin" to the hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_LABYRINTH_WALL}
s.listed_names=CARDS_SANGA_KAZEJIN_SUIJIN--{2008000017,34771947,id}
function s.filter(c)--Send 1 "Wicked Worm Beast of the Labyrinth" from your h/D to the GY
	return c:IsCode(2008000017) and c:IsAbleToGraveAsCost()
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.cfilter(c,tp)--act 1 "Labyrinth Wall Shadow" from your D
	return c:IsCode(34771947) and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_DECK,0,1,nil,tp) end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
	local tc=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	Duel.ActivateFieldSpell(tc,e,tp,eg,ep,ev,re,r,rp)
end
function s.thfilter(c)--Add 1 "Sanga of the Thunder", "Kazejin", or "Suijin" to the hand
	return c:IsCode(CARDS_SANGA_KAZEJIN_SUIJIN) and c:IsAbleToHand() and (c:IsLocation(LOCATION_DECK) or c:IsFaceup())
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK|LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK|LOCATION_REMOVED)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK|LOCATION_REMOVED,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
--function s.thfilter(c,tp)--act/add to your h 1 "Labyrinth Wall Shadow" from your D
--	return c:IsCode(34771947) and (c:IsAbleToHand() or c:GetActivateEffect():IsActivatable(tp,true,true))
--end
--function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
--	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,tp) end
--	if not Duel.CheckPhaseActivity() then Duel.RegisterFlagEffect(tp,CARD_MAGICAL_MIDBREAKER,RESET_CHAIN,0,1) end
--	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
--end
--function s.activate(e,tp,eg,ep,ev,re,r,rp)
--	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
--	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,tp)
--	local tc=g:GetFirst()
--	if tc then
--		local te=tc:GetActivateEffect()
--		local b1=tc:IsAbleToHand()
--		local b2=te:IsActivatable(tp,true,true)
--		if b1 and (not b2 or Duel.SelectYesNo(tp,aux.Stringid(id,3))) then
--			Duel.SendtoHand(tc,nil,REASON_EFFECT)
--			Duel.ConfirmCards(1-tp,tc)
--		else
--			Duel.ActivateFieldSpell(tc,e,tp,eg,ep,ev,re,r,rp)
--		end
--	end
--end