--Ragnaraika Sky Punisher
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
    --Special Summon procedure
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
    --Negate and banish effect
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
    e2:SetCode(EVENT_CHAINING)
    e2:SetRange(LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.negcon)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.negtg)
    e2:SetOperation(s.negop)
    c:RegisterEffect(e2)
    aux.DoubleSnareValidity(c,LOCATION_MZONE)
end
s.listed_series={SET_RAGNARAIKA}
s.listed_names={id}
function s.selfspcostfilter(c)--self spsumm
    return c:IsRace(RACE_INSECT|RACE_PLANT|RACE_REPTILE) and c:IsAbleToRemoveAsCost()
end
function s.selfspcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.selfspcostfilter,tp,LOCATION_EXTRA,0,1,nil)
end
function s.selfsptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.GetMatchingGroup(s.selfspcostfilter,tp,LOCATION_EXTRA,0,nil,tp)
	local rg=aux.SelectUnselectGroup(g,e,tp,1,1,aux.ChkfMMZ(1),1,tp,HINTMSG_REMOVE,nil,nil,true)
	if #rg>0 then
		rg:KeepAlive()
		e:SetLabelObject(rg)
		return true
	end
	return false
end
function s.selfspop(e,tp,eg,ep,ev,re,r,rp,c)
	local rg=e:GetLabelObject()
	if not rg then return end
	Duel.Remove(rg,POS_FACEUP,REASON_COST)
	rg:DeleteGroup()
end
function s.linkfilter(c)--negate
    return c:IsFaceup() and c:IsSetCard(SET_RAGNARAIKA) and c:IsType(TYPE_LINK)
end
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
    return rp==1-tp and Duel.IsTurnPlayer(tp) and Duel.IsExistingMatchingCard(s.linkfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	local relation=rc:IsRelateToEffect(re)
	if chk==0 then return rc:IsAbleToRemove(tp)
		or (not relation and Duel.IsPlayerCanRemove(tp)) end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
	if relation then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,rc,1,rc:GetControler(),rc:GetLocation())
	else
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,0,0,rc:GetPreviousLocation())
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
    if Duel.NegateEffect(ev) and re:GetHandler():IsRelateToEffect(re) then
        Duel.Remove(eg,POS_FACEDOWN,REASON_EFFECT)
    end
end