--Dark Scorpion Heist
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	--Banish from opponent's Deck
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_REMOVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_BATTLE_DAMAGE)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.rmcon)
	e2:SetTarget(s.rmtg)
	e2:SetOperation(s.rmop)
	c:RegisterEffect(e2)
	--Apply effect
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_SZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id)
	e3:SetTarget(s.applytg)
	e3:SetOperation(s.applyop)
	c:RegisterEffect(e3)
	--Set from Deck when this card leaves the field
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e4:SetCode(EVENT_LEAVE_FIELD)
	e4:SetCountLimit(1,{id,1})
	e4:SetCondition(s.setcon)
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)
end
s.listed_names={76922029,800000179,800000180,210490001} --Don Zaloog, Jeff the Assassin, Kafka the Ambush, custom card
s.listed_series={0x1a} --Dark Scorpion

--Banish condition: Don Zaloog or Dark Scorpion inflicts battle damage
function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=eg:GetFirst()
	return ep~=tp and rc:IsControler(tp) and (rc:IsCode(76922029) or rc:IsSetCard(0x1a))
end
--Filter for counting different Dark Scorpion monsters
function s.countfilter(c)
	return c:IsFaceup() and (c:IsCode(76922029) or (c:IsSetCard(0x1a) and c:IsType(TYPE_MONSTER)))
end
--Banish target
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.countfilter,tp,LOCATION_MZONE,0,nil)
	local ct=g:GetClassCount(Card.GetCode)
	if chk==0 then return ct>0 and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>=ct 
		and Duel.GetDecktopGroup(1-tp,ct):FilterCount(Card.IsAbleToRemove,nil)==ct end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,ct,1-tp,LOCATION_DECK)
end
--Banish operation
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.countfilter,tp,LOCATION_MZONE,0,nil)
	local ct=g:GetClassCount(Card.GetCode)
	local rg=Duel.GetDecktopGroup(1-tp,ct)
	if #rg==ct then
		Duel.DisableShuffleCheck()
		Duel.Remove(rg,POS_FACEDOWN,REASON_EFFECT)
	end
end

--Apply effect filter: Dark Scorpion that hasn't attacked
function s.applyfilter(c)
	return c:GetAttackAnnouncedCount()==0 and c:IsFaceup() and (c:IsCode(76922029) or (c:IsSetCard(0x1a) and c:IsType(TYPE_MONSTER)))
