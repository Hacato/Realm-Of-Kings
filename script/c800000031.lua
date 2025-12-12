--Aqua Fusion
--Scripted by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
	--Always treated as "Aquamarine" card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x30cd)
	c:RegisterEffect(e0)
	
	--Fusion Summon (OPT)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.activate1)
	c:RegisterEffect(e1)
	
	--Fusion Summon from GY (OPT)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.condition2)
	e2:SetCost(s.cost2)
	e2:SetTarget(s.target2)
	e2:SetOperation(s.activate2)
	c:RegisterEffect(e2)
end

--Fusion material filter for first effect (hand, field, deck) - exactly 2 monsters
function s.matfilter1(c,fc,e)
	return c:IsCanBeFusionMaterial(fc,SUMMON_TYPE_FUSION) and not c:IsImmuneToEffect(e) and c~=e:GetHandler() and c:IsMonster()
end

--Fusion Summon from hand/deck/field
function s.filter1(c,e,tp)
	if not (c:IsType(TYPE_FUSION) and c:IsSetCard(0x30cd) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)) then return false end
	local mg=Duel.GetMatchingGroup(s.matfilter1,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_DECK,0,nil,c,e)
	return c:CheckFusionMaterial(mg,nil,tp) and mg:GetCount()>=2
end

function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.filter1,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.filter1,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if tc then
		local mg=Duel.GetMatchingGroup(s.matfilter1,tp,LOCATION_HAND+LOCATION_ONFIELD+LOCATION_DECK,0,nil,tc,e)
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
		if mat:GetCount()==2 then
			tc:SetMaterial(mat)
			local handmat=mat:Filter(Card.IsLocation,nil,LOCATION_HAND)
			local fieldmat=mat:Filter(Card.IsLocation,nil,LOCATION_ONFIELD)
			local deckmat=mat:Filter(Card.IsLocation,nil,LOCATION_DECK)
			if handmat:GetCount()>0 then
				Duel.SendtoGrave(handmat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			end
			if fieldmat:GetCount()>0 then
				Duel.SendtoGrave(fieldmat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			end
			if deckmat:GetCount()>0 then
				Duel.SendtoGrave(deckmat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			end
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			tc:CompleteProcedure()
			--Cannot Special Summon from Extra Deck except WATER Fusion Monsters
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
			e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			e1:SetTargetRange(1,0)
			e1:SetTarget(s.splimit)
			e1:SetReset(RESET_PHASE+PHASE_END)
			e1:SetDescription(aux.Stringid(id,2))
			Duel.RegisterEffect(e1,tp)
		end
	end
end

function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not (c:IsType(TYPE_FUSION) and c:IsAttribute(ATTRIBUTE_WATER))
end

--Fusion Summon from GY effect - except the turn this card was sent to GY
function s.condition2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp and (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2)
		and aux.exccon(e)
end

--Cost: banish this card from GY
function s.cost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemove() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

--Filter for second effect
function s.filter2(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x30cd) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and s.fcheck2(c,tp,e)
end

function s.fcheck2(c,tp,e)
	local mg=Duel.GetMatchingGroup(s.matfilter2,tp,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e)
	return c:CheckFusionMaterial(mg,nil,tp)
end

--Material filter for second effect (field, GY, face-up banished)
function s.matfilter2(c,e)
	return c:IsAbleToDeck() and (c:IsFaceup() or not c:IsLocation(LOCATION_REMOVED)) and c~=e:GetHandler() and c:IsMonster()
end

function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,0,tp,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.filter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if tc then
		local mg=Duel.GetMatchingGroup(s.matfilter2,tp,LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e)
		local mat=Duel.SelectFusionMaterial(tp,tc,mg,nil,tp)
		tc:SetMaterial(mat)
		Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		tc:CompleteProcedure()
	end
end