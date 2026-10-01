--SAO Game Master Rule
--Scripted by Raivost
local s,id=GetID()

function s.initial_effect(c)
	--(1) Activate
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--(2) Once per Chain: negate 1 opponent's monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(s.negcon)
	e2:SetCost(s.negcost)
	e2:SetTarget(s.negtg)
	e2:SetOperation(s.negop)
	c:RegisterEffect(e2)
end

--(1) When this card is activated:
--Opponent's monsters in the GY cannot activate
--their effects for the rest of this turn
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)

	--Mark this card as already face-up
	c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1)
end

function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
		and re:GetActivateLocation()==LOCATION_GRAVE
end

--(2) Only usable after this card's activation has resolved
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(id)>0
end

--Remove 3 EN-Counters from your field
--Once per Chain
function s.negcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:GetFlagEffect(id+1)==0
			and Duel.IsCanRemoveCounter(
				tp,
				1,
				0,
				0x1994,
				3,
				REASON_COST
			)
	end

	Duel.RemoveCounter(
		tp,
		1,
		0,
		0x1994,
		3,
		REASON_COST
	)

	--Prevents another activation during the same Chain
	c:RegisterFlagEffect(id+1,RESET_CHAIN,0,1)
end

--Target 1 face-up monster your opponent controls
function s.negfilter(c)
	return c:IsFaceup()
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.negfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.negfilter,
			tp,
			0,
			LOCATION_MZONE,
			1,
			nil
		)
	end

	Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(id,1))
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(
		tp,
		s.negfilter,
		tp,
		0,
		LOCATION_MZONE,
		1,
		1,
		nil
	)
end

--Negate its effects until the end of this turn
function s.negop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()

	if not tc
		or not tc:IsRelateToEffect(e)
		or not tc:IsFaceup()
	then
		return
	end

	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetReset(
		RESET_EVENT+
		RESETS_STANDARD+
		RESET_PHASE+
		PHASE_END
	)
	tc:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	e2:SetValue(RESET_TURN_SET)
	tc:RegisterEffect(e2)
end