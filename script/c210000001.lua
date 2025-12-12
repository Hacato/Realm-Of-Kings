--Magicians'Sleight of Hand
--Coded by HuascarD
local s,id,o=GetID()
function s.initial_effect(c)
	--search
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,210000001)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--return to gy
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(210000001,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,210000091)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)	
end
s.listed_names={46986414,38033121}
function s.filter(c)
	return (c:ListsCode(c,46986414) or c:ListsCode(c,38033121)) and not c:IsCode(210000001) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,e:GetHandler())
		and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_HAND)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local ct1=Duel.GetMatchingGroupCount(Card.IsAbleToDeck,tp,LOCATION_HAND,0,nil)
	local ct2=Duel.GetMatchingGroupCount(s.filter,tp,LOCATION_DECK,0,nil)
	if ct1>0 and ct2>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,1,math.min(ct1,ct2,2),nil)
		if #g>0 then
			Duel.SendtoDeck(g,tp,SEQ_DECKSHUFFLE,REASON_EFFECT)
			local dg=Duel.GetOperatedGroup():FilterCount(Card.IsLocation,nil,LOCATION_DECK)
			if dg>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local g2=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,dg,dg,nil)
				if #g2>0 then
					Duel.BreakEffect()
					Duel.SendtoHand(g2,nil,REASON_EFFECT)
					Duel.ConfirmCards(1-tp,g2)
				end
			end
		end
	end
end
function s.thfilter(c)
	return c:IsFaceup() and not c:IsCode(210000001) and c:IsAbleToGrave()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_REMOVED,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_REMOVED,0,1,1,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoGrave(tc,REASON_EFFECT+REASON_RETURN)
	end
end