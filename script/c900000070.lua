--Ursarctic Drytron Meteominor Ursids
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	c:AddMustBeRitualSummoned()
	--You can only control 1
	c:SetUniqueOnField(1,0,id)
	--Ritual material check (≤ Level 2 total)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_MATERIAL_CHECK)
	e0:SetValue(s.matcheck)
	c:RegisterEffect(e0)
	--Special Summon from hand (Polari-style)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--Store the summon method info
	local e1b=Effect.CreateEffect(c)
	e1b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1b:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1b:SetOperation(s.sumop)
	c:RegisterEffect(e1b)
	--Unaffected by monsters Special Summoned from the Extra Deck
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)
	--Negate activation
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.negcon)
	e3:SetTarget(s.negtg)
	e3:SetOperation(s.negop)
	c:RegisterEffect(e3)
	--Store summon condition on the card itself
	if not s.global_check then
		s.global_check=true
		s.summon_with_lv8={}
	end
end
s.listed_series={SET_URSARCTIC,SET_DRYTRON}
s.listed_names={22398665}

--========== Ritual material check ==========
function s.matcheck(e,c)
	local g=c:GetMaterial()
	if g and g:GetSum(Card.GetOriginalLevel)<=2 then
		c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
	end
end

--========== Polari-style Special Summon ==========
function s.matfilter(c)
	return c:IsFaceup() and c:IsAbleToGraveAsCost() and c:HasLevel()
end
function s.matfilter1(c,tp,g,sc)
	return c:IsType(TYPE_TUNER) and g:IsExists(s.matfilter2,1,c,tp,c,sc)
end
function s.matfilter2(c,tp,mc,sc)
	local sg=Group.FromCards(c,mc)
	return not c:IsType(TYPE_TUNER) and math.abs(c:GetLevel()-mc:GetLevel())==1
		and Duel.GetMZoneCount(tp,sg,sc)>0
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	return g:IsExists(s.matfilter1,1,nil,tp,g,c)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,0,nil)
	local g1=g:Filter(s.matfilter1,nil,tp,g,c)
	local sg1=aux.SelectUnselectGroup(g1,e,tp,1,1,nil,1,tp,HINTMSG_TOGRAVE)
	if #sg1==0 then return false end
	local mc=sg1:GetFirst()
	local g2=g:Filter(s.matfilter2,mc,tp,mc,c)
	local sg2=aux.SelectUnselectGroup(g2,e,tp,1,1,nil,1,tp,HINTMSG_TOGRAVE)
	if #sg2==0 then return false end
	sg1:Merge(sg2)
	sg1:KeepAlive()
	e:SetLabelObject(sg1)
	return true
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	if not g then return end
	--Check if Level 8+ Tuner was used BEFORE sending to grave
	local has_lv8_tuner=false
	for tc in aux.Next(g) do
		if tc:IsType(TYPE_TUNER) and tc:GetLevel()>=8 then
			has_lv8_tuner=true
			break
		end
	end
	--Store this information in the global table using card's ID
	if has_lv8_tuner then
		s.summon_with_lv8[c]=true
	end
	Duel.SendtoGrave(g,REASON_COST)
	g:DeleteGroup()
end

--Finalize Special Summon condition
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--Check if this card was summoned with Level 8+ Tuner
	if s.summon_with_lv8[c] then
		c:RegisterFlagEffect(id+1,RESET_EVENT+RESETS_STANDARD,0,1)
		s.summon_with_lv8[c]=nil --Clean up
	end
end

--========== Immunity ==========
function s.immval(e,re)
	return re:IsActiveType(TYPE_MONSTER) and re:GetHandler():IsSummonLocation(LOCATION_EXTRA)
end

--========== Negate ==========
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsChainNegatable(ev) then return false end
	local c=e:GetHandler()
	return c:GetFlagEffect(id)>0 or c:GetFlagEffect(id+1)>0
end
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
end