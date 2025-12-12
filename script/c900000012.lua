--Slayer-Demon Of Creation
local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,4,2)
	--Alternative procedure: 2 "Slayer" monsters
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetDescription(aux.Stringid(id,5))
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.xyzcon)
	e0:SetTarget(s.xyztg)
	e0:SetOperation(s.xyzop)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)
	
	--Always treated as every attribute
	local e_attr=Effect.CreateEffect(c)
	e_attr:SetType(EFFECT_TYPE_SINGLE)
	e_attr:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e_attr:SetCode(EFFECT_ADD_ATTRIBUTE)
	e_attr:SetRange(LOCATION_MZONE+LOCATION_EXTRA)
	e_attr:SetValue(ATTRIBUTE_ALL)
	c:RegisterEffect(e_attr)
	
	--Negate effects when summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
	--Store reference to negate effect for destroy condition
	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1b:SetCondition(s.negcon)
	e1b:SetOperation(s.regop)
	c:RegisterEffect(e1b)
	
	--Destroy if negate effect is negated
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAIN_NEGATED)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	
	--Special summon Slayer monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,3))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	
	--Clear field once per duel
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,4))
	e4:SetCategory(CATEGORY_TOGRAVE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id,EFFECT_COUNT_CODE_DUEL)
	e4:SetCost(s.clearcost)
	e4:SetTarget(s.cleartg)
	e4:SetOperation(s.clearop)
	c:RegisterEffect(e4)
end

--Alternative Xyz procedure filters and functions
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x2407) and c:IsCanBeXyzMaterial()
end

function s.xyzcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
		and Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,2,nil)
end

function s.xyztg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.xyzfilter,tp,LOCATION_MZONE,0,nil)
	if #g>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local sg=g:Select(tp,2,2,nil)
		if sg then
			sg:KeepAlive()
			e:SetLabelObject(sg)
			return true
		end
	end
	return false
end

function s.xyzop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if g then
		c:SetMaterial(g)
		Duel.Overlay(c,g)
		g:DeleteGroup()
	end
end

--Register flag for negate effect usage
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
end

--Negate condition (Xyz Summoned)
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end

	--Negate target
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

--Negate operation
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_NEGATE)
	local g=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,2,nil)
	if #g>0 then
		for tc in aux.Next(g) do
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e1)
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE_EFFECT)
			e2:SetValue(RESET_TURN_SET)
			e2:SetReset(RESET_EVENT+RESETS_STANDARD)
			tc:RegisterEffect(e2)
			if tc:IsType(TYPE_TRAPMONSTER) then
				local e3=Effect.CreateEffect(e:GetHandler())
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e3)
			end
		end
	end
end

--Destroy condition (negate effect was negated)
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetFlagEffect(id)>0 and rp==1-tp and re and re:GetHandler()==c
end

--Destroy target
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,0,0,LOCATION_ONFIELD)
end

--Destroy operation
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,2,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--Special summon cost
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

--Special summon filter
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x2407) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--Special summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED)
end

--Special summon operation
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_DECK+LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		if g:GetFirst():IsLocation(LOCATION_DECK) then
			Duel.ShuffleDeck(tp)
		end
	end
end

--Clear field cost
function s.clearcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end

--Clear field target
function s.cleartg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end

--Clear field operation
function s.clearop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
		--Can only summon 1 monster for the rest of the turn
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e1:SetCode(EFFECT_LEFT_SPSUMMON_COUNT)
		e1:SetTargetRange(1,0)
		e1:SetValue(1)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
		--Cannot Normal Summon for the rest of the turn
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
		e2:SetCode(EFFECT_CANNOT_SUMMON)
		e2:SetTargetRange(1,0)
		e2:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e2,tp)
	end
end