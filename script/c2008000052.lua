--Grapherioleus' Codex
--Scripted by Hatter
local s,id=GetID()
function s.initial_effect(c)
	c:SetUniqueOnField(1,0,id)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Unaffected
	local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.indval)
	c:RegisterEffect(e2)
	--Declare search
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetCountLimit(1)
	e3:SetRange(LOCATION_SZONE)
	e3:SetProperty(EFFECT_FLAG_BOTH_SIDE+EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CARD_TARGET)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end
s.listed_names={id}
function s.indval(e,re)--immune
	return not re:GetHandler():IsCode(8437665)
end
function s.codecheck(c,digit)--search matching card
    local code=c:GetCode()
    return code%10==digit and code//(10^math.floor(math.log(code,10)))==digit
end
function s.filter(c,digit)
    return c:IsAbleToHand() and not c:IsPublic() and s.codecheck(c,digit)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    local choices={}
    for i=1,9 do
        if Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil,i) then 
            table.insert(choices,i)
        end
    end
    if chk==0 then return #choices>0 end
    local digit=Duel.AnnounceNumber(tp,table.unpack(choices))
    Duel.SetTargetParam(digit)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local digit=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
    local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil,digit)
    if #g>0 then
        Duel.ConfirmCards(tp,g)
        Duel.BreakEffect()
        Duel.SendtoHand(g,nil,REASON_EFFECT)
    end
end