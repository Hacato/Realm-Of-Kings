--Blade of the Destined Miracle
local s,id=GetID()
function s.initial_effect(c)
	aux.AddEquipProcedure(c,nil,aux.FilterBoolFunction(Card.IsCode,2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984))
	--atk/def
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_EQUIP)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	e3:SetValue(s.defval)
	c:RegisterEffect(e3)
	--direct attack
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_SZONE)
	e4:SetCountLimit(1)
	e4:SetOperation(s.daop)
	c:RegisterEffect(e4)
	--ATK/DEF value
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)--EFFECT_TYPE_EQUIP)
	e5:SetCode(EFFECT_SET_ATTACK_FINAL)
	e5:SetTargetRange(0,LOCATION_MZONE)
	e5:SetCondition(s.basecon)
	e5:SetTarget(s.basetg)
	e5:SetValue(s.batkval)--baseval
	c:RegisterEffect(e5)
--	local e6=e5:Clone()
--	e6:SetCode(EFFECT_SET_DEFENSE_FINAL)
--	e6:SetValue(s.bdefval)
--	c:RegisterEffect(e6)
	--sum/set ms limit
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_CANNOT_SUMMON)
	e7:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e7:SetRange(LOCATION_FZONE)
	e7:SetTargetRange(1,0)
	e7:SetTarget(s.splimit)
	c:RegisterEffect(e7)
	local e8=e7:Clone()
	e8:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	c:RegisterEffect(e8)
	local e9=e7:Clone()
	e9:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e9)
	local e10=e7:Clone()
	e10:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e10)
	--self destroy
	local e11=Effect.CreateEffect(c)
	e11:SetType(EFFECT_TYPE_SINGLE)
	e11:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e11:SetRange(LOCATION_FZONE)
	e11:SetCode(EFFECT_SELF_DESTROY)
	e11:SetCondition(s.sdcon)
	c:RegisterEffect(e11)
end
function s.atkval(e,c)--gain atk/def
	return c:GetBaseDefense()
end
function s.defval(e,c)
    return c:GetBaseAttack()
end
function s.daop(e,tp,eg,ep,ev,re,r,rp)--direct atk
	local eq=e:GetHandler():GetEquipTarget()
	local c=e:GetHandler()
	if eq:IsFaceup() and c:IsFaceup() then
	    local e1=Effect.CreateEffect(e:GetHandler())
	    e1:SetType(EFFECT_TYPE_SINGLE)
	    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_OATH)
	    e1:SetCode(EFFECT_SET_ATTACK_FINAL)
	    e1:SetValue(eq:GetAttack()/2)
	    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	    eq:RegisterEffect(e1)
	    local e2=Effect.CreateEffect(e:GetHandler())
	    e2:SetType(EFFECT_TYPE_SINGLE)
	    e2:SetProperty(EFFECT_CANNOT_DISABLE)
	    e2:SetCode(EFFECT_DIRECT_ATTACK)
	    e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	    eq:RegisterEffect(e2)
    end
end
function s.basecon(e,tp,eg,ep,ev,re,r,rp)--ATK/DEF value
	local ph=Duel.GetCurrentPhase()
	return e:GetHandler():IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
	and (ph==PHASE_DAMAGE or ph==PHASE_DAMAGE_CAL) and Duel.GetAttackTarget()~=nil and (Duel.GetAttacker()==e:GetHandler() or Duel.GetAttackTarget()==e:GetHandler())
end
function s.basetg(e,c)
	return c==e:GetHandler():GetBattleTarget()
end
function s.batkval(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler():GetBattleTarget()
	return c:GetBaseAttack()
end
--function s.bdefval(e,tp,eg,ep,ev,re,r,rp)
--	local c=e:GetHandler():GetBattleTarget()
--	return c:GetBaseDefense()
--end
function s.splimit(e,c)--You can only Sum/Set "Angel O0,O1,O2,O3,O4,O5,O6,O7", "Tualatin", or "Trias Hierarchia"
	return not c:IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
end
function s.sdfilter(c)--self-destroy
	return c:IsSummonLocation(LOCATION_EXTRA)
end
function s.sdcon(e)
	return Duel.IsExistingMatchingCard(s.sdfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end