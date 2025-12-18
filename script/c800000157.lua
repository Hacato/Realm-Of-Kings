--The Sacred Stone of Renais
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

s.listed_names={800000154}
s.listed_series={0x816}

--Ritual Monster: Eirika only
function s.ritfilter(c,e,tp)
	return c:IsCode(800000154)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end

--Hand / Field materials (Tribute)
function s.matfilter(c)
	return c:IsMonster() and c:HasLevel() and c:IsReleasableByEffect()
end

--GY materials (POJ only, banish)
function s.gyfilter(c)
	return c:IsSetCard(0x816) and c:IsMonster() and c:HasLevel() and c:IsAbleToRemove()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local rc=Duel.GetMatchingGroup(s.ritfilter,tp,LOCATION_HAND,0,nil,e,tp):GetFirst()
		if not rc then return false end
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
		local gy=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
		mg:Merge(gy)
		return mg:CheckWithSumGreater(Card.GetLevel,6)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rc=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp):GetFirst()
	if not rc then return end

	--Collect materials
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,nil)
	local gy=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
	mg:Merge(gy)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local mat=mg:SelectWithSumGreater(tp,Card.GetLevel,6)
	if not mat or #mat==0 then return end

	--Tribute hand/field
	local rg=mat:Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE)
	if #rg>0 then
		Duel.Release(rg,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end

	--Banish GY
	local bg=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	if #bg>0 then
		Duel.Remove(bg,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end

	--Ritual Summon
	Duel.BreakEffect()
	Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
	rc:CompleteProcedure()
end
