--Greater Vilepawn Archfiend
local s,id=GetID()
function s.initial_effect(c)
    --link sum
    c:EnableReviveLimit()
	--Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsCode,73219648),1,1)
	Link.AddProcedure(c,s.matfilter,1,1,s.lcheck)
	--maintain
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.mtcon)
	e1:SetOperation(s.mtop)
	c:RegisterEffect(e1)
	--immune
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)
	--negate and destroy
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_SOLVING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
	--no bdmg from direct attacks
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetOperation(s.atkop)
	c:RegisterEffect(e4)
	--cannot be battle target
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e5:SetRange(LOCATION_MZONE)
	e5:SetTargetRange(0,LOCATION_MZONE)
	e5:SetValue(s.atktg)
	c:RegisterEffect(e5)
	--move
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetTarget(s.seqtg)
	e6:SetOperation(s.seqop)
	c:RegisterEffect(e6)
end
s.listed_series={0x45}
s.listed_names={73219648}
s.roll_dice=true
function s.matfilter(c,lc,stype,tp)--link sum
	return c:IsSetCard(0x45,lc,stype,tp) and not c:IsType(TYPE_LINK,lc,stype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSummonCode,1,nil,lc,sumtype,tp,73219648)
end
function s.mtcon(e,tp,eg,ep,ev,re,r,rp)--maintain
	return Duel.GetTurnPlayer()==tp
end
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.CheckLPCost(tp,1000) then
		Duel.PayLPCost(tp,1000)
	else
		Duel.Destroy(e:GetHandler(),REASON_COST)
	end
end
function s.efilter(e,re,rp,c)--immune
	return e:GetHandlerPlayer()~=re:GetOwnerPlayer() and not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)--dice roll
	if ep==tp then return end
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	if not tg or not tg:IsContains(e:GetHandler()) or not Duel.IsChainDisablable(ev) then return false end
	local rc=re:GetHandler()
	local dc=Duel.TossDice(tp,1)
	if dc~=3 and dc~=6 then return end
	if Duel.NegateEffect(ev) and rc:IsRelateToEffect(re) then
		Duel.Destroy(rc,REASON_EFFECT)
	end
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)--no bdmg from direct attacks
	if Duel.GetAttacker():IsControler(1-tp) and not Duel.GetAttackTarget() then Duel.ChangeBattleDamage(tp,0) end
end
function s.atktg(e,c)--opp cannot attack other "Archfiend" ms
	return c:IsFaceup() and c:IsSetCard(0x45) and c:IsRace(RACE_FIEND) and c~=e:GetHandler()
end
function s.seqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)--move
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
end
function s.seqop(e,tp,eg,ep,ev,re,r,rp)
	Duel.MoveSequence(e:GetHandler(),math.log(Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0),2))
end