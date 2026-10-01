--SAO Aincrad
--Scripted by Raivost
--Updated for EN-Counter 0x1994
local s,id=GetID()

function s.initial_effect(c)
	--Enable EN-Counters
	c:EnableCounterPermit(0x1994)

	--(0) Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--(1) Place EN-Counter(s) when opponent Normal Summons
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetRange(LOCATION_FZONE)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	--Place EN-Counter(s) when opponent Special Summons
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	--(2) "SAO" monsters gain ATK
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_UPDATE_ATTACK)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_MZONE,0)
	e3:SetTarget(s.statfilter)
	e3:SetValue(s.statval)
	c:RegisterEffect(e3)

	--"SAO" monsters gain DEF
	local e4=e3:Clone()
	e4:SetCode(EFFECT_UPDATE_DEFENSE)
	c:RegisterEffect(e4)

	--(3) Destruction replacement
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e5:SetCode(EFFECT_DESTROY_REPLACE)
	e5:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e5:SetRange(LOCATION_FZONE)
	e5:SetCountLimit(1)
	e5:SetTarget(s.reptg)
	e5:SetOperation(s.repop)
	c:RegisterEffect(e5)
end

--(1) Count monsters Summoned to opponent's field
function s.ctfilter(c,tp)
	return c:IsControler(1-tp)
		and c:IsLocation(LOCATION_MZONE)
end

function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ct=eg:FilterCount(s.ctfilter,nil,tp)
	if ct>0 then
		c:AddCounter(0x1994,ct)
	end
end

--(2) "SAO" monsters gain 100 ATK/DEF
--for each EN-Counter on this card
function s.statfilter(e,c)
	return c:IsSetCard(0x999)
end

function s.statval(e,c)
	return e:GetHandler():GetCounter(0x1994)*100
end

--(3) Once per turn, if this card would be destroyed
--by a card effect, remove 3 EN-Counters instead
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()

	if chk==0 then
		return c:IsReason(REASON_EFFECT)
			and not c:IsReason(REASON_REPLACE)
			and c:IsCanRemoveCounter(tp,0x1994,3,REASON_EFFECT)
	end

	return Duel.SelectEffectYesNo(tp,c,96)
end

function s.repop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RemoveCounter(tp,0x1994,3,REASON_EFFECT)
end