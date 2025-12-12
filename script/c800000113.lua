--Constructor Resurrection
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon from GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end
s.listed_series={0x1568,0x1569} --Constructor, Blisstopia

--Target filter
function s.spfilter(c,e,tp,blisstopia)
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	if blisstopia then
		return c:IsRace(RACE_WYRM)
	else
		return c:IsSetCard(0x1568) and c:IsMonster()
	end
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local blisstopia=Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x1569),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp,blisstopia) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,blisstopia) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp,blisstopia)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		--Cannot Special Summon except Wyrm monsters
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(aux.Stringid(id,1))
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
		e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		e1:SetTargetRange(1,0)
		e1:SetTarget(s.splimit)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end
--Special Summon restriction: only Wyrm monsters
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsRace(RACE_WYRM)
end