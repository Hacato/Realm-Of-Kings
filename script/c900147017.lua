--Song of Relic
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={SET_SZS}
function s.filter(c)
	return c:IsSetCard(SET_SZS) and c:IsAbleToDeck()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    local ct=Duel.GetMatchingGroupCount(s.filter,tp,LOCATION_GRAVE,0,nil)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_GRAVE,0,1,ct,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
end
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_XYZ+TYPE_SYNCHRO) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
    local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
    if not tg then return end
    tg=tg:Filter(Card.IsRelateToEffect,nil,e)
    if #tg==0 then return end
    if tg:IsExists(Card.IsType,1,nil,TYPE_XYZ|TYPE_SYNCHRO) and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        local sg=tg:Filter(s.spfilter,nil,e,tp)
        if #sg==0 then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local sc=sg:Select(tp,1,1,nil):GetFirst()
        Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
        tg:RemoveCard(sc)
        for tc in tg:Iter() do
            Symphogear.IncreaseATK(sc,{
                value=300,
                reset=RESETS_STANDARD
            })
            local e1=Effect.CreateEffect(e:GetHandler())
            e1:SetDescription(3110)
            e1:SetType(EFFECT_TYPE_SINGLE)
            e1:SetCode(EFFECT_IMMUNE_EFFECT)
            e1:SetRange(LOCATION_MZONE)
            e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
            e1:SetValue(s.efilter)
            e1:SetOwnerPlayer(tp)
            e1:SetReset(RESETS_STANDARD)
            sc:RegisterEffect(e1,true)
        end
    end
    if #tg>0 then
        Duel.SendtoDeck(tg,nil,SEQ_DECKTOP,REASON_EFFECT)
        Duel.ShuffleDeck(tp)
    end
end
function s.efilter(e,re)
	return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end
Duel.LoadScript("szs-utility.lua")