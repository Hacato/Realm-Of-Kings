--YuYuYu Aobozu
--Scripted by Raivost
function c99910090.initial_effect(c)
  c:EnableReviveLimit()
  -- Cannot be Normal Summoned/Set or Special Summoned
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  e0:SetValue(c99910090.splimit)
  c:RegisterEffect(e0)
  --(1) Discard to draw
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99910090,0))
  e1:SetCategory(CATEGORY_DRAW)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND)
  e1:SetCountLimit(1,99910090)
  e1:SetCondition(c99910090.drcon)
  e1:SetCost(c99910090.drcost)
  e1:SetTarget(c99910090.drtg)
  e1:SetOperation(c99910090.drop)
  c:RegisterEffect(e1)
  --(2) Grant effect when equipped
  local e2=Effect.CreateEffect(c)
  e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
  e2:SetCode(EVENT_ADJUST)
  e2:SetRange(LOCATION_SZONE)
  e2:SetOperation(c99910090.grantop)
  c:RegisterEffect(e2)
  --(3) Destroy replace
  local e3=Effect.CreateEffect(c)
  e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_EQUIP)
  e3:SetCode(EFFECT_DESTROY_REPLACE)
  e3:SetTarget(c99910090.reptg)
  e3:SetOperation(c99910090.repop)
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
function c99910090.splimit(e,se,sp,st)
  return false
end

--(1) Discard to draw
function c99910090.drcon(e,tp,eg,ep,ev,re,r,rp)
  return not Duel.IsEnvironment(99910070)
end
function c99910090.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsDiscardable() end
  Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function c99910090.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
  Duel.SetTargetPlayer(tp)
  Duel.SetTargetParam(1)
  Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function c99910090.drop(e,tp,eg,ep,ev,re,r,rp)
  local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
  Duel.Draw(p,d,REASON_EFFECT)
end

--(2) Grant effect to equipped monster
function c99910090.grantop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local ec=c:GetEquipTarget()
  if not ec then return end
  
  -- Check if equipped to non-Fairy YuYuYu monster
  if ec:IsSetCard(0x991) and not ec:IsRace(RACE_FAIRY) then
    if ec:GetFlagEffect(99910090)==0 then
      -- Register the effect - using the equip card (c) as the owner
      local e1=Effect.CreateEffect(c)
      e1:SetDescription(aux.Stringid(99910090,1))
      e1:SetCategory(CATEGORY_DESTROY)
      e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
      e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
      e1:SetCode(EVENT_ATTACK_ANNOUNCE)
      e1:SetRange(LOCATION_MZONE)
      e1:SetCountLimit(1)
      e1:SetCondition(c99910090.nacon)
      e1:SetTarget(c99910090.natg)
      e1:SetOperation(c99910090.naop)
      e1:SetReset(RESET_EVENT+RESETS_STANDARD)
      e1:SetOwnerPlayer(tp)
      ec:RegisterEffect(e1)
      ec:RegisterFlagEffect(99910090,RESET_EVENT+RESETS_STANDARD,0,1)
    end
  end
end

--(2.1) Negate attack and destroy
function c99910090.nacon(e,tp,eg,ep,ev,re,r,rp)
  return Duel.GetAttacker():GetControler()~=tp
end
function c99910090.desfilter(c,atk)
  return c:IsFaceup() and c:IsAttackBelow(atk)
end
function c99910090.natg(e,tp,eg,ep,ev,re,r,rp,chk)
  local atk=Duel.GetAttacker():GetAttack()
  if chk==0 then return Duel.IsExistingMatchingCard(c99910090.desfilter,tp,0,LOCATION_MZONE,1,nil,atk) end
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
end
function c99910090.naop(e,tp,eg,ep,ev,re,r,rp)
  if Duel.NegateAttack() then
    local atk=Duel.GetAttacker():GetAttack()
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local g=Duel.SelectMatchingCard(tp,c99910090.desfilter,tp,0,LOCATION_MZONE,1,1,nil,atk)
    if g:GetCount()>0 then
      Duel.HintSelection(g)
      Duel.Destroy(g,REASON_EFFECT)
    end
  end
end

--(3) Destroy replace
function c99910090.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
  local c=e:GetHandler()
  local tg=c:GetEquipTarget()
  if chk==0 then return tg and not tg:IsReason(REASON_REPLACE) 
    and tg:IsReason(REASON_BATTLE+REASON_EFFECT) end
  return true
end
function c99910090.repop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Destroy(e:GetHandler(),REASON_EFFECT+REASON_REPLACE)
end