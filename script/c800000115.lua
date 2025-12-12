--Vegetation of Blisstopia
local s,id=GetID()
function s.initial_effect(c)
	--Activate: Special Summon Wyrm from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	--Non-Wyrm monsters lose ATK/DEF
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,LOCATION_MZONE)
	e2:SetTarget(s.atktg)
	e2:SetValue(-500)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e3)
	--Activate "Blisstopia" Field Spell from Deck
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_END)
	e4:SetRange(LOCATION_FZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.fscon)
	e4:SetCost(s.fscost)
	e4:SetTarget(s.fstg)
	e4:SetOperation(s.fsop)
	c:RegisterEffect(e4)
end
s.listed_names={id}
s.listed_series={0x1569} --Blisstopia
--Activation: Special Summon Wyrm from hand
function s.tgfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_WYRM) and c:IsAttribute(ATTRIBUTE_EARTH)
end
function s.spfilter(c,e,tp,atk)
	return c:IsRace(RACE_WYRM) and c:IsAttackBelow(atk-1) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spfilter_check(c,e,tp)
	return c:IsRace(RACE_WYRM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.tgfilter(chkc) end
	if chk==0 then return true end
	local valid_target=Duel.IsExistingTarget(s.tgfilter,tp,LOCATION_MZONE,0,1,nil)
	local has_space=Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	local has_monster=Duel.IsExistingMatchingCard(s.spfilter_check,tp,LOCATION_HAND,0,1,nil,e,tp)
	if valid_target and has_space and has_monster and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		Duel.SelectTarget(tp,s.tgfilter,tp,LOCATION_MZONE,0,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
	end
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	if not Duel.IsExistingTarget(Card.IsRelateToEffect,tp,LOCATION_MZONE,0,1,nil,e) then return end
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local atk=tc:GetAttack()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp,atk)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end
--Non-Wyrm monsters lose ATK/DEF
function s.atktg(e,c)
	return not c:IsRace(RACE_WYRM)
end
--Activate "Blisstopia" Field Spell from Deck
function s.fscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()==tp
end
function s.fscost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end
function s.fsfilter(c,tp)
	return c:IsSetCard(0x1569) and c:IsType(TYPE_FIELD) and not c:IsCode(id)
		and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.fstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.fsfilter,tp,LOCATION_DECK,0,1,nil,tp) end
end
function s.fsop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,s.fsfilter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if tc then
		local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		if fc then
			Duel.SendtoGrave(fc,REASON_RULE)
			Duel.BreakEffect()
		end
		Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		local te=tc:GetActivateEffect()
		te:UseCountLimit(tp,1,true)
		local tep=tc:GetControler()
		local cost=te:GetCost()
		if cost then cost(te,tep,eg,ep,ev,re,r,rp,1) end
		Duel.RaiseEvent(tc,4179255,te,0,tp,tp,Duel.GetCurrentChain())
	end
end