--Toon World - Effect
--Script by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	c:RegisterEffect(e1)
	--This card's name is always treated as "Toon World"
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetRange(LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE+LOCATION_REMOVED+LOCATION_SZONE)
	e2:SetValue(15259703)
	c:RegisterEffect(e2)
	--Opponent's monsters cannot attack during the turn they are Summoned
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_CANNOT_ATTACK)
	e3:SetRange(LOCATION_SZONE)
	e3:SetTargetRange(0,LOCATION_MZONE)
	e3:SetTarget(s.atktg)
	c:RegisterEffect(e3)
	--Register when monsters are summoned
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_SUMMON_SUCCESS)
	e4:SetRange(LOCATION_SZONE)
	e4:SetOperation(s.sumreg)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EVENT_FLIP_SUMMON_SUCCESS)
	c:RegisterEffect(e5)
	local e6=e4:Clone()
	e6:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e6)
	--Ritual Summon
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,0))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_IGNITION)
	e7:SetRange(LOCATION_SZONE)
	e7:SetCountLimit(1,id)
	e7:SetTarget(s.ristg)
	e7:SetOperation(s.risop)
	c:RegisterEffect(e7)
end
s.listed_names={15259703} --"Toon World"
s.listed_archetype=0x110 --"Relinquished" archetype
--Activation cost
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
--Cannot attack condition
function s.atktg(e,c)
	return c:GetFlagEffect(id)>0
end
--Register when monsters are summoned
function s.sumreg(e,tp,eg,ep,ev,re,r,rp)
	local g=eg:Filter(Card.IsControler,nil,1-tp)
	local tc=g:GetFirst()
	while tc do
		tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
		tc=g:GetNext()
	end
end
--Filter for "Relinquished" archetype or Toon type ritual monsters
function s.ritfilter(c,e,tp)
	return (c:IsSetCard(0x110) or (c:IsType(TYPE_TOON) and c:IsRitualMonster())) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) and c:IsLocation(LOCATION_HAND)
end
--Tribute filter - Toon type monsters only
function s.tribfilter(c)
	return c:IsType(TYPE_TOON) and c:IsLevelAbove(0)
end
--Check if ritual summon is possible
function s.risfilter(c,e,tp)
	if not s.ritfilter(c,e,tp) then return false end
	local mg=Duel.GetMatchingGroup(s.tribfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,c)
	if mg:GetCount()==0 then return false end
	if c:GetLevel()==0 then
		return true
	else
		return mg:CheckWithSumGreater(Card.GetLevel,c:GetLevel())
	end
end
--Ritual Summon target
function s.ristg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		return ft>0 and Duel.IsExistingMatchingCard(s.risfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end
--Ritual Summon operation
function s.risop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
	if #tg==0 then return end
	local tc=tg:GetFirst()
	local rlv=tc:GetLevel()
	local mg=Duel.GetMatchingGroup(s.tribfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,tc)
	if mg:GetCount()==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local mat
	if rlv==0 then
		mat=mg:Select(tp,1,1,nil)
	else
		mat=mg:SelectWithSumGreater(tp,Card.GetLevel,rlv)
	end
	if mat:GetCount()>0 then
		tc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
		Duel.BreakEffect()
		if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			tc:CompleteProcedure()
		end
	end
end