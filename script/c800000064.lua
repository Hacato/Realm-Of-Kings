--Shiranui Style Seven Stars
local s,id=GetID()
function s.initial_effect(c)
	--Effect 1: Shuffle 2 banished Zombies (1 Tuner + 1 non-Tuner), then Synchro Summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sctg)
	e1:SetOperation(s.scop)
	c:RegisterEffect(e1)

	--Effect 2: GY effect - Search (Ignition Effect)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCost(s.thcost)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

--=============================
-- Effect 1 helpers
--=============================
function s.tdfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsRace(RACE_ZOMBIE) and c:IsAbleToDeck()
end
function s.synfilter(c,e,tp,lv)
	return c:IsType(TYPE_SYNCHRO) and c:IsRace(RACE_ZOMBIE)
		and c:IsLevel(lv) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false)
end

-- Helper function to check if a valid Synchro exists for given level
function s.syncheck(e,tp,lv)
	return Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,lv)
end

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local g=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_REMOVED,0,nil)
	if chk==0 then
		-- Check for at least one Tuner and one non-Tuner
		local tuners=g:Filter(Card.IsType,nil,TYPE_TUNER)
		local nonTuners=g:Clone()
		for tc in aux.Next(tuners) do
			nonTuners:RemoveCard(tc)
		end
		if #tuners==0 or #nonTuners==0 then return false end
		-- Check if any valid combination has a matching Synchro Monster
		for tuner in aux.Next(tuners) do
			for nontuner in aux.Next(nonTuners) do
				local lv=tuner:GetLevel()+nontuner:GetLevel()
				if s.syncheck(e,tp,lv) then return true end
			end
		end
		return false
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g1=g:FilterSelect(tp,Card.IsType,1,1,nil,TYPE_TUNER)
	local g2=g:Clone()
	g2:RemoveCard(g1:GetFirst())
	-- Filter out remaining Tuners, only allow non-Tuners
	g2=g2:Filter(function(c) return not c:IsType(TYPE_TUNER) end,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g2sel=g2:Select(tp,1,1,nil)
	g1:Merge(g2sel)
	Duel.SetTargetCard(g1)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g1,2,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.scop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g~=2 then return end
	if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
		-- calculate total Levels
		local lv=0
		for tc in aux.Next(g) do
			if tc:IsLocation(LOCATION_DECK+LOCATION_EXTRA) then
				lv=lv+tc:GetLevel()
			end
		end
		if lv>0 then
			local sg=Duel.GetMatchingGroup(s.synfilter,tp,LOCATION_EXTRA,0,nil,e,tp,lv)
			if #sg>0 then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
				local sc=sg:Select(tp,1,1,nil):GetFirst()
				if sc and Duel.GetLocationCountFromEx(tp,tp,nil,sc)>0 then
					Duel.SpecialSummon(sc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
					sc:CompleteProcedure()
				end
			end
		end
	end
end

--=============================
-- Effect 2 helpers (GY search)
--=============================
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return e:GetHandler():IsAbleToRemoveAsCost() 
			and Duel.IsExistingMatchingCard(Card.IsAbleToRemoveAsCost,tp,LOCATION_HAND,0,1,nil) 
	end
	-- Banish this card
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
	-- Banish 1 card from hand
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemoveAsCost,tp,LOCATION_HAND,0,1,1,nil)
	if #g>0 then
		Duel.Remove(g,POS_FACEUP,REASON_COST)
	end
end

function s.thfilter(c)
	return c:IsSetCard(0xd9) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end