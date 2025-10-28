--Fate Ascended Archer, Emiya Shirou
--Scripted by Raivost
function c99890050.initial_effect(c)
  c:EnableReviveLimit()
  --Special Summon condition
  local e0=Effect.CreateEffect(c)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  e0:SetValue(aux.FALSE)
  c:RegisterEffect(e0)
  --(1) Reveal to search "Fate Archer, Emiya Shirou"
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99890050,0))
  e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND)
  e1:SetCountLimit(1,99890050)
  e1:SetCost(c99890050.thcost)
  e1:SetTarget(c99890050.thtg1)
  e1:SetOperation(c99890050.thop1)
  c:RegisterEffect(e1)
  --(2) Search on leave field
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99890050,1))
  e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_LEAVE_FIELD)
  e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
  e2:SetTarget(c99890050.thtg2)
  e2:SetOperation(c99890050.thop2)
  c:RegisterEffect(e2)
  --(3) Direct attack
  local e3=Effect.CreateEffect(c)
  e3:SetType(EFFECT_TYPE_SINGLE)
  e3:SetCode(EFFECT_DIRECT_ATTACK)
  c:RegisterEffect(e3)
  --(4) Reduce damage
  local e4=Effect.CreateEffect(c)
  e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
  e4:SetCode(EVENT_PRE_BATTLE_DAMAGE)
  e4:SetCondition(c99890050.rdcon)
  e4:SetOperation(c99890050.rdop)
  c:RegisterEffect(e4)
  --(5) Change position
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(99890050,2))
  e5:SetCategory(CATEGORY_POSITION)
  e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e5:SetType(EFFECT_TYPE_IGNITION)
  e5:SetRange(LOCATION_MZONE)
  e5:SetCountLimit(1)
  e5:SetTarget(c99890050.postg)
  e5:SetOperation(c99890050.posop)
  c:RegisterEffect(e5)
end
c99890050.listed_names={99890040}
--(1) Reveal to search "Fate Archer, Emiya Shirou"
function c99890050.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return not e:GetHandler():IsPublic() end
  local e1=Effect.CreateEffect(e:GetHandler())
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_PUBLIC)
  e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
  e:GetHandler():RegisterEffect(e1)
end
function c99890050.thfilter1(c)
  return c:IsCode(99890040) and c:IsAbleToHand()
end
function c99890050.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890050.thfilter1,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
  Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function c99890050.thop1(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890050.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
    Duel.ConfirmCards(1-tp,g)
    if c:IsRelateToEffect(e) then
      Duel.BreakEffect()
      Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
  end
end
--(2) Search on leave field
function c99890050.thfilter2(c)
  return c:IsSetCard(0x989) and bit.band(c:GetType(),0x81)==0x81 and not c:IsCode(99890040) and c:IsAbleToHand()
end
function c99890050.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890050.thfilter2,tp,LOCATION_DECK,0,1,nil) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function c99890050.thop2(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890050.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end
--(4) Reduce damage
function c99890050.rdcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  return ep~=tp and Duel.GetAttackTarget()==nil
  and c:GetEffectCount(EFFECT_DIRECT_ATTACK)<2 and Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)>0
end
function c99890050.rdop(e,tp,eg,ep,ev,re,r,rp)
  Duel.ChangeBattleDamage(ep,ev/2)
end
--(5) Change position
function c99890050.posfilter1(c)
  return c:IsFaceup() and c:IsSetCard(0x989)
end
function c99890050.posfilter2(c)
  return c:IsCanChangePosition()
end
function c99890050.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  local ct=Duel.GetMatchingGroupCount(c99890050.posfilter1,tp,LOCATION_MZONE,0,e:GetHandler())
  if chk==0 then return Duel.IsExistingTarget(c99890050.posfilter2,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) and ct>0 end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
  local g=Duel.SelectTarget(tp,c99890050.posfilter2,tp,LOCATION_MZONE,LOCATION_MZONE,1,ct,nil)
  Duel.SetOperationInfo(0,CATEGORY_POSITION,g,g:GetCount(),0,0)
end
function c99890050.posop(e,tp,eg,ep,ev,re,r,rp)
  local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
  local g=tg:Filter(Card.IsRelateToEffect,nil,e)
  if g:GetCount()>0 then
    Duel.ChangePosition(g,POS_FACEUP_DEFENSE,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)
  end
end