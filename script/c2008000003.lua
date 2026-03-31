--Number C51: Cataclysmal the Unmatched Might
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--Xyz summon procedure
	Xyz.AddProcedure(c,nil,4,4)
	c:EnableReviveLimit()
	--Unaffected by S/T
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetCondition(s.immcon)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
	--battle indestructable
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	--Absolute Cataclysm
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_DISABLE+CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e3:SetCondition(s.excond)
	e3:SetCost(s.excost)
	e3:SetTarget(s.extg)
	e3:SetOperation(s.exop)
	c:RegisterEffect(e3)
end
s.listed_names={id,56292140}
s.xyz_number=51
function s.immcon(e)--S/T immunity
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.efilter(e,te)
	return te:IsActiveType(TYPE_SPELL+TYPE_TRAP)
end
function s.excond(e,tp,eg,ep,ev,re,r,rp)--Absolute Cataclysm
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,56292140)
end
function s.excost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=e:GetHandler():GetOverlayCount()
	if chk==0 then return ct>0 and e:GetHandler():CheckRemoveOverlayCard(tp,ct,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,ct,ct,REASON_COST)
	Duel.PayLPCost(tp,math.floor(Duel.GetLP(tp)/2))
	--your other ms cannot attack the turn you act Cataclysm
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_ATTACK)
	e1:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE+EFFECT_FLAG_OATH)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.ftarget)
	e1:SetLabel(e:GetHandler():GetFieldID())
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetReset(RESET_PHASE+PHASE_END)
	e2:SetTargetRange(1,0)
	Duel.RegisterEffect(e2,tp)
end
function s.ftarget(e,c)
	return e:GetLabel()~=c:GetFieldID()
end
function s.negfilter(c)
	return c:IsFaceup() and not c:IsDisabled()
end
function s.extg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
  local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(s.filter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.exop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--negate the effs of all other face-up cs on the field
	local dg=Duel.GetMatchingGroup(s.negfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
	local oc=dg:GetFirst()
	for oc in aux.Next(dg) do
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		oc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		oc:RegisterEffect(e2)
	end
		Duel.BreakEffect()
		--des all other cs on the field
		local tc=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,c)
		    Duel.Destroy(tc,REASON_EFFECT)
		    --modify the ATK of Cataclysmal
		    if c:IsFaceup() and c:IsRelateToEffect(e) then
			Duel.BreakEffect()
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_SET_ATTACK_FINAL)
			e3:SetValue(9300)
			e3:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE+RESET_PHASE+PHASE_END)
			c:RegisterEffect(e3)
			--neither player can act the effs of cs des by this eff
			local og=Duel.GetOperatedGroup()
		    local dc=og:GetFirst()
			while dc do
			local e4=Effect.CreateEffect(e:GetHandler())
				e4:SetType(EFFECT_TYPE_SINGLE)
				e4:SetProperty(EFFECT_FLAG_OWNER_RELATE)
				e4:SetCode(EFFECT_CANNOT_TRIGGER)
				e4:SetReset(RESET_EVENT+RESETS_STANDARD)
				e4:SetValue(1)
				dc:RegisterEffect(e4)
				local e5=e4:Clone()
				e5:SetCode(EFFECT_CANNOT_ACTIVATE)
				dc:RegisterEffect(e5)
				dc=og:GetNext()
			end
		--effs of cs with the same name as those des cannot be act
		local e6=Effect.CreateEffect(e:GetHandler())
		e6:SetType(EFFECT_TYPE_FIELD)
		e6:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e6:SetCode(EFFECT_CANNOT_ACTIVATE)
		e6:SetTargetRange(1,1)
		e6:SetValue(s.aclimit)
		e6:SetLabel(table.unpack(og:GetClass(Card.GetCode)))
		e6:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e6,tp)
	end
end
function s.aclimit(e,re,tp)
	return re:GetHandler():IsCode(e:GetLabel())
end