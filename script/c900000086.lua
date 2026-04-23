--Mokey Mokey Demigod
local s,id=GetID()
local CARD_MOKEY_MOKEY=12482652
local CARD_MOKEY_MOKEY_VENGANCE=900000082
function s.initial_effect(c)
	c:EnableReviveLimit()

	--Must first be Special Summoned by "Mokey Mokey Vengance"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	--Always treated as "Mokey Mokey"
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_ADD_CODE)
	e1:SetValue(CARD_MOKEY_MOKEY)
	c:RegisterEffect(e1)

	--When this card is Special Summoned, all "Mokey Mokey" monsters you control gain 3000 ATK
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.atktg)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)

	--Twice per turn, if your monster destroys an opponent's monster by battle:
	--You may draw 1 card, and if you do, your opponent may Special Summon
	--1 monster from their GY or banishment, ignoring its Summoning conditions
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DRAW+CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(2,id+1)
	e3:SetCondition(s.drcon)
	e3:SetTarget(s.drtg)
	e3:SetOperation(s.drop)
	c:RegisterEffect(e3)

	--Cannot attack unless it is the only card you control
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CANNOT_ATTACK)
	e4:SetCondition(s.atkcon2)
	c:RegisterEffect(e4)
end
s.listed_names={CARD_MOKEY_MOKEY,CARD_MOKEY_MOKEY_VENGANCE}
s.listed_series={0x184}

function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(CARD_MOKEY_MOKEY_VENGANCE)
end

function s.mfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x184) and c:IsMonster()
end
function s.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.mfilter,tp,LOCATION_MZONE,0,1,nil) end
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_MZONE,0,nil)
	for tc in aux.Next(g) do
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(3000)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
		tc:RegisterEffect(e1)
	end
end

--Any of your monsters destroys an opponent's monster by battle
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not a then return false end
	if a:IsControler(tp) and d and d:IsControler(1-tp) and d:IsStatus(STATUS_BATTLE_DESTROYED) then
		return true
	end
	if d and d:IsControler(tp) and a:IsControler(1-tp) and a:IsStatus(STATUS_BATTLE_DESTROYED) then
		return true
	end
	return false
end

function s.spfilter(c,e,tp)
	return c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetPossibleOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.SelectYesNo(tp,aux.Stringid(id,1)) then return end
	if Duel.Draw(tp,1,REASON_EFFECT)==0 then return end
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)<=0 then return end
	local g=Duel.GetMatchingGroup(s.spfilter,1-tp,LOCATION_GRAVE|LOCATION_REMOVED,0,nil,e,1-tp)
	if #g>0 and Duel.SelectYesNo(1-tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
		local sg=g:Select(1-tp,1,1,nil)
		local tc=sg:GetFirst()
		if tc and Duel.SpecialSummon(tc,0,1-tp,1-tp,true,true,POS_FACEUP)~=0 then
			tc:CompleteProcedure()
		end
	end
end

function s.atkcon2(e)
	return Duel.GetFieldGroupCount(e:GetHandlerPlayer(),LOCATION_ONFIELD,0)>1
end