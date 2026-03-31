--Vampire Angel
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--sp summ from h/GY
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.hspcon)
	e1:SetOperation(s.hspop)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--double mat
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(511001225)
	e2:SetOperation(s.tgval1)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	--can be treated as a Level 5 or 8 m
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_XYZ_LEVEL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.xyzlv)
	c:RegisterEffect(e3)
end
s.listed_names={id}
function s.hspcon(e,c)--sp s from h/GY
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.CheckLPCost(tp,2000)
end
function s.hspop(e,tp,eg,ep,ev,re,r,rp,c)
    local c=e:GetHandler()
	Duel.PayLPCost(tp,2000)
	--Cannot Sp Summ from the ExD, except Zombies
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return not c:IsRace(RACE_ZOMBIE) and c:IsLocation(LOCATION_EXTRA) end)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.tgval1(e,c)--double mat
	return c:IsRace(RACE_ZOMBIE)
end
function s.xyzlv(e,c,rc)--can be treated as a Level 5 or 8 m
	local lv=e:GetHandler():GetLevel()
	if rc:IsRace(RACE_ZOMBIE) then
		return 5,8,lv
	else
		return lv
	end
end