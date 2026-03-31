--Archfiend's Linkage
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Link Summon procedure
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FIEND),2,2)
	--Change name
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(CARD_SUMMONED_SKULL)
	c:RegisterEffect(e1)
	--Search both cards
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.condition)
	e2:SetCost(s.cost)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
	--Special Summon "Summoned Skull"
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end
s.listed_series={0x45}
s.listed_names={69035382,CARD_SUMMONED_SKULL,95825679}
function s.condition(e,tp,eg,ep,ev,re,r,rp)--Search both cards
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsAbleToDeckAsCost,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeckAsCost,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil)
	Duel.SendtoDeck(g,nil,1,REASON_COST)
end
------------
--function s.tgcostfilter(c,tp)--shuffle 2 "Summoned Skull" and/or cs that mention it from your h/GY into the D/Ex D; add 1 "Archfiend's Awakening" and 1 "Contract with the Abyss" from your D/GY to your h
--	return (c:IsCode(CARD_SUMMONED_SKULL) or c:ListsCode(CARD_SUMMONED_SKULL)) and c:IsAbleToDeckOrExtraAsCost()
--end
--function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
--	local c=e:GetHandler()
--	if chk==0 then return Duel.IsExistingMatchingCard(s.tgcostfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,2,c) end
--	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
--	local g=Duel.SelectMatchingCard(tp,s.tgcostfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,2,2,c)
--	Duel.HintSelection(g)
--	Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_COST)
--end
-------------
function s.filter1(c,tp)
	return c:IsCode(69035382) and c:IsAbleToHand()
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,c)
end
function s.filter2(c)
	return c:IsCode(95825679) and c:IsAbleToHand()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g1=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,tp)
	if #g1>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g2=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.filter2),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,g1:GetFirst())
		g1:Merge(g2)
		Duel.SendtoHand(g1,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g1)
	end
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)--Sp Summ "Summoned Skull"
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_LINK) and rp==1-tp and c:IsPreviousControler(tp)
end
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_SUMMONED_SKULL) and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
		return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)
	end
end