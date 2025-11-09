--YuYuYu Inubouzaki Itsuki
--Scripted by Raivost
local s,id=GetID()
function s.initial_effect(c)
  c:EnableReviveLimit()
  Pendulum.AddProcedure(c)

  -------------------------------
  -- Pendulum Effects
  -------------------------------
  --(1) Destroy self → add Ritual Spell
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND+CATEGORY_SEARCH)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_PZONE)
  e1:SetCountLimit(1,id)
  e1:SetTarget(s.pendtg1)
  e1:SetOperation(s.pendop1)
  c:RegisterEffect(e1)

  --(2) Return Pendulum from Extra → shuffle opponent card
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetCategory(CATEGORY_TOHAND+CATEGORY_TODECK)
  e2:SetType(EFFECT_TYPE_IGNITION)
  e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e2:SetRange(LOCATION_PZONE)
  e2:SetCountLimit(1,id+1)
  e2:SetTarget(s.pendtg2)
  e2:SetOperation(s.pendop2)
  c:RegisterEffect(e2)

  -------------------------------
  -- Monster Effects
  -------------------------------
  --(1) Tribute self → search Ritual Monster
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(id,2))
  e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e3:SetType(EFFECT_TYPE_IGNITION)
  e3:SetRange(LOCATION_MZONE)
  e3:SetCountLimit(1)
  e3:SetCost(s.moncost1)
  e3:SetTarget(s.montg1)
  e3:SetOperation(s.monop1)
  c:RegisterEffect(e3)

  --(2) Quick Effect: Negate card
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(id,3))
  e4:SetCategory(CATEGORY_DISABLE)
  e4:SetType(EFFECT_TYPE_QUICK_O)
  e4:SetCode(EVENT_FREE_CHAIN)
  e4:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e4:SetRange(LOCATION_MZONE)
  e4:SetHintTiming(0,0x1c0)
  e4:SetCountLimit(1,id+2)
  e4:SetTarget(s.negtg)
  e4:SetOperation(s.negop)
  c:RegisterEffect(e4)

  --(3) Leave-field → search Ritual Spell + recover 500 LP
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(id,2))
  e5:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_RECOVER)
  e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e5:SetCode(EVENT_LEAVE_FIELD)
  e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
  e5:SetCondition(s.leavcon)
  e5:SetTarget(s.leavtg)
  e5:SetOperation(s.leavop)
  c:RegisterEffect(e5)
end

-----------------------------------
-- Pendulum Effect Functions
-----------------------------------
function s.ritspellfilter(c)
  return c:IsSetCard(0x991) and c:IsType(TYPE_RITUAL) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

-- Destroy self → search
function s.pendtg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    return e:GetHandler():IsDestructable() and Duel.IsExistingMatchingCard(s.ritspellfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
  end
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,0,0)
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end

function s.pendop1(e,tp,eg,ep,ev,re,r,rp)
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

-- Return Pendulum from Extra → shuffle opponent card
function s.rtdfilter(c)
  return c:IsAbleToDeck()
end
function s.rthfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x991) and c:IsType(TYPE_PENDULUM) and c:IsAbleToHand()
end

function s.pendtg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chk==0 then
    return Duel.IsExistingTarget(s.rtdfilter,tp,0,LOCATION_ONFIELD,1,nil)
       and Duel.IsExistingMatchingCard(s.rthfilter,tp,LOCATION_EXTRA,0,1,nil)
  end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
  local g=Duel.SelectTarget(tp,s.rtdfilter,tp,0,LOCATION_ONFIELD,1,1,nil)
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA)
  Duel.SetOperationInfo(0,CATEGORY_TODECK,g,1,1-tp,LOCATION_ONFIELD)
end

function s.pendop2(e,tp,eg,ep,ev,re,r,rp)
  local tc=Duel.GetFirstTarget()
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
  local g=Duel.SelectMatchingCard(tp,s.rthfilter,tp,LOCATION_EXTRA,0,1,1,nil)
  if #g>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
    if tc and tc:IsRelateToEffect(e) then
      Duel.SendtoDeck(tc,nil,2,REASON_EFFECT)
    end
  end
end

-----------------------------------
-- Monster Effect Functions
-----------------------------------
-- Tribute self → search Ritual Monster
function s.moncost1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsReleasable() end
  Duel.Release(e:GetHandler(),REASON_COST)
end

function s.monfilter1(c)
  return c:IsSetCard(0x991) and bit.band(c:GetType(),0x81)==0x81 and not c:IsCode(id) and c:IsAbleToHand()
end

function s.montg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(s.monfilter1,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.monop1(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,s.monfilter1,tp,LOCATION_DECK,0,1,1,nil)
  if #g>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end

-- Quick Effect: Negate card
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chk==0 then return Duel.IsExistingTarget(Card.IsNegatableMonster,tp,0,LOCATION_ONFIELD,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
  local g=Duel.SelectTarget(tp,Card.IsNegatableMonster,tp,0,LOCATION_ONFIELD,1,1,nil)
  Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local tc=Duel.GetFirstTarget()
  if tc and ((tc:IsFaceup() and not tc:IsDisabled()) or tc:IsType(TYPE_TRAPMONSTER)) and tc:IsRelateToEffect(e) then
    Duel.NegateRelatedChain(tc,RESET_TURN_SET)
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetCode(EFFECT_DISABLE)
    e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e1)
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_SINGLE)
    e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e2:SetCode(EFFECT_DISABLE_EFFECT)
    e2:SetValue(RESET_TURN_SET)
    e2:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e2)
    if tc:IsType(TYPE_TRAPMONSTER) then
      local e3=Effect.CreateEffect(c)
      e3:SetType(EFFECT_TYPE_SINGLE)
      e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
      e3:SetCode(EFFECT_DISABLE_TRAPMONSTER)
      e3:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
      tc:RegisterEffect(e3)
    end
  end
end

-- Leave-field → search Ritual Spell + recover 500 LP
function s.leavcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  return (c:IsReason(REASON_BATTLE) or (c:GetReasonPlayer()~=tp and c:IsReason(REASON_EFFECT)))
     and c:GetPreviousControler()==tp and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.leavtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(s.ritspellfilter,tp,LOCATION_GRAVE,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
  Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,500)
end

function s.leavop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,s.ritspellfilter,tp,LOCATION_GRAVE,0,1,1,nil)
  if #g>0 and Duel.SendtoHand(g,tp,REASON_EFFECT)>0 and g:GetFirst():IsLocation(LOCATION_HAND) then
    Duel.ConfirmCards(1-tp,g)
    Duel.Recover(tp,500,REASON_EFFECT)
  end
end
