--Yoshiie Vanguard – Masamune
--Created by Hacato
local s,id=GetID()
function s.initial_effect(c)
	--Cannot be destroyed by battle once per turn if you control another "Yoshiie" monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.indcon)
	e1:SetValue(s.indval)
	c:RegisterEffect(e1)
	
	--Send 1 "Yoshiie" Spell/Trap from Deck to GY, then add 1 different "Yoshiie" card from GY to hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

--Indestructible condition: control another "Yoshiie" monster
function s.indfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x2408) and not c:IsCode(id)
end
function s.indcon(e)
	return Duel.IsExistingMatchingCard(s.indfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,e:GetHandler())
end
function s.indval(e,re,r,rp)
	return (r&REASON_BATTLE)~=0
end

--Filter for "Yoshiie" Spell/Trap in Deck
function s.tgfilter(c)
	return c:IsSetCard(0x2408) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToGrave()
end
--Filter for different "Yoshiie" card in GY
function s.thfilter(c,code)
	return c:IsSetCard(0x2408) and not c:IsCode(code) and c:IsAbleToHand()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g1>0 then
		local tc=g1:GetFirst()
		if Duel.SendtoGrave(tc,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_GRAVE) then
			local g2=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_GRAVE,0,nil,tc:GetCode())
			if #g2>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local sg=g2:Select(tp,1,1,nil)
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
			end
		end
	end
end