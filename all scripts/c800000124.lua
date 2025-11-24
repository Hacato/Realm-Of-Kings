--Constructor Sentry Dragline
local s,id=GetID()
function s.initial_effect(c)
	---------------------------------------------------------------
	--1. Special Summon from hand (inherent)
	---------------------------------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetDescription(aux.Stringid(id,0))
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_HAND)
	e0:SetCountLimit(1,id)
	e0:SetCondition(s.spcon)
	c:RegisterEffect(e0)

	---------------------------------------------------------------
	--2. Shuffle 3 Wyrms from GY → Special Summon 1 Wyrm from GY
	---------------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.sscost)
	e2:SetTarget(s.sstg)
	e2:SetOperation(s.ssop)
	c:RegisterEffect(e2)

	---------------------------------------------------------------
	--3. Banish 2 Constructor/Demolition from GY → Draw 2
	---------------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_REMOVE+CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCost(s.drcost)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)
end

s.listed_series={0x1568,0x801}

---------------------------------------------------------------
--E1: Special Summon from hand (inherent)
---------------------------------------------------------------
function s.spconfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_EARTH) and c:IsRace(RACE_WYRM)
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spconfilter,tp,LOCATION_MZONE,0,1,nil)
end

---------------------------------------------------------------
--E2: Shuffle 3 Wyrms → Special Summon 1 Wyrm from GY
---------------------------------------------------------------
function s.tdfilter(c)
	return c:IsRace(RACE_WYRM) and c:IsAbleToDeck()
end

function s.ssfilter(c,e,tp)
	return c:IsRace(RACE_WYRM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

-- Ensure after shuffling 3, there is still a legal SS target
function s.rescon(sg,e,tp,mg)
	return Duel.IsExistingMatchingCard(s.ssfilter,tp,LOCATION_GRAVE,0,1,sg,e,tp)
end

function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local g=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_GRAVE,0,nil)
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,0)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,3,tp,LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.sscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end -- selection happens in operation
end

function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	local g=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_GRAVE,0,nil)
	local sg=aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,1,tp,HINTMSG_TODECK)
	if #sg~=3 then return end

	Duel.HintSelection(sg,true)
	if Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.ssfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp):GetFirst()
	if not tc then return end

	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)>0 then
		if not Duel.IsExistingMatchingCard(Auxiliary.FaceupFilter(Card.IsType,TYPE_FIELD),tp,LOCATION_FZONE,0,1,nil) then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			tc:RegisterEffect(e2)
		end
	end
end

---------------------------------------------------------------
--E3: Banish 2 Constructor/Demolition → Draw 2
---------------------------------------------------------------
function s.costfilter(c)
	return c:IsAbleToRemove() and (c:IsSetCard(0x1568) or c:IsSetCard(0x801))
end

function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_GRAVE,0,2,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_GRAVE,0,2,2,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,2,REASON_EFFECT)
end
