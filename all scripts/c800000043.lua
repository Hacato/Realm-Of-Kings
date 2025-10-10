--It's Hero Time!
--Script by Hacato
local s,id=GetID()
function s.initial_effect(c)
	--Activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	
	--Protect Omni-Heroes from leaving field
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_SEND_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	e2:SetCountLimit(1,id+100)
	c:RegisterEffect(e2)
end

--Filters
function s.thfilter(c)
	return c:IsCode(50000148) and c:IsAbleToHand()
end

function s.setfilter(c)
	return (c:IsCode(50000149) or c:IsCode(60000023)) and not c:IsForbidden()
end

function s.repfilter(c,tp)
	return c:IsSetCard(0x707) and c:IsLocation(LOCATION_MZONE) and c:IsControler(tp)
		and c:IsReason(REASON_BATTLE+REASON_EFFECT) and not c:IsReason(REASON_REPLACE)
end

--Activation target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Activation operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	--Add "The Omni-Kid" to hand
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		
		--If you control no other cards, set Omnimatrix or Ultimatrix
		if Duel.GetFieldGroupCount(tp,LOCATION_ONFIELD,0)==1 then
			local sg=Duel.GetMatchingGroup(s.setfilter,tp,LOCATION_DECK,0,nil)
			if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
				local tc=sg:Select(tp,1,1,nil):GetFirst()
				if tc then
					Duel.SSet(tp,tc)
				end
			end
		end
	end
end

--Replacement effect target
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToRemove() and eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,c,96)
end

--Replacement effect value
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end

--Replacement effect operation
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end