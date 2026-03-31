--Number C20: Omega Radiant
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon procedure
	Xyz.AddProcedure(c,nil,4,3)
	--immune to other ms' effs
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
	--battle indes
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
	e2:SetCountLimit(1)
	e2:SetValue(s.valcon)
	c:RegisterEffect(e2)
	--act by tg 1 other face-up m with this eff
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,0,EFFECT_COUNT_CODE_SINGLE)
	e3:SetCondition(s.condition)
	e3:SetCost(s.cost)
	e3:SetTarget(s.target)
	e3:SetOperation(s.operation)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	c:RegisterEffect(e3,false,REGISTER_FLAG_DETACH_XMAT)
	--act by tg this m with its own eff
	local e4=e3:Clone()
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetTarget(s.selftg)
	e4:SetOperation(s.selfop)
	c:RegisterEffect(e4)
end
s.listed_names={47805931}
s.xyz_number=20
function s.efilter(e,te)--immune to other ms' effs
	return te:IsActiveType(TYPE_MONSTER) and te:GetOwner()~=e:GetOwner()
end
function s.valcon(e,re,r,rp)--battle indes
	return (r&REASON_BATTLE)~=0
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)--act by tg 1 other face-up m with this eff
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,47805931)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)--act by tg 1 other face-up m with this eff
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.filter(c)
	return c:IsFaceup() and c:IsMonster()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.filter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_MZONE,LOCATION_MZONE,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.setfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,e:GetHandler())
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsFaceup() and tc:IsRelateToEffect(e) then
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		--Negate its effects
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)--RESET_PHASE+PHASE_END,2
		e2:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e2)
		--Cannot be Tributed
		local e3=Effect.CreateEffect(c)
		e3:SetDescription(3303)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e3:SetRange(LOCATION_MZONE)
		e3:SetCode(EFFECT_UNRELEASABLE_SUM)
		e3:SetValue(1)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e3,true)
		local e4=e3:Clone()
		e4:SetCode(EFFECT_UNRELEASABLE_NONSUM)
		tc:RegisterEffect(e4,true)
		--Cannot be used as mat for a Fus/Syn/Xyz/Link Summ
		local e5=Effect.CreateEffect(c)
		e5:SetDescription(aux.Stringid(id,2))
		e5:SetType(EFFECT_TYPE_SINGLE)
		e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CLIENT_HINT)
		e5:SetCode(EFFECT_CANNOT_BE_MATERIAL)
		e5:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,SUMMON_TYPE_XYZ,SUMMON_TYPE_LINK))
		e5:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e5)
	end
end
function s.cfilter(c,e)
	return c==e:GetHandler()
end
function s.selftg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.cfilter(chkc,e) end
	if chk==0 then return Duel.IsExistingTarget(s.cfilter,tp,LOCATION_MZONE,0,1,nil,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.cfilter,tp,LOCATION_MZONE,0,1,1,nil,e)
end
function s.selfop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsFaceup() and tc:IsRelateToEffect(e) then
	    --Increase ATK/DEF
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(600)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_UPDATE_DEFENSE)
		tc:RegisterEffect(e2)
		--Cannot be Tributed
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetDescription(3303)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e3:SetRange(LOCATION_MZONE)
		e3:SetCode(EFFECT_UNRELEASABLE_SUM)
		e3:SetValue(1)
		e3:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e3,true)
		local e4=e3:Clone()
		e4:SetCode(EFFECT_UNRELEASABLE_NONSUM)
		tc:RegisterEffect(e4,true)
		--Cannot be used as mat for a Fus/Syn/Xyz/Link Summ
		local e5=Effect.CreateEffect(e:GetHandler())
		e5:SetDescription(aux.Stringid(id,2))
		e5:SetType(EFFECT_TYPE_SINGLE)
		e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_CLIENT_HINT)
		e5:SetCode(EFFECT_CANNOT_BE_MATERIAL)
		e5:SetValue(aux.cannotmatfilter(SUMMON_TYPE_FUSION,SUMMON_TYPE_SYNCHRO,SUMMON_TYPE_XYZ,SUMMON_TYPE_LINK))
		e5:SetReset(RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,2)
		tc:RegisterEffect(e5)
	end
end