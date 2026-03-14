--Order Up Tatsugiri
local s,id=GetID()
function s.initial_effect(c)

	--(1) Activate effect: send Tatsugiri to GY and destroy accordingly
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--(2) GY revive (Quick Effect, can be activated anytime)
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)        -- Quick Effect
	e2:SetCode(EVENT_FREE_CHAIN)            -- Can be activated anytime
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)

end

--────────────────────────────
--(1) Target Dondozo
--────────────────────────────
function s.dondozofilter(c)
	return c:IsFaceup() and c:IsSetCard(0x14A2)
end

function s.tatsugirifilter(c)
	return c:IsLevel(4) and c:IsSetCard(0x24A2) and c:IsAbleToGrave()
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.dondozofilter(chkc) end
	if chk==0 then
		return Duel.IsExistingTarget(s.dondozofilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.tatsugirifilter,tp,LOCATION_DECK+LOCATION_SZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.dondozofilter,tp,LOCATION_MZONE,0,1,1,nil)
end

--────────────────────────────
--(1) Send Tatsugiri and destroy effect
--────────────────────────────
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tatsugirifilter,tp,LOCATION_DECK+LOCATION_SZONE,0,1,1,nil)
	local sc=g:GetFirst()
	if not sc then return end

	if Duel.SendtoGrave(sc,REASON_EFFECT)==0 then return end

	local id=sc:GetOriginalCode()

	--Curly Tatsugiri
	if id==800000191 then
		local atk=tc:GetAttack()
		local dg=Duel.GetMatchingGroup(function(c)
			return c:IsFaceup() and c:IsAttackBelow(atk)
		end,tp,0,LOCATION_MZONE,nil)
		Duel.Destroy(dg,REASON_EFFECT)

	--Droopy Tatsugiri
	elseif id==800000190 then
		local def=tc:GetDefense()
		local dg=Duel.GetMatchingGroup(function(c)
			return c:IsFaceup() and c:IsDefenseBelow(def)
		end,tp,0,LOCATION_MZONE,nil)
		Duel.Destroy(dg,REASON_EFFECT)

	--Stretchy Tatsugiri
	elseif id==800000192 then
		local dg=Duel.GetMatchingGroup(Card.IsSpellTrap,tp,0,LOCATION_ONFIELD,nil)
		Duel.Destroy(dg,REASON_EFFECT)
	end
end

--────────────────────────────
--(2) GY Special Summon
--────────────────────────────
function s.spfilter(c,e,tp)
	return c:IsCode(800000189) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end