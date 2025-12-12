--Yamai Sisters - Kaguya & Yuzuru
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,4,2)
	c:EnableReviveLimit()
	--spsummon limit
	local e1=Effect.CreateEffect(c)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(aux.xyzlimit)
	c:RegisterEffect(e1)
	--attack all
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_ATTACK_ALL)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	--pos change
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_POSITION)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetCost(s.atkcost)
	e3:SetTarget(s.postg)
	e3:SetOperation(s.posop)
	c:RegisterEffect(e3)
	--Return to Extra Deck and Special Summon
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.retcon)
	e4:SetTarget(s.rettg)
	e4:SetOperation(s.retop)
	c:RegisterEffect(e4)
	--Register when Xyz Summoned or flipped
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_SPSUMMON_SUCCESS)
	e5:SetCondition(s.regcon)
	e5:SetOperation(s.regop)
	c:RegisterEffect(e5)
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e6:SetCode(EVENT_FLIP)
	e6:SetOperation(s.regop)
	c:RegisterEffect(e6)
end
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end
function s.posfilter(c)
	return c:IsPosition(POS_FACEUP_ATTACK) and c:IsCanChangePosition()
end
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.posfilter,tp,0,LOCATION_MZONE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_POSITION,nil,1,0,0)
end
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local tc=Duel.SelectMatchingCard(tp,s.posfilter,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()
	if tc and Duel.ChangePosition(tc,POS_FACEUP_DEFENSE)~=0 then
		local c=e:GetHandler()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CANNOT_CHANGE_POSITION)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_XYZ)
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end
function s.spfilter(c,e,tp)
	return c:IsType(TYPE_SPIRIT) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
end
function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,0,0)
	if Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	end
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() and Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_EFFECT)~=0 then
		local tg=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE,0,nil,e,tp)
		if #tg>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local tc=tg:Select(tp,1,1,nil):GetFirst()
			Duel.SpecialSummon(tc,0,tp,tp,true,false,POS_FACEUP)
		end
	end
end