local s,id=GetID()
local COUNTER_BIG_DIPPER=0x204

function s.initial_effect(c)
	--Activate: Special Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--You can only control 1
	c:SetUniqueOnField(1,0,id)

	--Tribute trigger
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_RELEASE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.lvcon_release)
	e2:SetTarget(s.lvtg)
	e2:SetOperation(s.lvop)
	c:RegisterEffect(e2)

	--Material trigger (except Synchro)
	local e3=e2:Clone()
	e3:SetCode(EVENT_BE_MATERIAL)
	e3:SetCondition(s.lvcon_material)
	c:RegisterEffect(e3)

	--Destruction replacement
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EFFECT_DESTROY_REPLACE)
	e4:SetRange(LOCATION_SZONE)
	e4:SetTarget(s.reptg)
	e4:SetValue(s.repval)
	e4:SetOperation(s.repop)
	c:RegisterEffect(e4)
end

s.listed_series={0x165}
s.counter_list={COUNTER_BIG_DIPPER}

--Special Summon on activation
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x165) and c:IsLevelAbove(7)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Shared Level calculation
function s.sumlevels(g,tp)
	local lv=0
	for tc in aux.Next(g) do
		if tc:IsPreviousControler(tp)
			and tc:IsPreviousLocation(LOCATION_HAND+LOCATION_MZONE)
			and tc:IsSetCard(0x165)
			and tc:IsMonster() then
			local plv=tc:GetPreviousLevelOnField()
			if plv<=0 then plv=tc:GetLevel() end
			lv=lv+plv
		end
	end
	return lv
end

--Tribute condition
function s.lvcon_release(e,tp,eg,ep,ev,re,r,rp)
	return s.sumlevels(eg,tp)>0
end

--Material condition (no Synchro)
function s.lvcon_material(e,tp,eg,ep,ev,re,r,rp)
	if (r&REASON_SYNCHRO)~=0 then return false end
	return (r&(REASON_FUSION+REASON_XYZ+REASON_LINK))~=0
		and s.sumlevels(eg,tp)>0
end

--Target
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE)
			and chkc:IsControler(tp)
			and chkc:IsFaceup()
	end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
	e:SetLabel(s.sumlevels(eg,tp))
end

--Apply ATK/DEF changes
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local lv=e:GetLabel()
	if lv<=0 then return end

	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e)) then return end

	local val=lv*100

	--Your monster gains
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(val)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	tc:RegisterEffect(e2)

	--Opponent monsters lose
	local og=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
	for oc in aux.Next(og) do
		local e3=e1:Clone()
		e3:SetValue(-val)
		oc:RegisterEffect(e3)
		local e4=e2:Clone()
		e4:SetValue(-val)
		oc:RegisterEffect(e4)
	end
end

--Destruction replacement
function s.repfilter(c,tp)
	return c:IsFaceup()
		and c:IsControler(tp)
		and c:IsLocation(LOCATION_MZONE)
		and c:IsReason(REASON_BATTLE+REASON_EFFECT)
		and not c:IsReason(REASON_REPLACE)
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(s.repfilter,1,nil,tp)
			and Duel.IsCanRemoveCounter(tp,LOCATION_ONFIELD,0,COUNTER_BIG_DIPPER,2,REASON_EFFECT)
	end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),96)
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.RemoveCounter(tp,LOCATION_ONFIELD,0,COUNTER_BIG_DIPPER,2,REASON_EFFECT)
	Duel.Hint(HINT_CARD,0,id)
end
