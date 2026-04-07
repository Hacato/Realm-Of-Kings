--Orcust Piano Steed
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon + optional Link Summon (Ignition)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1,{id,1})
	e1:SetCost(Cost.SelfBanish)
	e1:SetCondition(s.spcon1)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Quick Effect version (Babel)
	local e2=e1:Clone()
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMING_END_PHASE)
	e2:SetCondition(s.spcon2)
	c:RegisterEffect(e2)
end

s.listed_series={SET_ORCUST}

--Condition: no Babel → Ignition
function s.spcon1(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsPlayerAffectedByEffect(tp,CARD_ORCUSTRATED_BABEL)
end

--Condition: with Babel → Quick Effect
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsPlayerAffectedByEffect(tp,CARD_ORCUSTRATED_BABEL)
end

--Filter for Orcust monster
function s.spfilter(c,e,tp)
	return c:IsSetCard(SET_ORCUST)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Filter for DARK Link monster
function s.lkfilter(c,e,tp,mg)
	return c:IsAttribute(ATTRIBUTE_DARK)
		and c:IsType(TYPE_LINK)
		and c:IsLinkSummonable(nil,mg)
end

--Target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
			and chkc:IsLocation(LOCATION_GRAVE)
			and s.spfilter(chkc,e,tp)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler(),e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,e:GetHandler(),e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

--Operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	--Special Summon
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)<=0 then return end

	--Optional Link Summon
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local lg=Duel.GetMatchingGroup(s.lkfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg)
	if #lg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local lc=lg:Select(tp,1,1,nil):GetFirst()
		Duel.LinkSummon(tp,lc,nil,mg)
	end
end