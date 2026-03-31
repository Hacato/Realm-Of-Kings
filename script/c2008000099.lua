--Tower of the Destined Miracle
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--mat limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e2:SetRange(LOCATION_SZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.etg)
	--e2:SetLabelObject(e2)--e1
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e3)
	local e4=e2:Clone()
	e4:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e4)
	local e5=e2:Clone()
	e5:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e5)
	--control
	local e6=e2:Clone()
	e6:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	c:RegisterEffect(e6)
	--tribute limit
	--local e7=e2:Clone()
	--e7:SetCode(EFFECT_UNRELEASABLE_SUM)
	--c:RegisterEffect(e7)
	--e8 tribute by eff limit
	--destroy replace
	local e9=Effect.CreateEffect(c)
	e9:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e9:SetCode(EFFECT_DESTROY_REPLACE)
	e9:SetRange(LOCATION_SZONE)
	e9:SetTarget(s.reptg)
	e9:SetValue(s.repval)
	e9:SetOperation(s.repop)
	c:RegisterEffect(e9)
	--sum/set ms limit
	local e10=Effect.CreateEffect(c)
	e10:SetType(EFFECT_TYPE_FIELD)
	e10:SetCode(EFFECT_CANNOT_SUMMON)
	e10:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e10:SetRange(LOCATION_FZONE)
	e10:SetTargetRange(1,0)
	e10:SetTarget(s.splimit)
	c:RegisterEffect(e10)
	local e11=e10:Clone()
	e11:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	c:RegisterEffect(e11)
	local e12=e10:Clone()
	e12:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
	c:RegisterEffect(e12)
	local e13=e10:Clone()
	e13:SetCode(EFFECT_CANNOT_MSET)
	c:RegisterEffect(e13)
	--self destroy
	local e14=Effect.CreateEffect(c)
	e14:SetType(EFFECT_TYPE_SINGLE)
	e14:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e14:SetRange(LOCATION_SZONE)
	e14:SetCode(EFFECT_SELF_DESTROY)
	e14:SetCondition(s.sdcon)
	c:RegisterEffect(e14)
end
function s.etg(e,c)--cannot be mat+control+unreleasable
	return c:IsFaceup() and c:IsCode(2008000092,82243738,2008000071,2008000076,2008000085,2008000088,2008000089,56784842,27769400,26866984)
end
function s.repfilter(c,tp)--destroy replace
	return c:IsControler(tp) and not c:IsReason(REASON_REPLACE)
		and (c:IsReason(REASON_BATTLE) or (c:IsReason(REASON_EFFECT) and c:GetReasonPlayer()==1-tp)) 
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 and c:IsDestructable(e) and not c:IsStatus(STATUS_DESTROY_CONFIRMED+STATUS_BATTLE_DESTROYED) 
		and eg:IsExists(s.repfilter,1,nil,tp) end
	if Duel.SelectEffectYesNo(tp,c,aux.Stringid(id,0)) then
		local g=eg:Filter(s.repfilter,nil,tp)
		if #g==1 then
			e:SetLabelObject(g:GetFirst())
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESREPLACE)
			local cg=g:Select(tp,1,1,nil)
			e:SetLabelObject(cg:GetFirst())
		end
		c:SetStatus(STATUS_DESTROY_CONFIRMED,true)
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
		return true
	else return false end
end
function s.repval(e,c)
	return c==e:GetLabelObject()
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	c:SetStatus(STATUS_DESTROY_CONFIRMED,false)
	Duel.Destroy(c,REASON_EFFECT+REASON_REPLACE)
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