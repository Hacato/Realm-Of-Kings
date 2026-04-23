--Mokey Mokey Vengeance
local s,id=GetID()
local CARD_MOKEY_MOKEY_DEMIGOD=900000086

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_DESTROYED)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end
s.listed_names={CARD_MOKEY_MOKEY_DEMIGOD}
s.listed_series={0x184}

--A "Mokey Mokey" monster you controlled was destroyed
function s.cfilter(c,tp)
	return c:IsReason(REASON_BATTLE|REASON_EFFECT)
		and c:IsPreviousLocation(LOCATION_MZONE)
		and c:IsPreviousControler(tp)
		and c:IsMonster()
		and c:IsSetCard(0x184)
end

function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

--"Mokey Mokey" monsters in your GY and/or banished
function s.spfilter(c,e,tp)
	return c:IsMonster()
		and c:IsSetCard(0x184)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--"Mokey Mokey Demigod" in your Extra Deck
function s.demigodfilter(c,e,tp)
	return c:IsCode(CARD_MOKEY_MOKEY_DEMIGOD)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local zone=0
	if Duel.CheckLocation(tp,LOCATION_MZONE,5) then
		zone=0x20
	elseif Duel.CheckLocation(tp,LOCATION_MZONE,6) then
		zone=0x40
	end
	if chk==0 then
		return ft>0
			and zone~=0
			and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.demigodfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end

	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE|LOCATION_REMOVED,0,nil,e,tp)
	if #g==0 then return end

	local sg=nil
	if #g<=ft then
		sg=g
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		sg=g:Select(tp,ft,ft,nil)
	end
	if not sg or #sg==0 then return end

	if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	--Only Special Summon "Mokey Mokey Demigod" to an Extra Monster Zone
	local zone=0
	if Duel.CheckLocation(tp,LOCATION_MZONE,5) then
		zone=0x20
	elseif Duel.CheckLocation(tp,LOCATION_MZONE,6) then
		zone=0x40
	end
	if zone==0 then return end

	local tc=Duel.GetFirstMatchingCard(s.demigodfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
	if tc then
		Duel.BreakEffect()
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP,zone)
	end
end