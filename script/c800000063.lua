--Shiranui Soulsaga
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon: 1 Zombie Tuner + 1+ non-Tuners
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsRace,RACE_ZOMBIE),1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()

	--Can only Special Summon once per turn
	c:SetSPSummonOnce(id)

	--Effect 1: On Special Summon: target 1 of your banished monsters; shuffle into Deck, then banish 1 monster from Deck with different original name
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,{id,0}) -- once per turn for this effect
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)

	--Effect 2: If banished: Special Summon 1 "Shiranui" monster from Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_REMOVE)
	e2:SetCountLimit(1,{id,1}) -- once per turn for this effect
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end

--Effect 1 filters: only your banished MONSTERS and ensure a valid monster exists in Deck
function s.tdfilter(c,tp)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToDeck()
		and Duel.IsExistingMatchingCard(s.rmvfilter,tp,LOCATION_DECK,0,1,nil,c:GetOriginalCode())
end
function s.rmvfilter(c,code)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToRemove() and c:GetOriginalCode()~=code
end

--Effect 1 target
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_REMOVED) and s.tdfilter(chkc,tp) end
	if chk==0 then return Duel.IsExistingTarget(s.tdfilter,tp,LOCATION_REMOVED,0,1,nil,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectTarget(tp,s.tdfilter,tp,LOCATION_REMOVED,0,1,1,nil,tp)
	e:SetLabel(g:GetFirst():GetOriginalCode()) -- store original code for Deck banish filtering
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,tp,LOCATION_DECK)
end

--Effect 1 operation
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local code=e:GetLabel()
	if tc and tc:IsRelateToEffect(e) and Duel.SendtoDeck(tc,nil,SEQ_DECKBOTTOM,REASON_EFFECT)>0 then
		Duel.BreakEffect()
		local g=Duel.GetMatchingGroup(s.rmvfilter,tp,LOCATION_DECK,0,nil,code)
		if #g>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local rc=g:Select(tp,1,1,nil):GetFirst()
			if rc then
				Duel.Remove(rc,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
end

--Effect 2: Special Summon 1 "Shiranui" from Deck when banished
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xd9) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
