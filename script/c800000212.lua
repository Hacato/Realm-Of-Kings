--Imaginary Arc Turbulence
--Scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
	--Activate: negate summon
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_SUMMON)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.condition)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON)
	c:RegisterEffect(e2)
end
s.listed_series={0x79b,0x80b}

function s.gyfilter(c)
	return c:IsMonster() and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsDefense(500)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return ep==1-tp
		and Duel.GetCurrentChain()==0
		and Duel.IsExistingMatchingCard(s.gyfilter,tp,LOCATION_GRAVE,0,1,nil)
end
function s.setfilter(c)
	return c:IsFaceup() and c:IsCanTurnSet()
end
function s.arcmetfilter(c)
	return c:IsFaceup() and c:IsMonster() and (c:IsSetCard(0x79b) or c:IsSetCard(0x80b))
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,#eg,0,0)
	if Duel.GetMatchingGroupCount(s.arcmetfilter,tp,LOCATION_MZONE,0,nil)>=2
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) then
		Duel.SetPossibleOperationInfo(0,CATEGORY_POSITION,nil,1,PLAYER_ALL,LOCATION_MZONE)
	end
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateSummon(eg)~=0 then
		if Duel.GetMatchingGroupCount(s.arcmetfilter,tp,LOCATION_MZONE,0,nil)>=2
			and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
			and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
			local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
			if #g>0 then
				Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)
			end
		end
	end
end