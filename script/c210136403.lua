--Amazoness Beast Rider
local s,id=GetID()
function s.initial_effect(c)
	--fusion materials
	Fusion.AddProcMix(c,true,true,s.mfilter1,s.mfilter2)
	c:EnableReviveLimit()
    --Destroy
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.descon)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
    --Change original ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.atkcon)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
    --Immune
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
    e3:SetCondition(s.immcon)
	e3:SetValue(s.immval)
	c:RegisterEffect(e3)
    --Multiple attacks
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_EXTRA_ATTACK)
	e4:SetCondition(s.atkcon)
	e4:SetValue(s.value)
	c:RegisterEffect(e4)
end
s.material_setcode=0x4
s.listed_series={0x4}
--fusion materials
function s.mfilter1(c,fc,sumtype,tp)
	return c:IsSetCard(0x4,fc,sumtype,tp) and c:IsRace(RACE_WARRIOR)
end
function s.mfilter2(c,fc,sumtype,tp)
	return c:IsRace(RACE_BEAST,fc,sumtype,tp) and c:IsLevelBelow(8)
end

--Destroy
function s.mfilter(c)
	return c:IsLevelAbove(7)
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local mg=e:GetHandler():GetMaterial()
	return mg and e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) and mg:IsExists(s.mfilter,1,nil)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--Change original ATK
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetMaterial()
	local val=0
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		local a=tc:GetOriginalLevel()
		if a<0 then a=0 end
		val=val+a
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SET_BASE_ATTACK)
	e1:SetValue(val*400)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
	c:RegisterEffect(e1)
end

--Immune
function s.immcon(e)
    local ph=Duel.GetCurrentPhase()
    return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end
function s.immval(e,te)
	return te:GetOwnerPlayer()~=e:GetHandlerPlayer() and te:IsActivated()
end

--Multiple attacks
function s.valfilter(c)
    return c:GetPreviousSetCard()==0x4 and c:GetPreviousLocation()==LOCATION_MZONE
end
function s.value(e,c)
	local g=e:GetHandler():GetMaterial()
	local ct=g:FilterCount(s.valfilter,nil)
	return math.max(0,ct)
end