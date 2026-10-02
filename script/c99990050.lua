--SAO Yui - SAO
--Scripted by Raivost
local s,id=GetID()

function s.initial_effect(c)
	--(1) Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.hspcon)
	c:RegisterEffect(e1)

	--(2) If Special Summoned: Tuner OR Level 4
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.tnlvtg)
	e2:SetOperation(s.tnlvop)
	c:RegisterEffect(e2)
end

--(1) Check for an "SAO" monster that is also
--a "Kirito" or "Asuna" monster
function s.hspfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0x999)
		and (c:IsSetCard(0x300) or c:IsSetCard(0x301))
end

function s.hspcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()

	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			s.hspfilter,
			tp,
			LOCATION_MZONE,
			0,
			1,
			nil
		)
end

--(2) If Special Summoned:
--Choose Tuner OR Level 4
function s.tnlvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end

	--Existing database strings:
	--String 3 = Tuner
	--String 2 = Level 4
	local op=Duel.SelectOption(
		tp,
		aux.Stringid(id,3),
		aux.Stringid(id,2)
	)

	e:SetLabel(op)
end

function s.tnlvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) or not c:IsFaceup() then
		return
	end

	--Option 0: Treat this card as a Tuner
	if e:GetLabel()==0 then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetCode(EFFECT_ADD_TYPE)
		e1:SetValue(TYPE_TUNER)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)

	--Option 1: Make its Level become 4
	else
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(4)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end