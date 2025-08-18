--Lunar Eclipse Celestial Iris Dragon
--ID: You can replace this with your desired ID
local s,id=GetID()
local SETCODE_ECLIPSE=0x04B2

function s.initial_effect(c)
	--Pendulum attributes
	Pendulum.AddProcedure(c)
	
	--Can only Pendulum Summon "Eclipse" monsters
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_CANNOT_NEGATE)
	e1:SetTargetRange(1,0)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)
	
	--Destroy itself to add an "Eclipse" Pendulum Monster
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	
	--Double battle damage effect when Pendulum Summoned
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.pendcon)
	e3:SetTarget(s.damtg)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
	
	--Double battle damage if battling a high-level/rank/link monster
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e4:SetCondition(s.damcon2)
	e4:SetValue(DOUBLE_DAMAGE)
	c:RegisterEffect(e4)
end

--Cannot Pendulum Summon non-"Eclipse" monsters
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not c:IsSetCard(SETCODE_ECLIPSE) and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
end

--Check if it's your End Phase
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(tp) and Duel.IsPhase(PHASE_END)
end

--Filter for Eclipse Pendulum Monster search
function s.thfilter(c)
	return c:IsSetCard(SETCODE_ECLIPSE) and c:IsType(TYPE_PENDULUM) and c:IsAbleToHand()
		and not c:IsCode(id)
end

--Target for the End Phase effect
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDestructable()
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) and Duel.GetFlagEffect(tp,id+1)==0 end
	Duel.RegisterFlagEffect(tp,id+1,RESET_PHASE+PHASE_END,0,1)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

--Operation for End Phase destroy and search
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.Destroy(c,REASON_EFFECT)==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--Check if this card was Pendulum Summoned
function s.pendcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_PENDULUM)
end

--Target selection for damage doubling effect (excluding self)
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) 
		and chkc~=e:GetHandler() end
	if chk==0 then return Duel.IsExistingTarget(
		aux.FaceupFilter(Card.IsMonster),
		tp,LOCATION_MZONE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,
		aux.FaceupFilter(Card.IsMonster),
		tp,LOCATION_MZONE,0,1,1,e:GetHandler())
end

--Apply the damage doubling and attack restriction effects
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) then return end
	
	--Double battle damage for the selected monster
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e1:SetValue(aux.ChangeBattleDamage(1,DOUBLE_DAMAGE))
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	tc:RegisterEffect(e1)
	
	--Other monsters cannot attack
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ATTACK)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktg)
	e2:SetLabel(tc:GetFieldID())
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

--Helper for attack restriction (affect all monsters except the selected one)
function s.atktg(e,c)
	return c:GetFieldID()~=e:GetLabel()
end

--Check if battling a high-level/rank/link monster
function s.damcon2(e)
	local c=e:GetHandler()
	if not Duel.GetAttacker() then return false end
	
	local bc
	if Duel.GetAttacker()==c then
		bc=Duel.GetAttackTarget()
	else
		bc=Duel.GetAttacker()
	end
	
	return bc and bc:IsControler(1-e:GetHandlerPlayer()) and 
		(bc:IsLevelAbove(5) or bc:IsRankAbove(5) or (bc:IsLinkMonster() and bc:IsLinkAbove(3)))
end