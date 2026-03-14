--SZS - X-Drive Maria
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
	--synchro summon
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99,s.matfilter)
	c:EnableReviveLimit()
	--cannot spsummon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,1)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	--destroy
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_TRIGGER_F+EFFECT_TYPE_FIELD)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_SZS}
function s.cfilter(c)
	return c:IsSetCard(SET_SZS) and c:IsType(TYPE_XYZ|TYPE_SYNCHRO)
end
function s.splimit(e,c)
	local tp=c:GetControler()
	local og=Duel.GetMatchingGroupCount(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local cg=Duel.GetMatchingGroupCount(s.cfilter,tp,0,LOCATION_MZONE,nil)
	return og==cg
end
function s.matfilter(c,scard,sumtype,tp)
	return c:IsSetCard(SET_SZS,scard,sumtype,tp)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.HintSelection(e:GetHandler())
	if Duel.SelectYesNo(tp, aux.Stringid(id,0)) then
		Duel.PayLPCost(tp,1000)
	else
		Duel.Destroy(e:GetHandler(),REASON_EFFECT)
	end
end
Duel.LoadScript("szs-utility.lua")