--Fate Ascended Shielder, Mashu Kyrielight
--Scripted by Raivost
function c99890110.initial_effect(c)
  c:EnableReviveLimit()
  --Special Summon condition
  local e0=Effect.CreateEffect(c)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  e0:SetValue(aux.FALSE)
  c:RegisterEffect(e0)
  --(1) Reveal to search "Fate Shielder, Mashu Kyrielight"
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99890110,0))
  e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND)
  e1:SetCountLimit(1,99890110)
  e1:SetCost(c99890110.thcost)
  e1:SetTarget(c99890110.thtg1)
  e1:SetOperation(c99890110.thop1)
  c:RegisterEffect(e1)
  --(2) Search on leave field
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99890110,1))
  e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_LEAVE_FIELD)
  e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
  e2:SetTarget(c99890110.thtg2)
  e2:SetOperation(c99890110.thop2)
  c:RegisterEffect(e2)
  --(3) Destroy replace
  local e3=Effect.CreateEffect(c)
  e3:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
  e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
  e3:SetCode(EFFECT_DESTROY_REPLACE)
  e3:SetRange(LOCATION_MZONE)
  e3:SetCountLimit(1)
  e3:SetTarget(c99890110.dreptg)
  c:RegisterEffect(e3)
  --(4) Cannot attack
  local e4=Effect.CreateEffect(c)
  e4:SetType(EFFECT_TYPE_FIELD)
  e4:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
  e4:SetRange(LOCATION_MZONE)
  e4:SetTargetRange(0,LOCATION_MZONE)
  e4:SetValue(c99890110.atlimit)
  c:RegisterEffect(e4)
end
c99890110.listed_names={99890100}
--(1) Reveal to search "Fate Shielder, Mashu Kyrielight"
function c99890110.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return not e:GetHandler():IsPublic() end
  local e1=Effect.CreateEffect(e:GetHandler())
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_PUBLIC)
  e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
  e:GetHandler():RegisterEffect(e1)
end
function c99890110.thfilter1(c)
  return c:IsCode(99890100) and c:IsAbleToHand()
end
function c99890110.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890110.thfilter1,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
  Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function c99890110.thop1(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890110.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
    Duel.ConfirmCards(1-tp,g)
    if c:IsRelateToEffect(e) then
      Duel.BreakEffect()
      Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
  end
end
--(2) Search on leave field
function c99890110.thfilter2(c)
  return c:IsSetCard(0x989) and bit.band(c:GetType(),0x81)==0x81 and not c:IsCode(99890100) and c:IsAbleToHand()
end
function c99890110.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890110.thfilter2,tp,LOCATION_DECK,0,1,nil) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function c99890110.thop2(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890110.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end
--(3) Destroy replace
function c99890110.dreptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsReason(REASON_BATTLE) and Duel.CheckLPCost(tp,500) end
  if Duel.SelectEffectYesNo(tp,e:GetHandler(),96) then
    local c=e:GetHandler()
    Duel.PayLPCost(tp,500)
    return true
  else return false end
end
--(4) Cannot attack
function c99890110.atlimit(e,c)
  return c:IsFaceup() and c:IsSetCard(0x989) and c~=e:GetHandler()
end