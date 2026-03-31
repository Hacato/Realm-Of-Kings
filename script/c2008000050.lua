--Kashtira Hydra
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,SET_KASHTIRA),7,2)
	c:EnableReviveLimit()
	--rm the top c from your opp's D f-d or GY f-d
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1)
	e1:SetCost(aux.dxmcostgen(1,1,nil))
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1,false,REGISTER_FLAG_DETACH_XMAT)
	--rm top 3 cs from the opp's D f-d
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_REMOVE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.dkcon)
	e2:SetTarget(s.dktg)
	e2:SetOperation(s.dkop)
	c:RegisterEffect(e2)
end
s.listed_names={id}
s.listed_series={SET_KASHTIRA}
function s.filter(c)--rm the top c from your opp's D f-d or GY f-d
	return c:IsSetCard(SET_KASHTIRA) and c:IsAbleToRemove()
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) and Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_DECK+LOCATION_GRAVE,1,nil) end
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	--your "Kashtira" c
	local g1=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g1:GetFirst()
	--your opp's D or GY card, f-d
	local g2=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_DECK+LOCATION_GRAVE,1,1,nil)
	if tc and #g2>0 then
	    Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
		Duel.HintSelection(g2,true)
		Duel.Remove(g2,POS_FACEDOWN,REASON_EFFECT)
	end
end
function s.dkfilter(c,tp)--rm the top 3 cs from your opp's D f-d
	return c:IsFacedown() and (c:IsControler(1-tp) or c:IsControler(tp))
end
function s.dkcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.dkfilter,1,nil,tp)
end
function s.dktg(e,tp,eg,ep,ev,re,r,rp,chk)
    local ct=Duel.GetMatchingGroupCount(s.dkfilter,tp,LOCATION_REMOVED,LOCATION_REMOVED,tp,1-tp)
	local rg=Duel.GetDecktopGroup(1-tp,4)
	if chk==0 then return rg:FilterCount(Card.IsAbleToRemove,nil,tp,POS_FACEDOWN,REASON_EFFECT)==3 end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,rg,3,1-tp,LOCATION_DECK)
end
function s.dkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetDecktopGroup(1-tp,3)
	if #g==0 then return end
	Duel.DisableShuffleCheck()
	Duel.Remove(g,POS_FACEDOWN,REASON_EFFECT)
end