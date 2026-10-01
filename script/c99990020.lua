--SAO Asuna-SAO
--Scripted by Raivost
local s,id=GetID()

function s.initial_effect(c)
	--(1) Gain search effect during the turn this card was Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetOperation(s.geop)
	c:RegisterEffect(e1)

	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	--(2) Change attacked monster to Defense Position and reduce its DEF
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_POSITION+CATEGORY_DEFCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_START)
	e3:SetCost(s.poscost)
	e3:SetTarget(s.postg)
	e3:SetOperation(s.posop)
	c:RegisterEffect(e3)
end

s.listed_names={99990020,99990050}

--(1) During the turn this card was Normal or Special Summoned,
--gain an Ignition Effect that searches SAO Yui-SAO
function s.geop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

--Search SAO Yui-SAO
function s.thfilter(c)
	return c:IsCode(99990050) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(id,0))
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstMatchingCard(s.thfilter,tp,LOCATION_DECK,0,nil)
	if tc then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end

--(2) Remove 1 EN-Counter from your field
function s.poscost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsCanRemoveCounter(tp,1,0,0x1994,1,REASON_COST)
	end
	Duel.RemoveCounter(tp,1,0,0x1994,1,REASON_COST)
end

--Must be Asuna attacking an opponent's Attack Position monster
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local d=Duel.GetAttackTarget()

	if chk==0 then
		return Duel.GetAttacker()==c
			and d
			and d:IsControler(1-tp)
			and d:IsAttackPos()
			and d:IsCanChangePosition()
	end

	Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(id,1))
	Duel.SetTargetCard(d)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,d,1,0,0)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local d=Duel.GetFirstTarget()
	if not d or not d:IsRelateToEffect(e) or not d:IsAttackPos() then
		return
	end

	--Only reduce DEF if the position change succeeds
	if Duel.ChangePosition(d,POS_FACEUP_DEFENSE)>0 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_DEFENSE)
		e1:SetValue(-700)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		d:RegisterEffect(e1)
	end
end