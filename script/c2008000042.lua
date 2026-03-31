--D/D/D Martial King Achilles
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Xyz Summon procedure
	Xyz.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsRace,RACE_FIEND),7,2)
	--copy
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1)
	e1:SetHintTiming(0,TIMING_MAIN_END+TIMING_BATTLE_START+TIMING_BATTLE_END)
	e1:SetCost(aux.dxmcostgen(1,1,nil))
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--return to gy
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DAMAGE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.rtgcon)
	e2:SetCost(s.rtgcost)
	e2:SetOperation(s.rtgop)
	c:RegisterEffect(e2)
end
s.listed_series={0xaf}
s.listed_names={id}
function s.filter(c)--copy+burn
	return c:IsSetCard(0xaf) and c:IsMonster() and c:IsType(TYPE_EFFECT) and not c:IsCode(id) and c:IsAbleToRemove()
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK+LOCATION_EXTRA+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,0,tp,LOCATION_DECK+LOCATION_EXTRA+LOCATION_GRAVE)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,PLAYER_ALL,1000)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK+LOCATION_EXTRA+LOCATION_GRAVE,0,1,1,nil)
	local tc=g:GetFirst()
	local c=e:GetHandler()
	if tc and Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_REMOVED)
		and c:IsRelateToEffect(e) and c:IsFaceup() then
		local code=tc:GetOriginalCode()
		local reset_flag=RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END
		--name replace
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(reset_flag)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetValue(code)
		c:RegisterEffect(e1)
		--effect replace
		c:CopyEffect(code, reset_flag, 1)
		Duel.ConfirmCards(1-tp,tc)
	end
	--burn
	Duel.Damage(1-tp,1000,REASON_EFFECT,true)
	Duel.Damage(tp,1000,REASON_EFFECT,true)
	Duel.RDComplete()
end
function s.rtgcon(e,tp,eg,ep,ev,re,r,rp)--return to grave
	return ep==tp --and (r&REASON_BATTLE+REASON_EFFECT)~=0
end
function s.costfilter(c)
	return c:IsFaceup() and c:IsDestructable()
end
function s.rtgcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,c)
	Duel.Destroy(g,REASON_COST)
end
function s.rtgfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xaf) and c:IsMonster()
end
function s.rtgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.rtgfilter,tp,LOCATION_REMOVED,0,nil)
	if #g>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
		local sg=g:Select(tp,1,1,nil)
		Duel.HintSelection(sg)
		Duel.SendtoGrave(sg,REASON_EFFECT+REASON_RETURN)
	end
end