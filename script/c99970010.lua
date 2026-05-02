--DAL - Spacequake
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --activate
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={SET_DAL,SET_SPIRIT}
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SPIRIT) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil,e,tp) end
    Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_MZONE)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local dg1=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,0,e:GetHandler())
    local dg2=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_ONFIELD,nil)
    local resolves=false
	if #dg1>0 and #dg2>0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local sg1=dg1:Select(tp,1,1,nil)
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local sg2=dg2:Select(tp,1,1,nil)
        sg1:Merge(sg2)
		Duel.HintSelection(sg1)
		Duel.Destroy(sg1,REASON_EFFECT)
	end
    Duel.BreakEffect()
    Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(id,1))
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<1 then return end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
    local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil,e,tp)
    if #g>0 then
        Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
        resolves=true
    end
    if resolves then
        e:GetHandler():CancelToGrave()
        Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end