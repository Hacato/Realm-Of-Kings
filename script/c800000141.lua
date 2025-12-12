--SZS Disharmony Omen
local s,id=GetID()
function s.initial_effect(c)
	--Negate activation and declare attack
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)
end
s.listed_series={0x2406}

--Check if you control a "SZS" monster
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsSetCard,0x2406),tp,LOCATION_MZONE,0,1,nil)
		and (re:IsActiveType(TYPE_MONSTER) or re:IsHasType(EFFECT_TYPE_ACTIVATE)) and Duel.IsChainNegatable(ev)
		and rp==1-tp
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	--Negate the activation
	if Duel.NegateActivation(ev) then
		--Check if you control a "SZS" monster and opponent has face-up monsters
		local ag=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsSetCard,0x2406),tp,LOCATION_MZONE,0,nil)
		local tg=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		if #ag>0 and #tg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATTACK)
			local atk=ag:Select(tp,1,1,nil):GetFirst()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
			local def=tg:Select(tp,1,1,nil)
			if atk and #def>0 then
				local tc=def:GetFirst()
				--Perform battle damage calculation
				Duel.CalculateDamage(atk,tc)
			end
		end
		--Register effect to search when any opponent's monster is destroyed by battle this turn
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e1:SetCode(EVENT_BATTLE_DESTROYED)
		e1:SetCondition(s.thcon)
		e1:SetOperation(s.thop)
		e1:SetReset(RESET_PHASE+PHASE_END)
		Duel.RegisterEffect(e1,tp)
	end
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return c:IsControler(1-tp) end,1,nil)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFlagEffect(tp,id)>0 then return end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	Duel.Hint(HINT_CARD,0,id)
	local sg=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #sg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local thg=sg:Select(tp,1,1,nil)
		if #thg>0 then
			Duel.SendtoHand(thg,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,thg)
		end
	end
end

--Search filter: "SZS" Spell/Trap except "SZS Disharmony Omen"
function s.thfilter(c)
	return c:IsSetCard(0x2406) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand() and not c:IsCode(id)
end