--SZS - Ignite Module Tsubasa
--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --xyz summon
	Symphogear.XyzSummonProcedure(c,id)
    --destroy
    local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetCost(Cost.DetachFromSelf(1,1,nil))
	e1:SetOperation(s.dmgop)
	c:RegisterEffect(e1)
end
s.listed_series={SET_SZS}
function s.dmgop(e,tp,eg,ep,ev,re,r,rp)
	Symphogear.IncreaseATK(e:GetHandler(),{
		value=300,
		reset=RESETS_STANDARD_PHASE_END
	})
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetCode(EFFECT_CHANGE_BATTLE_DAMAGE)
	e1:SetCondition(function(e) local bc=e:GetHandler():GetBattleTarget() return bc and bc:IsControler(1-e:GetHandlerPlayer()) end)
	e1:SetValue(aux.ChangeBattleDamage(1,DOUBLE_DAMAGE))
	e1:SetReset(RESETS_STANDARD_PHASE_END)
	e:GetHandler():RegisterEffect(e1)
end
Duel.LoadScript("szs-utility.lua")