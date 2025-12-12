--Absolute Warrior
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	Synchro.AddProcedure(c,aux.FilterBoolFunctionEx(s.tunerfilter),1,1,Synchro.NonTuner(nil),1,99)
	c:EnableReviveLimit()
	
	--On Synchro Summon: Opponent's Level 5+ monsters cannot activate effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.actcon)
	e1:SetOperation(s.actop)
	c:RegisterEffect(e1)
	
	--ATK gain and targeting protection if controlling Dragon Synchro
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetCondition(s.atkcon)
	e2:SetValue(1500)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetCondition(s.atkcon)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	
	--When sent to GY: Add or Special Summon a "Synchron" or "Resonator"
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetCountLimit(1,{id,1})
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end

s.listed_series={0x1017,0x57} --"Synchron" and "Resonator" archetype IDs

--Filter for "Synchron" or "Resonator" Tuners
function s.tunerfilter(c)
	return c:IsSetCard(0x1017) or c:IsSetCard(0x57)
end

--Synchro Summon condition
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

--Effect to prevent Level 5+ monsters from activating effects (OPPONENT ONLY)
function s.actop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	
	--Opponent's field monsters: Cannot trigger effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_TRIGGER)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,4)) -- "Opponent's Level 5+ monsters cannot activate effects"
	e1:SetTargetRange(0,1)
	e1:SetTarget(s.actlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	
	--Opponent's hand/grave effects: Cannot activate
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetDescription(aux.Stringid(id,4))
	e2:SetTargetRange(0,1)
	e2:SetValue(s.aclimit)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
	
	--Visual confirmation for players
	Duel.Hint(HINT_CARD,0,id)
	Duel.Hint(HINT_MESSAGE,tp,aux.Stringid(id,4)) -- "Opponent's Level 5+ monsters cannot activate effects"
	Duel.Hint(HINT_MESSAGE,1-tp,aux.Stringid(id,4))
end

--Target limitation for opponent's field monsters
function s.actlimit(e,c)
	return c:IsLevelAbove(5) and c:IsMonster()
end

--Value function for opponent's hand/grave activation prevention
function s.aclimit(e,re,tp)
	local loc=re:GetActivateLocation()
	local rc=re:GetHandler()
	return (loc==LOCATION_HAND or loc==LOCATION_GRAVE) and rc:IsLevelAbove(5) and rc:IsMonster()
end

--Check if controlling a Dragon Synchro Monster
function s.dragonfilter(c)
	return c:IsFaceup() and c:IsRace(RACE_DRAGON) and c:IsType(TYPE_SYNCHRO)
end

function s.atkcon(e)
	return Duel.IsExistingMatchingCard(s.dragonfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

--Filter for "Synchron" or "Resonator" monster search
function s.thfilter(c,e,tp,ft)
	return (c:IsSetCard(0x1017) or c:IsSetCard(0x57)) and c:IsMonster()
		and (c:IsAbleToHand() or (ft>0 and c:IsCanBeSpecialSummoned(e,0,tp,false,false)))
end

--Target for the GY effect
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,e,tp,ft) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

--Operation for the GY effect
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,ft)
	local tc=g:GetFirst()
	if not tc then return end
	
	local b1=tc:IsAbleToHand()
	local b2=ft>0 and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
	
	local op=0
	if b1 and b2 then
		op=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3)) -- 0=to hand, 1=SS
	elseif b1 then
		op=0
	elseif b2 then
		op=1
	else
		return
	end
	
	if op==0 then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	else
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		--Negate its effects
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end