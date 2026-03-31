--Sanctuary of the Destined Miracle
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
    --immune
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.imfilter)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)
	--no eff dmg
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CHANGE_DAMAGE)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(1,0)
	e3:SetCondition(s.damcon)
	e3:SetValue(s.damval)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_NO_EFFECT_DAMAGE)
	c:RegisterEffect(e4)
    --sum/set ms limit
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD)
	e5:SetCode(EFFECT_CANNOT_SUMMON)
	e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e5:SetRange(LOCATION_FZONE)
	e5:SetTargetRange(1,0)
	e5:SetTarget(s.splimit)
	c:RegisterEffect(e5)
	local e6=e5:Clone()
	e6:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	c:RegisterEffect(e6)
	local e7=e5:Clone()
	e7:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e7)
	local e8=e5:Clone()
	e8:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e8)
	--self destroy
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_SINGLE)
	e9:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e9:SetRange(LOCATION_FZONE)
	e9:SetCode(EFFECT_SELF_DESTROY)
	e9:SetCondition(s.sdcon)
	c:RegisterEffect(e9)
end
function s.imfilter(e,c)--immune
	return c:IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
end
function s.efilter(e,te)
	return not te:GetOwner():IsSetCard(0x2d5)--IsCode(2008000064,2008000094,2008000099,2008000107)
end
function s.cfilter(c)--no eff dmg
	return c:IsFaceup() and c:IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
end
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end
function s.splimit(e,c)--You can only Sum/Set "Angel O0,O1,O2,O3,O4,O5,O6,O7", "Tualatin" , or "Trias Hierarchia"
	return not c:IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
end
function s.sdfilter(c)--self-destroy
	return c:IsSummonLocation(LOCATION_EXTRA)
end
function s.sdcon(e)
	return Duel.IsExistingMatchingCard(s.sdfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end