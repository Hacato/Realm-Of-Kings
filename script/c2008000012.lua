--Ragnaraika Dreadful Bloom
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
    -- Special Summon procedure
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_PROC)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
    e1:SetCondition(s.selfspcon)
    e1:SetTarget(s.selfsptg)
    e1:SetOperation(s.selfspop)
    c:RegisterEffect(e1)
    --Send 1 "Ragnaraika" S/T to GY; return 1 "Ragnaraika" card from banishment to GY
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e2:SetProperty(EFFECT_FLAG_DELAY)
    e2:SetCode(EVENT_SUMMON_SUCCESS)
    e2:SetCountLimit(1,{id,1})
    e2:SetCost(s.gycost)
    e2:SetTarget(s.gytg)
    e2:SetOperation(s.gyop)
    c:RegisterEffect(e2)
    local e3=e2:Clone()
    e3:SetCode(EVENT_SPSUMMON_SUCCESS)
    c:RegisterEffect(e3)
end
s.listed_series={SET_RAGNARAIKA}
s.listed_names={id}
function s.selfspcostfilter(c)--self spsumm
    return c:IsRace(RACE_INSECT|RACE_PLANT|RACE_REPTILE) and c:IsFaceup() and c:IsAbleToExtraAsCost()
end
function s.selfspcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.selfspcostfilter,tp,LOCATION_REMOVED,0,1,nil)
end
function s.selfsptg(e,tp,eg,ep,ev,re,r,rp,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.GetMatchingGroup(s.selfspcostfilter,tp,LOCATION_REMOVED,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.ChkfMMZ(1),1,tp,HINTMSG_TODECK,nil,nil,true)
	if #sg>0 then
		sg:KeepAlive()
		e:SetLabelObject(sg)
		return true
	end
	return false
end
function s.selfspop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	Duel.HintSelection(g,true)
	Duel.SendtoDeck(g,nil,2,REASON_COST)
	g:DeleteGroup()
end
function s.costfilter(c)--return 1 "Ragnaraika" from your banishment to the GY
	return c:IsSetCard(SET_RAGNARAIKA) and c:IsSpellTrap() and c:IsAbleToGraveAsCost()
end
function s.gycost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.rvfilter(c)
    return c:IsSetCard(SET_RAGNARAIKA) and c:IsFaceup()
end
function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.rvfilter,tp,LOCATION_REMOVED,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_REMOVED)
end
function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.rvfilter,tp,LOCATION_REMOVED,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,1,nil)
		Duel.HintSelection(sg)
		Duel.SendtoGrave(sg,REASON_EFFECT+REASON_RETURN)
	end
end