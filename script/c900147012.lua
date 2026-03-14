--SZS - Shul Shagana Shirabe
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --spsummon
    Symphogear.EffectProcedure(c,id,true,{
        category=CATEGORY_TOHAND,
		type=EFFECT_TYPE_QUICK_O,
		range=LOCATION_HAND,
		code=EVENT_CHAINING,
		property=EFFECT_FLAG_CARD_TARGET,
		cost=s.thcost,
		target=s.thtg,
		operation=s.thop,
    })
end
s.listed_series={SET_SZS}
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDiscardable()
		and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DISCARD)
	local g=Duel.SelectMatchingCard(tp,Card.IsDiscardable,tp,LOCATION_HAND,0,1,1,e:GetHandler())
	g:AddCard(e:GetHandler())
	Duel.SendtoGrave(g,REASON_DISCARD|REASON_COST)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsLocation(LOCATION_MZONE) and chkc:IsAbleToHand() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,Card.IsAbleToHand,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
	local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_SKIP_DP)
    e1:SetTargetRange(1,0)
    e1:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN)
    Duel.RegisterEffect(e1,tp)
    local e2=Effect.CreateEffect(e:GetHandler())
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e2:SetCode(EFFECT_CANNOT_DRAW)
    e2:SetTargetRange(1,0)
    e2:SetReset(RESET_PHASE+PHASE_END+RESET_SELF_TURN)
    Duel.RegisterEffect(e2,tp)
end
Duel.LoadScript("szs-utility.lua")