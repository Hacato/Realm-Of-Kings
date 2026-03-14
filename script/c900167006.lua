--NSO - Dark Kangel
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    --change name
    local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_CHANGE_CODE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetValue(CODE_KANGEL)
	c:RegisterEffect(e0)
    --spsummon
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e1:SetCode(EFFECT_SPSUMMON_CONDITION)
    c:RegisterEffect(e1)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_FIELD)
    e2:SetCode(EFFECT_SPSUMMON_PROC)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
    e2:SetRange(LOCATION_EXTRA)
    e2:SetCondition(s.sprcon)
    e2:SetTarget(s.sprtg)
    e2:SetOperation(s.sprop)
    c:RegisterEffect(e2)
    --negate
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e3:SetRange(LOCATION_MZONE)
    e3:SetCost(s.discost)
	e3:SetCondition(s.discon)
	e3:SetTarget(s.distg)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
    --self destruction
    local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_SELF_DESTROY)
	e4:SetCondition(s.descon)
	c:RegisterEffect(e4)
end
s.listed_names={CODE_KANGEL,CODE_AMECHAN}
s.listed_series={SET_NSO}
function s.faceup(code)
    return function(c)
        return c:IsFaceup() and c:IsCode(code) and c:IsAbleToRemoveAsCost()
    end
end
function s.extramat(c)
    return c:GetCounter(0x900a)>0
end
function s.sprcon(e,c)
    if c==nil then return true end
    local tp=c:GetControler()
    local rg1=Duel.GetMatchingGroup(s.faceup(CODE_KANGEL),tp,LOCATION_EXTRA,0,nil)
    local rg2=Duel.GetMatchingGroup(s.faceup(CODE_AMECHAN),tp,LOCATION_EXTRA,0,nil)
    local extra=Duel.GetMatchingGroup(s.extramat,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    return #rg1>0 and #rg2>0 or #extra==2
end
function s.sprtg(e,tp,eg,ep,ev,re,r,rp,c)
    local rg1=Duel.GetMatchingGroup(s.faceup(CODE_KANGEL),tp,LOCATION_EXTRA,0,nil)
    local rg2=Duel.GetMatchingGroup(s.faceup(CODE_AMECHAN),tp,LOCATION_EXTRA,0,nil)
    local extra=Duel.GetMatchingGroup(s.extramat,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
    if #extra>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
        local g=extra:Select(tp,2,2,nil)
        g:KeepAlive()
        e:SetLabelObject(g)
        return true
    elseif #rg1>0 and #rg2>0 then
        local g1=rg1:Select(tp,1,1,nil)
        local g2=rg2:Select(tp,1,1,nil)
        g1:Merge(g2)
        g1:KeepAlive()
        e:SetLabelObject(g1)
        return true
    end
    return false
end
function s.sprop(e,tp,eg,ep,ev,re,r,rp,c)
    local g=e:GetLabelObject()
    if not g then return end
    Duel.Remove(g,POS_FACEUP,REASON_COST)
    g:DeleteGroup()
end
function s.discost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
end
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsStatus(STATUS_BATTLE_DESTROYED) and Duel.IsChainNegatable(ev) and rp==1-tp
end
function s.distg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end
function s.descon(e)
	return Duel.GetLP(e:GetHandlerPlayer())<=2000
end