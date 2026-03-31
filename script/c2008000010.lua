--Crimson Eclipser Vampire
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,7,2,s.ovfilter,aux.Stringid(id,0),2,s.xyzop)
	--give your "Vampires" immunity to your opp's m effs
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetHintTiming(TIMING_STANDBY_PHASE+TIMING_END_PHASE)
	e1:SetCost(s.cost)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
	--Sp Summ "Bram" up to the number of mats of this c
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_TRIGGER_O+EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_LEAVE_FIELD)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	--Record of each mat before this c leaves the field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e3:SetCode(EVENT_LEAVE_FIELD_P)
	e3:SetOperation(s.recordop)
	e3:SetLabelObject(e2)
	c:RegisterEffect(e3)
end
s.listed_names={id,38250531}
s.listed_series={SET_VAMPIRE}
function s.ovfilter(c,tp,lc)--Alternative Xyz Sum
	return c:IsFaceup() and c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,38250531)
end
function s.xyzop(e,tp,chk,mc)
	if chk==0 then return mc:CheckRemoveOverlayCard(tp,1,REASON_COST) end
	mc:RemoveOverlayCard(tp,1,1,REASON_COST)
	return true
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)--give your "Vampires" immunity to your opp's m effs
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,SET_VAMPIRE),tp,LOCATION_MZONE,0,nil)
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		--Unaffected by opp ms' effs
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(3111)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
		e1:SetRange(LOCATION_MZONE)
		e1:SetCode(EFFECT_IMMUNE_EFFECT)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e1:SetValue(s.efilter)
		tc:RegisterEffect(e1)
	end
end
function s.efilter(e,te,c)
	return te:IsActiveType(TYPE_MONSTER) and te:GetOwner()~=c
		and te:GetOwnerPlayer()~=e:GetHandlerPlayer()
end
function s.recordop(e,tp,eg,ep,ev,re,r,rp)--summon Bram and attach this card to it
	local g=e:GetHandler():GetOverlayGroup()
	g:KeepAlive()
	e:GetLabelObject():SetLabelObject(g)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousPosition(POS_FACEUP) and not e:GetHandler():IsLocation(LOCATION_DECK)
end
function s.spfilter(c,e,tp,rp)
	return c:IsCode(38250531) and Duel.GetLocationCountFromEx(tp,rp,nil,c)>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=e:GetLabelObject()
	if chk==0 then return #g>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp,rp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ct=#e:GetLabelObject()
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ct=1 end
	ct=math.min(ct,aux.CheckSummonGate(tp) or ct)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,ct,nil,e,tp,rp)
	if #g>0 then
		local count=Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		if count~=0 then
			local sg=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCode),tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,id)
			if #sg>0 then
				Duel.BreakEffect()
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
				sg=sg:Select(tp,1,count,nil)
				for oc in aux.Next(sg) do
					local tc=g:FilterSelect(tp,Card.IsLocation,1,1,nil,LOCATION_MZONE):GetFirst()
					if not tc then break end
					Duel.Overlay(tc,oc)
					g:RemoveCard(tc)
					--Unaffected by opp's c effs
					local e1=Effect.CreateEffect(e:GetHandler())
					e1:SetDescription(3110)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_IMMUNE_EFFECT)
					e1:SetRange(LOCATION_MZONE)
					e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CLIENT_HINT)
					e1:SetValue(s.efilter2)
					e1:SetOwnerPlayer(tp)
					e1:SetReset(RESET_EVENT+RESETS_STANDARD)
					tc:RegisterEffect(e1,true)
				end
			end
		end
	end
end
function s.efilter2(e,re)
	return e:GetOwnerPlayer()~=re:GetOwnerPlayer()
end