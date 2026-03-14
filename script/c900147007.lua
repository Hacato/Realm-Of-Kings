--SZS - Synchrogazer
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
	--activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={SET_SZS}
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_SZS) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.xyzfilter(c,e,tp,mc)
	return c:IsSetCard(SET_SZS) and c:IsType(TYPE_XYZ) and mc:IsCanBeXyzMaterial(c,tp,REASON_EFFECT)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.synfilter(c,e,tp,mc)
	return c:IsSetCard(SET_SZS) and c:IsType(TYPE_SYNCHRO) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
        and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp):GetFirst()
    local b1=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,tc)
    local b2=Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,tc)
    if tc then
        Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
    end
	if tc and Duel.GetTurnPlayer()~=tp and (b1 or b2)
        and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.BreakEffect()
        local op=Duel.SelectEffect(tp,
            {b1,aux.Stringid(id,1)},
            {b2,aux.Stringid(id,2)}
        )
        if op==1 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local g=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc)
            local oc=g:GetFirst()
            if oc then
                local mg=Group.FromCards(tc)
                oc:SetMaterial(mg)
                Duel.Overlay(oc,mg)
                Duel.SpecialSummon(oc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
                oc:CompleteProcedure()
            end
        elseif op==2 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local sc=Duel.SelectMatchingCard(tp,s.synfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc):GetFirst()
            if sc then
                local mg=Group.FromCards(tc)
                sc:SetMaterial(mg)
                Duel.Release(mg,REASON_EFFECT|REASON_MATERIAL|REASON_SYNCHRO)
                Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
                sc:CompleteProcedure()
            end
        end
    end
end