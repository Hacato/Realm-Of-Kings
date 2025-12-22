--SZS Cherry Blossom Gungnir - Hibiki
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Treated as "YuYuYu" in hand
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_HAND)
	e0:SetValue(0x991)
	c:RegisterEffect(e0)
	--Ritual Summon with any "YuYuYu" Ritual Spell
	Ritual.AddProcGreater({handler=c,filter=s.ritualfilter,lv=5})
	--Register Ritual Summon flag
	local e1a=Effect.CreateEffect(c)
	e1a:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1a:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1a:SetCondition(s.regcon)
	e1a:SetOperation(s.regop)
	c:RegisterEffect(e1a)
	--Check for battles involving SZS/YuYuYu monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BATTLE_CONFIRM)
	e2:SetRange(LOCATION_MZONE)
	e2:SetOperation(s.checkop)
	c:RegisterEffect(e2)
	--Lose 1000 LP during End Phase if no battle occurred
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_END)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.lpcon)
	e1:SetOperation(s.lpop)
	e1:SetLabelObject(e2)
	c:RegisterEffect(e1)
	--Destroy monster at start of Damage Step and inflict damage
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_START)
	e3:SetCountLimit(1)
	e3:SetCondition(s.descon)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
	--Tribute to add card at end of Damage Step
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_HANDES)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DAMAGE_STEP_END)
	e4:SetCondition(s.thcon)
	e4:SetCost(s.thcost)
	e4:SetTarget(s.thtg)
	e4:SetOperation(s.thop)
	c:RegisterEffect(e4)
end
s.listed_names={0x991,0x2406}
s.fit_monster={0x991}

--Ritual filter for "YuYuYu" Ritual Spells
function s.ritualfilter(c)
	return c:IsSetCard(0x991) and c:IsRitualSpell()
end

--Register Ritual Summon
function s.regcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_RITUAL)
end

function s.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END,0,1)
end

--Battle check - triggers whenever ANY battle occurs involving SZS/YuYuYu monsters
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	local d=Duel.GetAttackTarget()
	if not d then return end
	--Check if battle involves SZS/YuYuYu monster vs opponent's monster
	if (a:IsSetCard(0x2406) or a:IsSetCard(0x991)) and a:IsControler(tp) and d:IsControler(1-tp) then
		e:SetLabel(1)
	elseif (d:IsSetCard(0x2406) or d:IsSetCard(0x991)) and d:IsControler(tp) and a:IsControler(1-tp) then
		e:SetLabel(1)
	end
end

function s.lpcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local flag=e:GetLabelObject():GetLabel()
	return c:GetFlagEffect(id)>0 and flag==0
end

function s.lpop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Damage(tp,1000,REASON_EFFECT)
	e:GetLabelObject():SetLabel(0)
	local c=e:GetHandler()
	if c:GetFlagEffect(id)>0 then
		c:ResetFlagEffect(id)
	end
end

--Destroy and damage effect
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc~=nil
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():GetBattleTarget()~=nil end
	local bc=e:GetHandler():GetBattleTarget()
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,bc:GetBaseAttack())
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetHandler():GetBattleTarget()
	if bc and bc:IsRelateToBattle() then
		local atk=bc:GetBaseAttack()
		if atk<0 then atk=0 end
		if Duel.Destroy(bc,REASON_EFFECT)>0 then
			Duel.Damage(1-tp,atk,REASON_EFFECT)
		end
	end
end

--Tribute to search effect
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:GetBattleTarget()~=nil
end

function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

function s.thfilter(c)
	return (c:IsSetCard(0x2406) and c:IsLevel(4) and c:IsMonster()) 
		or (c:IsSetCard(0x991) and c:IsRitualSpell()) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) 
		and Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
		Duel.ConfirmCards(1-tp,g)
		Duel.ShuffleHand(tp)
		Duel.BreakEffect()
		Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT+REASON_DISCARD)
	end
end