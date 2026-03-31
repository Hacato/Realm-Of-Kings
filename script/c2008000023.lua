--Aramas 8th Coffins' Gambit
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCountLimit(1,id)
	--e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	Duel.AddCustomActivityCounter(id,ACTIVITY_SPSUMMON,aux.FilterBoolFunction(Card.IsSetCard,0x45))
end
s.listed_series={0x45}
s.listed_names={id}
s.roll_dice=true
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)--die roll
	if chk==0 then return Duel.GetCustomActivityCount(id,tp,ACTIVITY_SPSUMMON)==0 end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.sslimit)
	Duel.RegisterEffect(e1,tp)
end
function s.sslimit(e,c)
	return not c.roll_dice and c:IsSetCard(0x45)
end
function s.filter(c)
	return c.roll_dice and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
		return g:GetClassCount(Card.GetCode)>=8
	end
	Duel.SetOperationInfo(0,CATEGORY_DICE,nil,0,tp,1)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_DECK,0,nil)
	if g:GetClassCount(Card.GetCode)>=8 then
	    --1st card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg1=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg1:GetFirst():GetCode())
		--2nd card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg2=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg2:GetFirst():GetCode())
		--3rd card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg3=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg3:GetFirst():GetCode())
		--4th card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg4=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg4:GetFirst():GetCode())
		--5th card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg5=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg5:GetFirst():GetCode())
		--6th card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg6=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg6:GetFirst():GetCode())
		--7th card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg7=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg7:GetFirst():GetCode())
		--8th card
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
		local sg8=g:Select(tp,1,1,nil)
		g:Remove(Card.IsCode,nil,sg8:GetFirst():GetCode())
		--merge chosen cards
		sg1:Merge(sg2)
		sg1:Merge(sg3)
		sg1:Merge(sg4)
		sg1:Merge(sg5)
		sg1:Merge(sg6)
		sg1:Merge(sg7)
		sg1:Merge(sg8)
		Duel.ConfirmCards(1-tp,sg1)
		--shuffle them back
		Duel.ShuffleDeck(tp)
		--------------------
		local dice=Duel.TossDice(tp,1)
		  --add 1 card
		  if dice==1 or dice==2 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		  local tg=sg1:Select(tp,1,1,nil)
		  local tc=tg:GetFirst()
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
			return
		  --add 2 cards
		elseif dice==3 or dice==4 then	
		    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		  local dg=sg1:Select(tp,2,2,nil)
		    Duel.SendtoHand(dg,nil,REASON_EFFECT)
		    Duel.ConfirmCards(1-tp,dg)
          return
		  --add 3 cards
		else
		    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		  local rg=sg1:Select(tp,3,3,nil)
		    Duel.SendtoHand(rg,nil,REASON_EFFECT)
		    Duel.ConfirmCards(1-tp,rg)
	    end
    end
end