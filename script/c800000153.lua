--Pursuer of Justice – Cormag the Righteous Wyvernrider
local s,id=GetID()
function s.initial_effect(c)
	--While you control this card: you cannot Special Summon, except "Pursuer of Justice" monsters (cannot be negated)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e0:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetTargetRange(1,0)
	e0:SetTarget(s.splimit)
	c:RegisterEffect(e0)

	--Special Summon this card from hand or GY if you control a Level 6 "Pursuer of Justice" monster
	--You can only Special Summon 1 "Pursuer of Justice – Cormag the Righteous Wyvernrider" per turn this way
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--Other "Pursuer of Justice" monsters you control cannot be targeted by opponent's card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e2:SetProperty(EFFECT_FLAG_IGNORE_IMMUNE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.tgtg)
	e2:SetValue(aux.tgoval)
	c:RegisterEffect(e2)
end

--Special Summon restriction
function s.splimit(e,c)
	return not c:IsSetCard(0x816)
end

--Check for Level 6 "Pursuer of Justice" monster
function s.lv6filter(c)
	return c:IsSetCard(0x816) and c:IsLevel(6)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.lv6filter,tp,LOCATION_MZONE,0,1,nil)
end

--Target protection (ONLY excludes this specific instance)
function s.tgtg(e,c)
	return c:IsSetCard(0x816) and c~=e:GetHandler()
end
