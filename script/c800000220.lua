--Imaginary Arc Tower
local s,id=GetID()
local SET_IMAGINARY_ARC=0x79b
local SET_METARION=0x179

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.acttg)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)

	--"Imaginary Arc" and "Metarion" monsters cannot be destroyed by card effects
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.indtg)
	e2:SetValue(1)
	c:RegisterEffect(e2)

	--Standby Phase: Declare 1 Type
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetOperation(s.declop)
	c:RegisterEffect(e3)

	--Opponent's non-Machine monsters lose ATK while you control a "Metarion"
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_UPDATE_ATTACK)
	e4:SetRange(LOCATION_FZONE)
	e4:SetTargetRange(0,LOCATION_MZONE)
	e4:SetCondition(s.atkcon)
	e4:SetTarget(s.atktg)
	e4:SetValue(s.atkval)
	c:RegisterEffect(e4)
end

s.listed_series={SET_IMAGINARY_ARC,SET_METARION}

function s.actfilter(c)
	return c:IsMonster()
		and (c:IsSetCard(SET_IMAGINARY_ARC) or (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsDefense(500)))
		and (c:IsAbleToHand() or c:IsAbleToGrave())
end

function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.actfilter,tp,LOCATION_DECK,0,1,nil)
	end
end

function s.actop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local g=Duel.SelectMatchingCard(tp,s.actfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if not tc then return end

	local b1=tc:IsAbleToHand()
	local b2=tc:IsAbleToGrave()
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,1),aux.Stringid(id,2))
	elseif b1 then
		op=0
	else
		op=1
	end

	if op==0 then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	else
		Duel.SendtoGrave(tc,REASON_EFFECT)
	end
end

function s.indtg(e,c)
	return c:IsFaceup() and (c:IsSetCard(SET_IMAGINARY_ARC) or c:IsSetCard(SET_METARION))
end

function s.declop(e,tp,eg,ep,ev,re,r,rp)
	local rc=Duel.AnnounceRace(tp,1,RACE_ALL)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetOperation(s.raceop)
	e1:SetLabel(rc)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

function s.spfilter(c,tp)
	return c:IsControler(1-tp)
		and c:IsSummonLocation(LOCATION_DECK+LOCATION_EXTRA)
		and c:IsFaceup()
end

function s.raceop(e,tp,eg,ep,ev,re,r,rp)
	local rc=e:GetLabel()
	local g=eg:Filter(s.spfilter,nil,tp)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_ADD_RACE)
		e1:SetValue(rc)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end

function s.metfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_METARION)
end

function s.atkcon(e)
	local tp=e:GetHandlerPlayer()
	return Duel.IsExistingMatchingCard(s.metfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.atktg(e,c)
	return c:IsFaceup() and not c:IsRace(RACE_MACHINE)
end

function s.atkval(e,c)
	local tp=e:GetHandlerPlayer()
	local ct=Duel.GetMatchingGroupCount(s.metfilter,tp,LOCATION_MZONE,0,nil)
	return ct*-300
end