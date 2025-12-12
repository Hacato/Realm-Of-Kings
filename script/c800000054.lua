--Monado Wielder - Fiora
local s,id=GetID()
function s.initial_effect(c)
	--Gain 500 ATK if you control another "Monado" monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetValue(500)
	e1:SetCondition(s.atkcon)
	c:RegisterEffect(e1)
	--Can make a second attack if equipped with Monado Sword
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_EXTRA_ATTACK)
	e2:SetValue(1)
	e2:SetCondition(s.extraatkcon)
	c:RegisterEffect(e2)
	--Destroy 1 Spell/Trap if this card destroys a monster by battle
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCondition(aux.bdgcon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

--Filter for another "Monado" monster
function s.monadfilter(c)
	return c:IsSetCard(0x712)
end

--Condition for ATK gain
function s.atkcon(e)
	local c=e:GetHandler()
	return Duel.IsExistingMatchingCard(s.monadfilter,c:GetControler(),LOCATION_MZONE,0,1,c)
end

--Condition for extra attack (must be equipped with Monado Sword)
function s.extraatkcon(e)
	local c=e:GetHandler()
	local g=c:GetEquipGroup()
	return g:IsExists(Card.IsCode,1,nil,50000425)
end

--Target Spell/Trap to destroy
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,0,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsType,tp,0,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

--Destroy operation
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
