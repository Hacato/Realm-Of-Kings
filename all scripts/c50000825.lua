--Dark Counterpart Showdown
local s,id=GetID()
function s.initial_effect(c)
	local e1=Ritual.CreateProc({handler=c,lvtype=RITPROC_EQUAL,filter=s.ritualfil,extrafil=s.extrafil,extraop=s.extraop,matfilter=s.matfilter})
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
end
function s.ritualfil(c)
	return c:IsCode(50000824) -- Mirror Counterpart - Dark Meta Knight
end
function s.exfilter0(c)
	return c:IsType(TYPE_PENDULUM) and c:IsLevelAbove(1) and c:IsAbleToGrave()
end
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	if Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0 then
		return Duel.GetMatchingGroup(s.exfilter0,tp,LOCATION_DECK,0,nil)
	end
end
function s.extraop(mg,e,tp,eg,ep,ev,re,r,rp)
	local mat2=mg:Filter(Card.IsLocation,nil,LOCATION_DECK)
	if #mat2>0 then
		mg:Sub(mat2)
		Duel.SendtoGrave(mat2,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
	if #mg>0 then
		Duel.ReleaseRitualMaterial(mg)
	end
end
function s.matfilter(c,e,tp)
	return c:IsType(TYPE_PENDULUM) and (c:IsLocation(LOCATION_HAND+LOCATION_ONFIELD) or (c:IsLocation(LOCATION_DECK) and Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0))
end