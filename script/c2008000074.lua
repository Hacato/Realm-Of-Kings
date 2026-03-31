--Skull Archfiend's Lair
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--decrease tribute
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DECREASE_TRIBUTE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_HAND,0)
	e2:SetTarget(aux.TargetBoolFunction(Card.IsCode,CARD_SUMMONED_SKULL))
	e2:SetValue(0x1)
	c:RegisterEffect(e2)
--	--pierce
--	local e3=Effect.CreateEffect(c)
--	e3:SetType(EFFECT_TYPE_SINGLE)
--	e3:SetCode(EFFECT_PIERCE)
--	local e4=Effect.CreateEffect(c)
--	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
--	e4:SetRange(LOCATION_FZONE)
--	e4:SetTargetRange(LOCATION_MZONE,0)
--	e4:SetTarget(s.target)
--	e4:SetLabelObject(e3)
--	c:RegisterEffect(e4)
	--Eff des rep
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_DESTROY_REPLACE)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTarget(s.reptg)
	e5:SetValue(s.repval)
	e5:SetOperation(s.repop)
	c:RegisterEffect(e5)
end
s.listed_series={0x45}
s.listed_names={id,CARD_SUMMONED_SKULL}
function s.filter(c)--Search
	return (c:IsCode(CARD_SUMMONED_SKULL) or (c:ListsCode(CARD_SUMMONED_SKULL) and c:IsMonster())) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
--function s.target(e,c)--pierce
--	return (c:IsCode(CARD_SUMMONED_SKULL) or (c:ListsCode(CARD_SUMMONED_SKULL) and c:IsMonster()))
--end
function s.repfilter(c,tp)--eff des rep
	return c:IsFaceup() and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
		and (c:IsCode(CARD_SUMMONED_SKULL) or (c:ListsCode(CARD_SUMMONED_SKULL) and c:IsMonster())) 
		and not c:IsReason(REASON_REPLACE) and c:IsReason(REASON_EFFECT)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return eg:IsExists(s.repfilter,1,nil,tp) end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.SendtoGrave(e:GetHandler(),REASON_EFFECT|REASON_REPLACE)
end