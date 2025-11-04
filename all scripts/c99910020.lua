--YuYuYu Yuuki Yuuna
--Scripted by Raivost
local s,id=GetID()
function s.initial_effect(c)
  --Monster setup
  c:EnableReviveLimit()
  
  --Pendulum setup
  Pendulum.AddProcedure(c)

  -------------------------------
  -- Pendulum Effects
  -------------------------------
  --(1) Destroy this card to add 1 "YuYuYu" Ritual Spell from Deck/GY
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_PZONE)
  e1:SetCountLimit(1,id)
  e1:SetTarget(s.destg1)
  e1:SetOperation(s.desop1)
  c:RegisterEffect(e1)

  --(2) YuYuYu Ritual Monsters gain 500 ATK during Damage Step
  local e2=Effect.CreateEffect(c)
  e2:SetCategory(CATEGORY_ATKCHANGE)
  e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
  e2:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
  e2:SetRange(LOCATION_PZONE)
  e2:SetCondition(s.atkcon)
  e2:SetOperation(s.atkop)
  c:RegisterEffect(e2)

  -------------------------------
  -- Monster Effects
  -------------------------------
  --(1) Tribute this card to add 1 "YuYuYu" Ritual Monster (except itself)
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(id,1))
  e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e3:SetType(EFFECT_TYPE_IGNITION)
  e3:SetRange(LOCATION_MZONE)
  e3:SetCountLimit(1)
  e3:SetCost(s.thcost1)
  e3:SetTarget(s.thtg1)
  e3:SetOperation(s.thop1)
  c:RegisterEffect(e3)

  --(2) Destroy battle target and inflict its ATK as damage
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(id,2))
  e4:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
  e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e4:SetCode(EVENT_BATTLE_START)
  e4:SetCountLimit(1)
  e4:SetCondition(s.descon2)
  e4:SetTarget(s.destg2)
  e4:SetOperation(s.desop2)
  c:RegisterEffect(e4)

  --(3) If destroyed by battle or opponent effect, add Ritual Spell from GY and gain 500 LP
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(id,3))
  e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_RECOVER)
  e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e5:SetCode(EVENT_LEAVE_FIELD)
  e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
  e5:SetCondition(s.thcon2)
  e5:SetTarget(s.thtg2)
  e5:SetOperation(s.thop2)
  c:RegisterEffect(e5)
end

-----------------------------------
-- Pendulum Effect Functions
-----------------------------------

-- Filter for Ritual Spells (Pendulum destroy search)
function s.ritspellfilter(c)
  return c:IsSetCard(0x991) and c:IsType(TYPE_RITUAL) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

-- Destroy self to add Ritual Spell
function s.destg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then 
    return e:GetHandler():IsDestructable() and Duel.IsExistingMatchingCard(s.ritspellfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) 
  end
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.desop1(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if not c:IsRelateToEffect(e) then return end
  if Duel.Destroy(c,REASON_EFFECT)~=0 then
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.ritspellfilter),tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
    if #g>0 then
      Duel.SendtoHand(g,nil,REASON_EFFECT)
      Duel.ConfirmCards(1-tp,g)
    end
  end
end

-- 500 ATK boost during Damage Step for YuYuYu Ritual Monsters
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
  local a=Duel.GetAttacker()
  local d=Duel.GetAttackTarget()
  if not a or not d then return false end
  local tc=nil
  if a:IsControler(tp) and a:IsSetCard(0x991) and a:IsType(TYPE_RITUAL) then tc=a
  elseif d:IsControler(tp) and d:IsSetCard(0x991) and d:IsType(TYPE_RITUAL) then tc=d end
  e:SetLabelObject(tc)
  return tc~=nil
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
  local tc=e:GetLabelObject()
  if tc and tc:IsRelateToBattle() then
    Duel.Hint(HINT_CARD,0,id)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetValue(500)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE)
    tc:RegisterEffect(e1)
  end
end

-----------------------------------
-- Monster Effect Functions
-----------------------------------

-- Tribute self to search Ritual Monster
function s.thcost1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsReleasable() end
  Duel.Release(e:GetHandler(),REASON_COST)
end

function s.thfilter2(c)
  return c:IsSetCard(0x991) and c:IsType(TYPE_RITUAL) and c:IsType(TYPE_MONSTER) and not c:IsCode(id) and c:IsAbleToHand()
end

function s.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter2,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop1(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,s.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
  if #g>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end

-- Destroy battle target and inflict its ATK as damage
function s.descon2(e,tp,eg,ep,ev,re,r,rp)
  return e:GetHandler():GetBattleTarget()~=nil
end

function s.destg2(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  local bc=e:GetHandler():GetBattleTarget()
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,bc,1,0,0)
  Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,bc:GetAttack())
end

function s.desop2(e,tp,eg,ep,ev,re,r,rp)
  local bc=e:GetHandler():GetBattleTarget()
  if bc and bc:IsRelateToBattle() then
    local dam=bc:GetAttack()
    if Duel.Destroy(bc,REASON_EFFECT)~=0 and dam>0 then
      Duel.Damage(1-tp,dam,REASON_EFFECT)
    end
  end
end

-- Leave-field trigger: Add Ritual Spell from GY + Recover 500 LP
function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  return (c:IsReason(REASON_BATTLE) or (c:GetReasonPlayer()~=tp and c:IsReason(REASON_EFFECT)))
     and c:GetPreviousControler()==tp and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(s.ritspellfilter,tp,LOCATION_GRAVE,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
  Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,500)
end

function s.thop2(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,s.ritspellfilter,tp,LOCATION_GRAVE,0,1,1,nil)
  if #g>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
    Duel.ConfirmCards(1-tp,g)
    Duel.Recover(tp,500,REASON_EFFECT)
  end
end
