--Shake Your Tail
local s,id=GetID()
function s.initial_effect(c)
	--Reflect damage and gain LP if "Ponygirl - Sunset Shimmer" is on field
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DAMAGE+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
s.listed_names={50000439} --Assuming this is "Ponygirl - Sunset Shimmer"
function s.sunsetfilter(c)
	return c:IsCode(50000439) and c:IsFaceup() --"Ponygirl - Sunset Shimmer"
end
function s.ponygirlfilter(c)
	return c:IsSetCard(0x713) and c:IsFaceup() --"Ponygirl" archetype
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	if rp==tp then return false end
	if not Duel.IsExistingMatchingCard(s.ponygirlfilter,tp,LOCATION_MZONE,0,1,nil) then return false end
	
	local ex1,cg1,ct1,cp1,cv1=Duel.GetOperationInfo(ev,CATEGORY_DAMAGE)
	if ex1 and (cp1==tp or cp1==PLAYER_ALL) then 
		e:SetLabel(cv1 or 0) -- Ensure we have an integer value (default to 0)
		return true
	end
	return false
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local dam=e:GetLabel()
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(dam)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,dam)
	if Duel.IsExistingMatchingCard(s.sunsetfilter,tp,LOCATION_MZONE,0,1,nil) then
		Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,dam)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local dam=e:GetLabel()
	if dam and dam>0 then -- Ensure dam is not nil
		local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
		if Duel.Damage(p,dam,REASON_EFFECT)>0 and Duel.IsExistingMatchingCard(s.sunsetfilter,tp,LOCATION_MZONE,0,1,nil) then
			Duel.Recover(tp,dam,REASON_EFFECT)
		end
	end
end