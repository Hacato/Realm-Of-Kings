--Grayrover the Wandering Grayscale
local s,id=GetID()
function s.initial_effect(c)
	--Cannot be used as Link Material, except for "Grayscale" Link Monsters
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e0:SetValue(s.linklimit)
	c:RegisterEffect(e0)

	--Special Summon from hand (Quick Effect)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Link Summon after Special Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.lktg)
	e2:SetOperation(s.lkop)
	c:RegisterEffect(e2)

	--Special Summon from GY when Grayscale Xyz is summoned
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_HANDES)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.spcon2)
	e3:SetCost(s.spcost2)
	e3:SetTarget(s.sptg2)
	e3:SetOperation(s.spop2)
	c:RegisterEffect(e3)
end
s.listed_series={0x2410}

--Cannot be Link Material except for "Grayscale"
function s.linklimit(e,c,lnk,sumtype,tp)
	return c and not c:IsSetCard(0x2410)
end

--Special Summon from hand condition
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_MZONE,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Link Summon target
function s.lktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(Card.IsCanBeLinkMaterial,tp,LOCATION_MZONE+LOCATION_HAND,0,nil)
		return Duel.IsExistingMatchingCard(s.lkfilter,tp,LOCATION_EXTRA,0,1,nil,mg,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.lkfilter(c,mg,tp)
	return c:IsSetCard(0x2410) and c:IsLinkSummonable(mg)
end
function s.lkop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(Card.IsCanBeLinkMaterial,tp,LOCATION_MZONE+LOCATION_HAND,0,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.lkfilter,tp,LOCATION_EXTRA,0,1,1,nil,mg,tp)
	local lc=g:GetFirst()
	if lc then
		Duel.LinkSummon(tp,lc,mg)
	end
end

--Grayscale Xyz Special Summon condition
function s.spcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
function s.cfilter(c,tp)
	return c:IsSetCard(0x2410) and c:IsType(TYPE_XYZ) and c:IsControler(tp)
end

--Discard cost
function s.spcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,nil) end
	Duel.DiscardHand(tp,Card.IsDiscardable,1,1,REASON_COST+REASON_DISCARD)
end

--Special Summon from GY
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end
