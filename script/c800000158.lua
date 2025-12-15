--Pursuer of Justice - L'Arachel the Light of Rausten
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Summon procedure: 3 "Pursuer of Justice" monsters with different names
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_FUSION_MATERIAL)
	e0:SetCondition(s.fuscon)
	e0:SetOperation(s.fusop)
	c:RegisterEffect(e0)
	--Cannot Special Summon except "Pursuer of Justice" monsters (cannot be negated)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	--Special Summon Level 4 or lower POJ from GY when Fusion Summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--Shuffle 3 banished POJ and draw 2 when sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
	--Limit to 1
	c:SetUniqueOnField(1,0,id)
end
s.listed_series={0x816}

--Fusion material filter
function s.ffilter(c,fc,sub,mg,sg)
	return c:IsSetCard(0x816) and (not sg or not sg:IsExists(Card.IsCode,1,c,c:GetCode()))
end

--Fusion condition
function s.fuscon(e,g,gc,chkf)
	if g==nil then return true end
	local c=e:GetHandler()
	local mg=g:Filter(s.ffilter,nil,c,false,nil,nil)
	if gc then
		if not mg:IsContains(gc) then return false end
		local sg=Group.CreateGroup()
		return mg:IsExists(s.fusfilter1,1,nil,c,mg,sg,gc,chkf)
	end
	local sg=Group.CreateGroup()
	return mg:IsExists(s.fusfilter1,1,nil,c,mg,sg,nil,chkf)
end

function s.fusfilter1(c,fc,mg,sg,gc,chkf)
	sg:AddCard(c)
	local res=mg:IsExists(s.fusfilter2,1,sg,fc,mg,sg,gc,chkf)
	sg:RemoveCard(c)
	return res
end

function s.fusfilter2(c,fc,mg,sg,gc,chkf)
	sg:AddCard(c)
	local res=mg:IsExists(s.fusfilter3,1,sg,fc,mg,sg,gc,chkf)
	sg:RemoveCard(c)
	return res
end

function s.fusfilter3(c,fc,mg,sg,gc,chkf)
	sg:AddCard(c)
	local res=sg:GetClassCount(Card.GetCode)==3 and (not gc or sg:IsContains(gc)) and Duel.GetLocationCountFromEx(0,0,sg,fc)>0
	sg:RemoveCard(c)
	return res
end

--Fusion operation
function s.fusop(e,tp,eg,ep,ev,re,r,rp,gc,chkf)
	local c=e:GetHandler()
	local mg=eg:Filter(s.ffilter,nil,c,false,nil,nil)
	local sg=Group.CreateGroup()
	for i=1,3 do
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local tc=mg:FilterSelect(tp,s.fuscheck,1,1,nil,sg,gc,i==3):GetFirst()
		sg:AddCard(tc)
		if gc and tc==gc then gc=nil end
	end
	Duel.SetFusionMaterial(sg)
end

function s.fuscheck(c,sg,gc,last)
	if sg:IsExists(Card.IsCode,1,nil,c:GetCode()) then return false end
	if last then
		sg:AddCard(c)
		local res=(not gc or sg:IsContains(gc))
		sg:RemoveCard(c)
		return res
	end
	return true
end

--Cannot Special Summon except "Pursuer of Justice" monsters
function s.splimit(e,c,sump,sumtype,sumpos,targetp)
	return not c:IsSetCard(0x816)
end

--Special Summon condition: Fusion Summoned
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

--Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

function s.spfilter(c,e,tp)
	return c:IsSetCard(0x816) and c:IsLevelBelow(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Special Summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		--Cannot attack this turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_ATTACK)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

--Draw condition: Fusion Summoned and sent to GY
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsSummonType(SUMMON_TYPE_FUSION)
end

--Draw target
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2)
		and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_REMOVED,0,3,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.tdfilter(c)
	return c:IsSetCard(0x816) and c:IsMonster() and c:IsAbleToDeck()
end

--Draw operation
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_REMOVED,0,3,3,nil)
	if #g==3 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==3 then
		Duel.BreakEffect()
		Duel.Draw(tp,2,REASON_EFFECT)
	end
end