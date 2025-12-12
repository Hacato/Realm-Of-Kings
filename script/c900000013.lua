--Slayer-Servant King Of Society
local s,id=GetID()
function s.initial_effect(c)
	--Link Summon
	c:EnableReviveLimit()
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsSetCard,0x2407),2,2)
	
	--Always treated as every attribute
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_ADD_ATTRIBUTE)
	e0:SetRange(LOCATION_MZONE+LOCATION_EXTRA)
	e0:SetValue(ATTRIBUTE_ALL)
	c:RegisterEffect(e0)
	
	--Add "Slayer Society" when summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	
	--Special summon when Slayer Society is activated
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAIN_SOLVING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	
	--Add Slayer S/T when leaves field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetTarget(s.th2tg)
	e3:SetOperation(s.th2op)
	c:RegisterEffect(e3)
end

s.listed_names={900000003} --Slayer Society

--When summoned condition (Link Summon)
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_LINK)
end

--Add Slayer Society filter
function s.thfilter(c)
	return c:IsCode(900000003) and c:IsAbleToHand()
end

--Add Slayer Society target
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

--Add Slayer Society operation
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--Special summon condition (Slayer Society activated)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local seq=c:GetSequence()
	return re and re:GetHandler():IsCode(900000003) and c:IsLocation(LOCATION_MZONE) and (seq==5 or seq==6)
end

--Special summon filters
function s.spfilter1(c,e,tp)
	return c:IsSetCard(0x2407) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end

function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x2407) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE,1-tp)
end

--Special summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g1=Duel.GetMatchingGroup(s.spfilter1,tp,LOCATION_GRAVE,0,nil,e,tp)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_DECK,0,nil,e,tp)
	if chk==0 then return #g1>0 or #g2>0 end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_DECK)
end

--Special summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.spfilter1),tp,LOCATION_GRAVE,0,nil,e,tp)
	local g2=Duel.GetMatchingGroup(s.spfilter2,tp,LOCATION_DECK,0,nil,e,tp)
	
	local ft1=Duel.GetLocationCount(tp,LOCATION_MZONE)
	local ft2=Duel.GetLocationCount(1-tp,LOCATION_MZONE)
	
	--Special summon from grave (up to 3, to your field)
	if #g1>0 and ft1>0 then
		local ct=math.min(3,ft1,#g1)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg1=g1:Select(tp,1,ct,nil)
		if #sg1>0 then
			Duel.SpecialSummon(sg1,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
		end
	end
	
	--Special summon from deck (1, to opponent's field)
	if #g2>0 and ft2>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg2=g2:Select(tp,1,1,nil)
		if #sg2>0 then
			Duel.SpecialSummon(sg2,0,tp,1-tp,false,false,POS_FACEUP_DEFENSE)
			Duel.ShuffleDeck(tp)
		end
	end
end

--Add Slayer S/T filter
function s.th2filter(c)
	return c:IsSetCard(0x2407) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end

--Add Slayer S/T target
function s.th2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.th2filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

--Add Slayer S/T operation
function s.th2op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.th2filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end