--Tragedy of the Dark Scorpions
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
    --ATK up
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.atkcon)
    e2:SetCost(aux.bfgcost)
    e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end
s.listed_names={76922029,74153887}
s.listed_series={0x1a}
function s.cfilter(c)
	return c:IsSetCard(0x1a) and c:IsAbleToGraveAsCost()
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SendtoGrave(g,REASON_COST)
    e:SetLabelObject(g:GetFirst())
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
        local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
        return #g>0
    end
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
    if e:GetLabelObject():IsCode(74153887) and e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		Duel.SetChainLimit(s.chainlm)
	end
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	Duel.Destroy(g,REASON_EFFECT)
end
function s.chainlm(e,rp,tp)
	return tp==rp
end

function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local b=Duel.GetAttackTarget()
	if a:IsControler(1-tp) then a,b=b,a end
	return a and b and a~=e:GetHandler() and a:IsControler(tp) and a:IsFaceup()
		and a:IsCode(76922029) and b:IsFaceup() and b:IsControler(1-tp)
end
function s.vfilter(c)
	return c:IsSetCard(0x1a) and (c:IsFaceup() or c:IsLocation(LOCATION_GRAVE))
end
function s.atkfilter(c)
    return c:IsMonster() and c:IsSetCard(0x1a)
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.vfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil) end
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp,chk)
	local a=Duel.GetAttacker()
	local b=Duel.GetAttackTarget()
	if a:IsControler(1-tp) then a,b=b,a end
	if a and b and b:IsRelateToBattle() and b:IsFaceup() and b:IsControler(1-tp) then
		-- Update ATK
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_UPDATE_ATTACK)
		e2:SetValue(s.atkval)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		a:RegisterEffect(e2)
	end
end
function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(s.atkfilter,e:GetHandlerPlayer(),LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	for tc in aux.Next(g) do
		if g:IsExists(Card.IsCode,2,nil,tc:GetCode()) then
			g:RemoveCard(tc)
		end
		return g:GetSum(Card.GetBaseAttack)
	end
end