end
--Apply effect target
function s.applytg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.applyfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.applyfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.applyfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
--Apply effect operation
function s.applyop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or tc:IsFacedown() or not tc:IsRelateToEffect(e) then return end
	
	--Take no battle damage involving it
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(3210)
	e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_NO_BATTLE_DAMAGE)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
	
	local op=0
	--Don Zaloog
	if tc:IsCode(76922029) then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(76922029,0))
		if Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 and Duel.IsPlayerCanDiscardDeck(1-tp,2) then
			op=Duel.SelectOption(tp,aux.Stringid(76922029,1),aux.Stringid(76922029,2))
		elseif Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 then
			Duel.SelectOption(tp,aux.Stringid(76922029,1))
			op=0
		else
			Duel.SelectOption(tp,aux.Stringid(76922029,2))
			op=1
		end
		if op==0 then
			local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND,nil)
			local sg=g:RandomSelect(tp,1)
			Duel.SendtoGrave(sg,REASON_DISCARD+REASON_EFFECT)
		else
			Duel.DiscardDeck(1-tp,2,REASON_EFFECT)
		end
	end
	--Dark Scorpion - Chick the Yellow
	if tc:IsCode(48768179) then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(48768179,0))
		if Duel.IsExistingMatchingCard(Card.IsAbleToDeck,tp,0,LOCATION_MZONE,1,nil)
			and Duel.IsPlayerCanDiscardDeck(1-tp,1) then
			op=Duel.SelectOption(tp,aux.Stringid(48768179,1),aux.Stringid(48768179,2))
		elseif Duel.IsPlayerCanDiscardDeck(1-tp,1) then
			Duel.SelectOption(tp,aux.Stringid(48768179,2))
			op=1
		else
			Duel.SelectOption(tp,aux.Stringid(48768179,1))
			op=0
		end
		if op==0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
			local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,0,LOCATION_MZONE,1,1,nil)
			Duel.HintSelection(g)
			Duel.SendtoDeck(g,nil,0,REASON_EFFECT)
		else
			Duel.DiscardDeck(1-tp,1,REASON_EFFECT)
		end
	end
	--Dark Scorpion - Meanae the Thorn
	if tc:IsCode(74153887) then
		if Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_DECK,0,1,nil,0x1a) and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_GRAVE,0,1,nil,0x1a) then
			op=Duel.SelectOption(tp,aux.Stringid(74153887,1),aux.Stringid(74153887,2))
		elseif Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_DECK,0,1,nil,0x1a) then
			Duel.SelectOption(tp,aux.Stringid(74153887,1))
			op=0
		elseif Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_GRAVE,0,1,nil,0x1a) then
			Duel.SelectOption(tp,aux.Stringid(74153887,2))
			op=1
		end
		if op==0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g=Duel.SelectMatchingCard(tp,Card.IsSetCard,tp,LOCATION_DECK,0,1,1,nil,0x1a)
			if #g>0 then
				Duel.SendtoHand(g,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,g)
			end
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
			local g=Duel.SelectMatchingCard(tp,Card.IsSetCard,tp,LOCATION_GRAVE,0,1,1,nil,0x1a)
			Duel.SendtoHand(g,nil,REASON_EFFECT)
		end
	end
	--Dark Scorpion - Gorg the Strong
	if tc:IsCode(6967870) then
		if Duel.IsExistingMatchingCard(Card.IsSpellTrap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) and Duel.IsPlayerCanDiscardDeck(1-tp,2) then
			op=Duel.SelectOption(tp,aux.Stringid(6967870,1),aux.Stringid(6967870,2))
		elseif Duel.IsPlayerCanDiscardDeck(1-tp,2) then
			Duel.SelectOption(tp,aux.Stringid(6967870,2))
			op=1
		else
			Duel.SelectOption(tp,aux.Stringid(6967870,1))
			op=0
		end
		if op==0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local g=Duel.SelectMatchingCard(tp,Card.IsSpellTrap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
			Duel.HintSelection(g)
			Duel.Destroy(g,REASON_EFFECT)
		else
			Duel.DiscardDeck(1-tp,2,REASON_EFFECT)
		end
	end
	--Dark Scorpion - Cliff the Trap Remover
	if tc:IsCode(61587183) then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(61587183,0))
		if Duel.IsExistingMatchingCard(Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) and Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>0 then
			op=Duel.SelectOption(tp,aux.Stringid(61587183,1),aux.Stringid(61587183,2))
		elseif Duel.GetFieldGroupCount(tp,0,LOCATION_DECK)>0 then
			Duel.SelectOption(tp,aux.Stringid(61587183,2))
			op=1
		else
			Duel.SelectOption(tp,aux.Stringid(61587183,1))
			op=0
		end
		if op==0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
			local g=Duel.SelectMatchingCard(tp,Card.IsAbleToHand,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
			Duel.HintSelection(g)
			Duel.SendtoHand(g,nil,REASON_EFFECT)
		else
			local g=Duel.GetDecktopGroup(1-tp,1)
			if #g>0 then
				Duel.ConfirmCards(tp,g)
				Duel.Hint(HINT_SELECTMSG,tp,0)
				local ac=Duel.SelectOption(tp,aux.Stringid(61587183,3),aux.Stringid(61587183,4))
				if ac==1 then Duel.MoveSequence(g:GetFirst(),1) end
			end
		end
	end
	--Dark Scorpion Burglars
	if tc:IsCode(40933924) then
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_TOGRAVE)
		local g=Duel.SelectMatchingCard(1-tp,Card.IsSpell,1-tp,LOCATION_DECK,0,1,1,nil)
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
	--Jeff the Assassin
	if tc:IsCode(800000179) then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(800000179,1))
		if Duel.IsExistingMatchingCard(Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,nil) then
			op=Duel.SelectOption(tp,aux.Stringid(800000179,2),aux.Stringid(800000179,3))
		else
			Duel.SelectOption(tp,aux.Stringid(800000179,2))
			op=0
		end
		if op==0 then
			Duel.Damage(1-tp,1000,REASON_EFFECT)
		else
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
			local g=Duel.SelectMatchingCard(tp,Card.IsAbleToRemove,tp,0,LOCATION_ONFIELD,1,1,nil)
			if #g>0 then
				Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
			end
		end
	end
	--Kafka the Ambush
	if tc:IsCode(800000180) then
		Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(800000180,1))
		local b1=Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0
		local b2=Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_DECK,0,1,nil,0x1a)
			and Duel.IsExistingMatchingCard(Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,nil)
		if b1 and b2 then
			op=Duel.SelectOption(tp,aux.Stringid(800000180,2),aux.Stringid(800000180,3))
		elseif b1 then
			Duel.SelectOption(tp,aux.Stringid(800000180,2))
			op=0
		elseif b2 then
			Duel.SelectOption(tp,aux.Stringid(800000180,3))
			op=1
		end
		if op==0 then
			--Opponent gives 1 card from hand
			if Duel.GetFieldGroupCount(tp,0,LOCATION_HAND)>0 then
				Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_ATOHAND)
				local g=Duel.SelectMatchingCard(1-tp,Card.IsAbleToChangeControler,1-tp,LOCATION_HAND,0,1,1,nil)
				if #g>0 then
					Duel.SendtoHand(g,tp,REASON_EFFECT)
					Duel.ConfirmCards(tp,g)
				end
			end
		else
			--Send Dark Scorpion card to GY, then take control
			if Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_DECK,0,1,nil,0x1a) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
				local tg=Duel.SelectMatchingCard(tp,Card.IsSetCard,tp,LOCATION_DECK,0,1,1,nil,0x1a)
				if #tg>0 and Duel.SendtoGrave(tg,REASON_EFFECT)>0 then
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
					local tc=Duel.SelectMatchingCard(tp,Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,1,nil):GetFirst()
					if tc then
						Duel.GetControl(tc,tp,PHASE_END,1)
					end
				end
			end
		end
	end
	--Custom card 210490001
	if tc:IsCode(210490001) then
		local g=Duel.GetMatchingGroup(s.countfilter,tp,LOCATION_MZONE,0,nil)
		local ct=g:GetClassCount(Card.GetCode)
		Duel.Draw(tp,ct,REASON_EFFECT)
	end
end

--Set from Deck condition
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousPosition(POS_FACEUP) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
--Set from Deck filter
function s.setfilter(c)
	return c:IsSetCard(0x1a) and c:IsType(TYPE_SPELL+TYPE_TRAP) and not c:IsCode(id) and c:IsSSetable()
end
--Set from Deck target
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
--Set from Deck operation
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local tc=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil):GetFirst()
	if tc and Duel.SSet(tp,tc)>0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		if tc:IsQuickPlaySpell() then
			e1:SetCode(EFFECT_QP_ACT_IN_SET_TURN)
		elseif tc:IsTrap() then
			e1:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
		end
		e1:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end