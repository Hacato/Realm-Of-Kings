--Fate Ascended Rider, Iskandar
local s,id=GetID()
function s.initial_effect(c)
	--Cannot be Normal Summoned/Set
	c:EnableReviveLimit()
	--Must be Special Summoned by "Fate Rider, Iskandar"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)
	--Effect 1: Reveal to add "Fate Rider, Iskandar" from Deck, shuffle this back
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.thcost)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--Effect 2: Equip top card of Deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)
	--Effect 3: Return equipped cards to hand when this card leaves the field
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_LEAVE_FIELD_P)
	e3:SetOperation(s.checkop)
	c:RegisterEffect(e3)
	local e3b=Effect.CreateEffect(c)
	e3b:SetDescription(aux.Stringid(id,2))
	e3b:SetCategory(CATEGORY_TOHAND)
	e3b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3b:SetCode(EVENT_LEAVE_FIELD)
	e3b:SetLabelObject(e3)
	e3b:SetCondition(s.retcon)
	e3b:SetTarget(s.rettg)
	e3b:SetOperation(s.retop)
	c:RegisterEffect(e3b)
	--Effect 4: Equip opponent's monster when they activate effect (Quick Effect)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,3))
	e4:SetCategory(CATEGORY_EQUIP)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetCondition(s.qeqcon)
	e4:SetTarget(s.qeqtg)
	e4:SetOperation(s.qeqop)
	c:RegisterEffect(e4)
	--Effect 5: Place Relic Counter on Field Spell when leaving field
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(id,4))
	e5:SetCategory(CATEGORY_COUNTER)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_LEAVE_FIELD)
	e5:SetCondition(s.ctcon)
	e5:SetOperation(s.ctop)
	c:RegisterEffect(e5)
end
s.listed_names={800000075}
s.counter_place_list={0x1997}

--Special Summon limit: Only by "Fate Rider, Iskandar"
function s.splimit(e,se,sp,st)
	return se:GetHandler():IsCode(800000075)
end

--Effect 1: Add "Fate Rider, Iskandar" from Deck
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
end
function s.thfilter(c)
	return c:IsCode(800000075) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		local c=e:GetHandler()
		if c:IsRelateToEffect(e) and c:IsLocation(LOCATION_HAND) then
			Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

--Effect 2: Equip top card of Deck
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>0 end
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_DECK)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	local tc=Duel.GetDecktopGroup(tp,1):GetFirst()
	if tc and tc:IsMonster() then
		local atk=tc:GetAttack()
		local def=tc:GetDefense()
		if Duel.Equip(tp,tc,c) then
			--Equip limit
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_EQUIP_LIMIT)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD)
			e1:SetValue(s.eqlimit)
			e1:SetLabelObject(c)
			tc:RegisterEffect(e1)
			--Mark as equipped by Effect 2
			tc:RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD,0,0)
			--Grant ATK/DEF boost
			if atk>0 then
				local e2=Effect.CreateEffect(c)
				e2:SetType(EFFECT_TYPE_SINGLE)
				e2:SetCode(EFFECT_UPDATE_ATTACK)
				e2:SetValue(atk//2)
				e2:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e2)
			end
			if def>0 then
				local e3=Effect.CreateEffect(c)
				e3:SetType(EFFECT_TYPE_SINGLE)
				e3:SetCode(EFFECT_UPDATE_DEFENSE)
				e3:SetValue(def//2)
				e3:SetReset(RESET_EVENT+RESETS_STANDARD)
				c:RegisterEffect(e3)
			end
		end
	elseif tc then
		--Still equip non-monsters but no boost
		Duel.Equip(tp,tc,c)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(c)
		tc:RegisterEffect(e1)
		--Mark as equipped by Effect 2
		tc:RegisterFlagEffect(id+100,RESET_EVENT+RESETS_STANDARD,0,0)
	end
end
function s.eqlimit(e,c)
	return c==e:GetLabelObject()
end

--Effect 3: Return equipped cards to hand
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetEquipGroup():Filter(Card.HasFlagEffect,nil,id+100)
	if #g>0 then
		g:KeepAlive()
		e:SetLabelObject(g)
	else
		e:SetLabelObject(nil)
	end
end
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	local label=e:GetLabelObject()
	if not label then return false end
	local g=label:GetLabelObject()
	return g and #g>0
end
function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g=e:GetLabelObject():GetLabelObject()
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,#g,0,0)
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local label=e:GetLabelObject()
	if not label then return end
	local g=label:GetLabelObject()
	if g and #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		g:DeleteGroup()
	end
end

--Effect 4: Equip opponent's monster when they activate effect (Quick Effect)
function s.qeqcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==1-tp and re:IsMonsterEffect() and rc:IsLocation(LOCATION_HAND+LOCATION_MZONE) and rc:IsRelateToEffect(re)
end
function s.qeqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and rc:IsAbleToChangeControler() end
	Duel.SetTargetCard(rc)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,rc,1,0,0)
end
function s.qeqop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and c:IsRelateToEffect(e) and c:IsFaceup()) then return end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	if Duel.Equip(tp,tc,c,true) then
		--Equip limit
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(s.eqlimit)
		e1:SetLabelObject(c)
		tc:RegisterEffect(e1)
		--Opponent cannot Summon cards with same name
		local code=tc:GetCode()
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_FIELD)
		e2:SetCode(EFFECT_CANNOT_SUMMON)
		e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE)
		e2:SetRange(LOCATION_MZONE)
		e2:SetTargetRange(0,1)
		e2:SetLabel(code)
		e2:SetTarget(s.sumlimit)
		e2:SetCondition(s.sumcon)
		e2:SetLabelObject(tc)
		c:RegisterEffect(e2)
		local e3=e2:Clone()
		e3:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
		c:RegisterEffect(e3)
		local e4=e2:Clone()
		e4:SetCode(EFFECT_CANNOT_FLIP_SUMMON)
		c:RegisterEffect(e4)
	end
end
function s.sumcon(e)
	local tc=e:GetLabelObject()
	local c=e:GetHandler()
	return tc and tc:IsLocation(LOCATION_SZONE) and tc:GetEquipTarget()==c
end
function s.sumlimit(e,c)
	return c:IsCode(e:GetLabel())
end

--Effect 5: Place Relic Counter on Field Spell
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousPosition(POS_FACEUP)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_FZONE,0,nil)
	local tc=g:GetFirst()
	while tc do
		if tc:IsSetCard(0x989) then --"Fate" archetype setcode (adjust if different)
			tc:AddCounter(0x1997,1)
		end
		tc=g:GetNext()
	end
end