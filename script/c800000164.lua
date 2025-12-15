--The Sacred Stone of Frelia
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x816}
function s.lkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x816) and c:IsType(TYPE_LINK)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.lkfilter(chkc)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.lkfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.lkfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	
	-- Treat Link Rating as Level
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_LEVEL)
	e1:SetValue(tc:GetLink())
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
	
	-- Can be treated as Level 3 or 6 for Xyz Summon of "Pursuer of Justice" monsters
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_XYZ_LEVEL)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(function(e,c,rc)
		if not rc or not rc:IsSetCard(0x816) then return 0 end
		return 0x30006 -- Both Level 3 and Level 6
	end)
	e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e2)
	
	-- Can be used as Xyz Material for Rank 3 or 6 "Pursuer of Justice" monsters
	local e2b=Effect.CreateEffect(e:GetHandler())
	e2b:SetType(EFFECT_TYPE_SINGLE)
	e2b:SetCode(EFFECT_XYZ_MATERIAL)
	e2b:SetValue(s.xyzval)
	e2b:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e2b)
	
	-- Can be treated as Level 3 or 6 for Synchro Summon of "Pursuer of Justice" monsters
	local e3=Effect.CreateEffect(e:GetHandler())
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_SYNCHRO_LEVEL)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(function(e,c)
		if not c or not c:IsSetCard(0x816) then return 0 end
		return 0x30006 -- Both Level 3 and Level 6
	end)
	e3:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e3)
	
	-- Can be treated as Level 3 or 6 for Ritual Summon of "Pursuer of Justice" monsters
	local e4=Effect.CreateEffect(e:GetHandler())
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_RITUAL_LEVEL)
	e4:SetValue(function(e,c)
		if not c or not c:IsSetCard(0x816) then return e:GetHandler():GetLevel() end
		return 0x30006 -- Both Level 3 and Level 6
	end)
	e4:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e4)
	
	-- Restrict usage to "Pursuer of Justice" Ritual/Synchro/Xyz only
	local e5=Effect.CreateEffect(e:GetHandler())
	e5:SetType(EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_CANNOT_BE_MATERIAL)
	e5:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e5:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	e5:SetValue(s.matlimit)
	tc:RegisterEffect(e5)
end
function s.matlimit(e,c)
	if not c then return false end
	return not (c:IsSetCard(0x816) and (c:IsType(TYPE_RITUAL) or c:IsType(TYPE_SYNCHRO) or c:IsType(TYPE_XYZ)))
end
function s.xyzval(e,c)
	if not c or not c:IsSetCard(0x816) then return false end
	return c:IsRank(3) or c:IsRank(6)
end