--Red Dragon Ascension
--Trap Card
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Banish effect
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_OATH)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.gytg)
	e2:SetOperation(s.gyop)
	c:RegisterEffect(e2)
end
s.listed_series={0x1045,0x57} -- 0x1045 is Red Dragon Archfiend series, 0x57 is Resonator

function s.rdafilter(c)
	return c:IsSetCard(0x1045) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

function s.tunerfilter(c)
	return c:IsType(TYPE_TUNER) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup())
end

function s.spfilter(c,e,tp,lv)
	return c:IsSetCard(0x1045) and c:IsType(TYPE_SYNCHRO) and c:GetLevel()==lv 
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_SYNCHRO,tp,false,false) 
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local rg=Duel.GetMatchingGroup(s.rdafilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	local tg=Duel.GetMatchingGroup(s.tunerfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if chk==0 then 
		return #rg>0 and #tg>0
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g1=Duel.SelectTarget(tp,s.rdafilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil)
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g2=Duel.SelectTarget(tp,s.tunerfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,99,nil)
	
	local g=Group.CreateGroup()
	g:Merge(g1)
	g:Merge(g2)
	
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g==0 then return end
	
	local total=0
	for tc in aux.Next(g) do
		total=total+tc:GetLevel()
	end
	
	if Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==#g then
		Duel.BreakEffect()
		
		local pg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,total)
		if #pg>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tc=pg:Select(tp,1,1,nil):GetFirst()
			if tc then
				Duel.SpecialSummon(tc,SUMMON_TYPE_SYNCHRO,tp,tp,false,false,POS_FACEUP)
				tc:CompleteProcedure()
			end
		end
	end
end

function s.rda_filter(c)
	return c:IsFaceup() and c:IsSetCard(0x1045) and c:IsType(TYPE_SYNCHRO)
end

function s.resonator_filter(c)
	return c:IsSetCard(0x57) and c:IsMonster() and c:IsAbleToGrave()
end

function s.gytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.rda_filter(chkc) end
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	if chk==0 then return Duel.IsExistingTarget(s.rda_filter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.resonator_filter,tp,LOCATION_DECK,0,1,nil)
		and ct>0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.rda_filter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,math.min(ct,Duel.GetMatchingGroupCount(s.resonator_filter,tp,LOCATION_DECK,0,nil)),tp,LOCATION_DECK)
end

function s.gyop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) then return end
	
	local ct=Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
	if ct==0 then return end
	
	local g=Duel.GetMatchingGroup(s.resonator_filter,tp,LOCATION_DECK,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,1,ct,aux.TRUE,1,tp,HINTMSG_TOGRAVE)
	local sent=Duel.SendtoGrave(sg,REASON_EFFECT)
	local sentct=sg:FilterCount(Card.IsLocation,nil,LOCATION_GRAVE)
	
	if sentct>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(sentct)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end