--Black Chaos Offering
--Coded by HuascarD
local s,id,o=GetID()
function s.initial_effect(c)
	local e1=Ritual.CreateProc({handler=c,lvtype=RITPROC_GREATER,filter=s.ritualfil,extrafil=s.extrafil,extraop=s.extraop,matfilter=s.forcedgroup,location=LOCATION_HAND+LOCATION_GRAVE})
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target(e1))
	c:RegisterEffect(e1)
end
s.listed_series={0xcf}
function s.ritualfil(c)
	return c:IsSetCard(0xcf) and c:IsRitualMonster()
end
function s.exfilter0(c,e)
	return c:IsFaceup() and c:IsCanBeRitualMaterial(sc) and not c:IsImmuneToEffect(e)
end
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>1 then
		return Duel.GetMatchingGroup(s.exfilter0,tp,0,LOCATION_MZONE,nil,e,c)
	end
end
function s.extraop(mg,e,tp,eg,ep,ev,re,r,rp)
	local mat2=mg:Filter(Card.IsControler,nil,1-tp)
	mg:Sub(mat2)
	Duel.ReleaseRitualMaterial(mg)
	Duel.SendtoGrave(mat2,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end
function s.forcedgroup(c,e,tp)
	return c:IsLocation(LOCATION_HAND+LOCATION_ONFIELD) or (c:IsControler(1-tp) and c:IsLocation(LOCATION_MZONE))
end
function s.target(eff)
	local tg = eff:GetTarget()
	return function(e,...)
		local ret = tg(e,...)
		if ret then return ret end
		if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
			Duel.SetChainLimit(s.chlimit)
		end
	end
end
function s.chlimit(e,ep,tp)
	return tp==ep
end