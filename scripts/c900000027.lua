--Sword of The Ashened
--Equip Spell
local s,id=GetID()
function s.initial_effect(c)
	--Activate (Equip manually from hand)
	local e0=Effect.CreateEffect(c)
	e0:SetCategory(CATEGORY_EQUIP)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	e0:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e0:SetTarget(s.target)
	e0:SetOperation(s.activate)
	c:RegisterEffect(e0)
	
	--Equip limit
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EQUIP_LIMIT)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetValue(s.eqlimit)
	c:RegisterEffect(e1)
	
	--Equip from Hand/GY when Ashened Fusion is summoned
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_HAND+LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.equipcon)
	e2:SetTarget(s.equiptg)
	e2:SetOperation(s.equipop)
	c:RegisterEffect(e2)
	
	--Special Summon when sent to GY
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
	
	--Grant protection effects to equipped monster
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_EQUIP)
	e4:SetRange(LOCATION_SZONE)
	e4:SetOperation(s.protectop)
	c:RegisterEffect(e4)
end

--Manual equip target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.eqfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

--Manual equip operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if e:GetHandler():IsRelateToEffect(e) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.Equip(tp,e:GetHandler(),tc)
	end
end

--Equip limit: DARK AND PYRO (changed from OR to AND)
function s.eqlimit(e,c)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_PYRO)
end

--Protection effects operation
function s.protectop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=c:GetEquipTarget()
	if not tc or eg:GetFirst()~=c then return end
	
	--Cannot leave the field (complete protection)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_RELEASE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
	--Cannot be tributed
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UNRELEASABLE_SUM)
	e2:SetValue(1)
	tc:RegisterEffect(e2)
	local e3=e1:Clone()
	e3:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	e3:SetValue(1)
	tc:RegisterEffect(e3)
	--Cannot be used as material
	local e4=e1:Clone()
	e4:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e4:SetValue(1)
	tc:RegisterEffect(e4)
	local e5=e1:Clone()
	e5:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	e5:SetValue(1)
	tc:RegisterEffect(e5)
	local e6=e1:Clone()
	e6:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	e6:SetValue(1)
	tc:RegisterEffect(e6)
	local e7=e1:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e7:SetValue(1)
	tc:RegisterEffect(e7)
	--Cannot be destroyed by battle
	local e8=e1:Clone()
	e8:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e8:SetValue(1)
	tc:RegisterEffect(e8)
	--Cannot be destroyed by effect
	local e9=e1:Clone()
	e9:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e9:SetValue(1)
	tc:RegisterEffect(e9)
	--Cannot be banished
	local e10=e1:Clone()
	e10:SetCode(EFFECT_CANNOT_REMOVE)
	e10:SetValue(1)
	tc:RegisterEffect(e10)
	--Cannot be targeted
	local e11=e1:Clone()
	e11:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e11:SetValue(1)
	tc:RegisterEffect(e11)
	--Cannot be sent to GY (except by this card's own effect)
	local e12=e1:Clone()
	e12:SetCode(EFFECT_CANNOT_TO_GRAVE)
	e12:SetValue(1)
	tc:RegisterEffect(e12)
	--Cannot be returned to hand/deck
	local e13=e1:Clone()
	e13:SetCode(EFFECT_CANNOT_TO_HAND)
	e13:SetValue(1)
	tc:RegisterEffect(e13)
	local e14=e1:Clone()
	e14:SetCode(EFFECT_CANNOT_TO_DECK)
	e14:SetValue(1)
	tc:RegisterEffect(e14)
	
	--Grant Quick Effect to the equipped monster
	local e15=Effect.CreateEffect(c)
	e15:SetDescription(aux.Stringid(id,2))
	e15:SetCategory(CATEGORY_DESTROY+CATEGORY_HANDES)
	e15:SetType(EFFECT_TYPE_QUICK_O)
	e15:SetCode(EVENT_CHAINING)
	e15:SetRange(LOCATION_MZONE)
	e15:SetCountLimit(1)
	e15:SetCondition(s.qecon)
	e15:SetTarget(s.qetg)
	e15:SetOperation(s.qeop)
	e15:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e15)
end

--Condition: Ashened Fusion Monster summoned
function s.equipcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

function s.cfilter(c,tp)
	return c:IsSetCard(0x1a5) and c:IsType(TYPE_FUSION) and c:IsControler(tp) and c:IsFaceup()
end

--Filter for equip target (DARK AND PYRO)
function s.eqfilter(c)
	return c:IsFaceup() and c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_PYRO)
end

--Target for equip from Hand/GY
function s.equiptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.eqfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,e:GetHandler(),1,0,0)
end

--Operation: Equip from Hand/GY
function s.equipop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.Equip(tp,c,tc)
	end
end

--Condition for Special Summon (must be sent from field)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD)
end

--Filter for Special Summon (DARK AND PYRO, excluding previously equipped)
function s.spfilter(c,e,tp,exc)
	return c:IsAttribute(ATTRIBUTE_DARK) and c:IsRace(RACE_PYRO)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and c~=exc
end

--Target for Special Summon from GY
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local exc=e:GetHandler():GetPreviousEquipTarget()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,exc) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
	e:SetLabelObject(exc)
end

--Operation: Special Summon
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local exc=e:GetLabelObject()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,0,1,1,nil,e,tp,exc)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

--Condition: Opponent activates Spell/Trap that affects monster on field
function s.qecon(e,tp,eg,ep,ev,re,r,rp)
	if not re:IsActiveType(TYPE_SPELL+TYPE_TRAP) or rp==tp then return false end
	
	--Check if it targets a monster
	if re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then
		local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
		if tg and tg:IsExists(Card.IsLocation,1,nil,LOCATION_MZONE) then
			return true
		end
	end
	
	--Check if it affects monsters without targeting
	if re:IsHasCategory(CATEGORY_DESTROY) or re:IsHasCategory(CATEGORY_REMOVE) 
		or re:IsHasCategory(CATEGORY_TOHAND) or re:IsHasCategory(CATEGORY_TODECK)
		or re:IsHasCategory(CATEGORY_TOGRAVE) or re:IsHasCategory(CATEGORY_CONTROL)
		or re:IsHasCategory(CATEGORY_DISABLE) or re:IsHasCategory(CATEGORY_NEGATE)
		or re:IsHasCategory(CATEGORY_POSITION) or re:IsHasCategory(CATEGORY_ATKCHANGE)
		or re:IsHasCategory(CATEGORY_DEFCHANGE) then
		return true
	end
	
	return false
end

--Target for Quick Effect
function s.qetg(e,tp,eg,ep,ev,re,r,rp,chk)
	local b1=Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0
	local b2=Duel.IsExistingMatchingCard(nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil)
	if chk==0 then return b1 or b2 end
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	elseif b1 then
		op=0
	else
		op=1
	end
	e:SetLabel(op)
	if op==0 then
		Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,1-tp,1)
	else
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
	end
end

--Operation for Quick Effect
function s.qeop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetLabel()==0 then
		local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
		if #g>0 then
			local sg=g:RandomSelect(tp,1)
			Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
		if #g>0 then
			Duel.Destroy(g,REASON_EFFECT)
		end
	end
end