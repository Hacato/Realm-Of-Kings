--YuYuYu Yoshiteru
--Scripted by Raivost
function c99910110.initial_effect(c)
  c:EnableReviveLimit()
  -- Cannot be Normal Summoned/Set or Special Summoned
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  e0:SetValue(c99910110.splimit)
  c:RegisterEffect(e0)
  --(1) Discard to draw
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99910110,0))
  e1:SetCategory(CATEGORY_DRAW)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND)
  e1:SetCountLimit(1,99910110)
  e1:SetCondition(c99910110.drcon)
  e1:SetCost(c99910110.drcost)
  e1:SetTarget(c99910110.drtg)
  e1:SetOperation(c99910110.drop)
  c:RegisterEffect(e1)
  --(2) Grant effect when equipped
  local e2=Effect.CreateEffect(c)
  e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
  e2:SetCode(EVENT_ADJUST)
  e2:SetRange(LOCATION_SZONE)
  e2:SetOperation(c99910110.grantop)
  c:RegisterEffect(e2)
  --(3) Destroy replace
  local e3=Effect.CreateEffect(c)
  e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_EQUIP)
  e3:SetCode(EFFECT_DESTROY_REPLACE)
  e3:SetTarget(c99910110.reptg)
  e3:SetOperation(c99910110.repop)
  c:RegisterEffect(e3)
  --(4) Equip limit - only 1 at a time
  local e4=Effect.CreateEffect(c)
  e4:SetType(EFFECT_TYPE_SINGLE)
  e4:SetCode(EFFECT_EQUIP_LIMIT)
  e4:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
  e4:SetValue(1)
  c:RegisterEffect(e4)
end

-- Cannot be Normal Summoned/Set or Special Summoned
function c99910110.splimit(e,se,sp,st)
  return false
end

--(1) Discard to draw
function c99910110.drcon(e,tp,eg,ep,ev,re,r,rp)
  return not Duel.IsEnvironment(99910070)
end
function c99910110.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsDiscardable() end
  Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function c99910110.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
  Duel.SetTargetPlayer(tp)
  Duel.SetTargetParam(1)
  Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function c99910110.drop(e,tp,eg,ep,ev,re,r,rp)
  local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
  Duel.Draw(p,d,REASON_EFFECT)
end

--(2) Grant effect to equipped monster
function c99910110.grantop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local ec=c:GetEquipTarget()
  if not ec then return end
  
  -- Check if equipped to non-Fairy YuYuYu monster
  if ec:IsSetCard(0x991) and not ec:IsRace(RACE_FAIRY) then
    if ec:GetFlagEffect(99910110)==0 then
      -- Register the effect
      local e1=Effect.CreateEffect(c)
      e1:SetDescription(aux.Stringid(99910110,1))
      e1:SetCategory(CATEGORY_ATKCHANGE)
      e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
      e1:SetCode(EVENT_BATTLE_DESTROYING)
      e1:SetCondition(c99910110.sacon)
      e1:SetOperation(c99910110.saop)
      e1:SetReset(RESET_EVENT+RESETS_STANDARD)
      ec:RegisterEffect(e1)
      ec:RegisterFlagEffect(99910110,RESET_EVENT+RESETS_STANDARD,0,1)
    end
  end
end

--(2.1) Second attack condition and operation
function c99910110.sacon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local bc=c:GetBattleTarget()
  return c:IsRelateToBattle() and bc:IsLocation(LOCATION_GRAVE)
end
function c99910110.saop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsFaceup() and c:IsRelateToEffect(e) then
    -- Gain ATK
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(700)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
    c:RegisterEffect(e1)
    -- Second attack
    Duel.ChainAttack()
  end
end

--(3) Destroy replace
function c99910110.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
  local c=e:GetHandler()
  local tg=c:GetEquipTarget()
  if chk==0 then return tg and not tg:IsReason(REASON_REPLACE) 
    and tg:IsReason(REASON_BATTLE+REASON_EFFECT) end
  return true
end
function c99910110.repop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Destroy(e:GetHandler(),REASON_EFFECT+REASON_REPLACE)
end