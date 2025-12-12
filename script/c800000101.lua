--Constructor Battler Big Rollen
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--ATK reduction during Damage Step
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_BATTLE_CONFIRM)
	e2:SetRange(LOCATION_HAND+LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.atkcon)
	e2:SetCost(s.atkcost)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end
s.listed_series={0x1568} --Constructor

--Special Summon condition: face-up Field Spell exists
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_FIELD),tp,LOCATION_FZONE,LOCATION_FZONE,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--ATK reduction condition: your "Constructor" monster battles
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local bc=Duel.GetBattleMonster(tp)
	return bc and bc:IsSetCard(0x1568) and bc:IsFaceup() and Duel.GetAttackTarget()~=nil
end
--Cost: send this card to GY
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return (c:IsLocation(LOCATION_HAND) or (c:IsLocation(LOCATION_MZONE) and c:IsFaceup()))
		and c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end
--Operation: opponent's battling monster loses ATK
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetAttacker()
	if tc:IsControler(tp) then tc=Duel.GetAttackTarget() end
	if tc and tc:IsRelateToBattle() and tc:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-c:GetAttack())
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end