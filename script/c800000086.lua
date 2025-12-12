--YuYuYu Inugami
--Scripted by Raivost + corrected to match effect
local s,id=GetID()
function s.initial_effect(c)
  --Cannot be Normal Summoned/Set or Special Summoned
  c:EnableReviveLimit()
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  c:RegisterEffect(e0)
  
  --(1) Discard to draw if "YuYuYu Sea of Trees" is not on field
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_DRAW)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND)
  e1:SetCondition(s.drcon)
  e1:SetCost(s.drcost)
  e1:SetTarget(s.drtg)
  e1:SetOperation(s.drop)
  c:RegisterEffect(e1)
  
  --(2) Equip to non-Fairy "YuYuYu" monster
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetCategory(CATEGORY_EQUIP)
  e2:SetType(EFFECT_TYPE_IGNITION)
  e2:SetRange(LOCATION_HAND)
  e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e2:SetTarget(s.eqtg)
  e2:SetOperation(s.eqop)
  c:RegisterEffect(e2)
  
  --(3) Grant effect to equipped monster
  local e3=Effect.CreateEffect(c)
  e3:SetType(EFFECT_TYPE_EQUIP)
  e3:SetCode(EFFECT_UPDATE_ATTACK)
  e3:SetValue(0)
  c:RegisterEffect(e3)
  
  local e4=Effect.CreateEffect(c)
  e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_GRANT)
  e4:SetRange(LOCATION_SZONE)
  e4:SetTargetRange(LOCATION_MZONE,0)
  e4:SetTarget(s.eftg)
  e4:SetLabelObject(e3)
  c:RegisterEffect(e4)
  
  --(4) Granted effect: ATK gain at start of Damage Step
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(id,2))
  e5:SetCategory(CATEGORY_ATKCHANGE)
  e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e5:SetCode(EVENT_BATTLE_START)
  e5:SetCondition(s.atkcon)
  e5:SetOperation(s.atkop)
  e4:SetLabelObject(e5)
  
  --(5) Redirect destruction
  local e6=Effect.CreateEffect(c)
  e6:SetType(EFFECT_TYPE_EQUIP)
  e6:SetCode(EFFECT_DESTROY_SUBSTITUTE)
  e6:SetValue(s.repval)
  c:RegisterEffect(e6)
  
  --(6) Only 1 Inugami per monster
  local e7=Effect.CreateEffect(c)
  e7:SetType(EFFECT_TYPE_SINGLE)
  e7:SetCode(EFFECT_EQUIP_LIMIT)
  e7:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
  e7:SetValue(s.eqlimit)
  c:RegisterEffect(e7)
end
s.listed_names={0x999} --YuYuYu archetype
s.listed_names={id} --Self-reference for duplicate check

--(1) Discard to draw
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
  return not Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,99910070),tp,LOCATION_ONFIELD,0,1,nil) --Replace with actual Sea of Trees code
end
function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsDiscardable() end
  Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
  Duel.SetTargetPlayer(tp)
  Duel.SetTargetParam(1)
  Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
  local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
  Duel.Draw(p,d,REASON_EFFECT)
end

--(2) Equip procedure
function s.eqfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x999) and not c:IsRace(RACE_FAIRY)
    and not c:GetEquipGroup():IsExists(Card.IsCode,1,nil,id)
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and s.eqfilter(chkc) end
  if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
    and Duel.IsExistingTarget(s.eqfilter,tp,LOCATION_MZONE,0,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
  Duel.SelectTarget(tp,s.eqfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.eqop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local tc=Duel.GetFirstTarget()
  if not c:IsRelateToEffect(e) or not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
  if tc:GetEquipGroup():IsExists(Card.IsCode,1,nil,id) then return end
  Duel.Equip(tp,c,tc)
end

--(3) Effect grant filter
function s.eftg(e,c)
  return e:GetHandler():GetEquipTarget()==c
end

--(4) Granted ATK gain effect
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local bc=c:GetBattleTarget()
  return bc and bc:IsControler(1-tp) and bc:IsSummonLocation(LOCATION_EXTRA)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsFaceup() and c:IsRelateToEffect(e) then
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(c:GetBaseAttack())
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
    c:RegisterEffect(e1)
  end
end

--(5) Redirect destruction
function s.repval(e,re,r,rp)
  return bit.band(r,REASON_BATTLE+REASON_EFFECT)~=0
end

--(6) Equip limit
function s.eqlimit(e,c)
  return c:IsSetCard(0x999) and not c:IsRace(RACE_FAIRY)
    and not c:GetEquipGroup():IsExists(Card.IsCode,1,e:GetHandler(),id)
end