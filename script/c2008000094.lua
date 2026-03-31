--Fortress of the Destined Miracle
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
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_SZONE,0)
	e2:SetTarget(s.imfilter)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)
    --sum/set ms limit
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_SUMMON)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(1,0)
	e3:SetTarget(s.splimit)
	c:RegisterEffect(e3)
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	c:RegisterEffect(e4)
	local e5=e3:Clone()
	e5:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e5)
	local e6=e3:Clone()
	e6:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e6)
	--no bdmg
	local e7=Effect.CreateEffect(c)
	e7:SetType(EFFECT_TYPE_FIELD)
	e7:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e7:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e7:SetRange(LOCATION_SZONE)
	e7:SetTargetRange(LOCATION_MZONE,0)
	e7:SetTarget(s.target)
	e7:SetValue(1)
	c:RegisterEffect(e7)
	--self destroy
	local e8=Effect.CreateEffect(c)
	e8:SetType(EFFECT_TYPE_SINGLE)
	e8:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e8:SetRange(LOCATION_SZONE)
	e8:SetCode(EFFECT_SELF_DESTROY)
	e8:SetCondition(s.sdcon)
	c:RegisterEffect(e8)
end
function s.imfilter(e,c)--immune
	return c:IsSetCard(0x2d5)--c:IsCode(2008000063,2008000064,2008000099,2008000107,2008000094)
end
function s.efilter(e,te)
	return not te:GetOwner():IsSetCard(0x2d5)--IsCode(2008000063,2008000064,2008000099,2008000107,2008000094)
end
function s.splimit(e,c)--You can only Sum/Set "Angel O0,O1,O2,O3,O4,O5,O6,O7", "Tualatin" , or "Trias Hierarchia"
	return not c:IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
end
function s.target(e,c)--no bdmg
	return c:IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
end
function s.sdfilter(c)--self-destroy
	return c:IsSummonLocation(LOCATION_EXTRA)
end
function s.sdcon(e)
	return Duel.IsExistingMatchingCard(s.sdfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end