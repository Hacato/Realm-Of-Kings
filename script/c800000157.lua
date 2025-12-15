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
--Ritual Monster filter (Eirika only, from hand)
function s.ritfilter(c,e,tp)
	return c:IsCode(800000154)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end
--Materials from hand/field (tribute) - exclude the ritual monster being summoned
function s.matfilter(c,rc)
	return c:IsMonster() and c:IsReleasableByEffect() and c:HasLevel() and c~=rc
end
--Materials from GY (banish POJ only)
function s.gyfilter(c)
	return c:IsSetCard(0x816) and c:IsMonster() and c:HasLevel() and c:IsAbleToRemove()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
		local rg=Duel.GetMatchingGroup(s.ritfilter,tp,LOCATION_HAND,0,nil,e,tp)
		if #rg==0 then return false end
		local rc=rg:GetFirst()
		local mg1=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,rc,rc)
		local mg2=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
		mg1:Merge(mg2)
		return mg1:CheckWithSumGreater(Card.GetLevel,5)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rc=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp):GetFirst()
	if not rc then return end
	
	--Get materials excluding the ritual monster being summoned
	local mg1=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,rc,rc)
	local mg2=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil)
	mg1:Merge(mg2)
	
	local lv=rc:GetLevel()
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local mat=aux.SelectUnselectGroup(
		mg1,
		e,tp,
		1,99,
		function(g)
			return g:GetSum(Card.GetLevel)>=lv
		end,
		1,tp,
		HINTMSG_RELEASE
	)
	
	if not mat or #mat==0 then return end
	
	--Split materials by location
	local rg=mat:Filter(Card.IsLocation,nil,LOCATION_HAND+LOCATION_MZONE)
	local bg=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	
	--Tribute materials from hand/field
	if #rg>0 then
		Duel.Release(rg,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
	
	--Banish materials from GY
	if #bg>0 then
		Duel.Remove(bg,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
	end
	
	--Special Summon the Ritual Monster from hand
	Duel.BreakEffect()
	Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
	rc:CompleteProcedure()
end