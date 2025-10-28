--Fate Ascended Lancer, Cu Chulainn
--Scripted by Raivost
function c99890180.initial_effect(c)
  c:EnableReviveLimit()
  --Special Summon condition
  local e0=Effect.CreateEffect(c)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  e0:SetValue(aux.FALSE)
  c:RegisterEffect(e0)
  --(1) Reveal to search "Fate Lancer, Cu Chulainn"
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99890180,0))
  e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND)
  e1:SetCountLimit(1,99890180)
  e1:SetCost(c99890180.thcost)
  e1:SetTarget(c99890180.thtg1)
  e1:SetOperation(c99890180.thop1)
  c:RegisterEffect(e1)
  --(2) Search on leave field
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99890180,1))
  e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_LEAVE_FIELD)
  e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
  e2:SetTarget(c99890180.thtg2)
  e2:SetOperation(c99890180.thop2)
  c:RegisterEffect(e2)
  --(3) Destroy 
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(99890180,2))
  e3:SetCategory(CATEGORY_DESTROY)
  e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e3:SetCode(EVENT_BATTLE_START)
  e3:SetTarget(c99890180.destg)
  e3:SetOperation(c99890180.desop)
  c:RegisterEffect(e3)
  --(4) Discard
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(99890180,3))
  e4:SetCategory(CATEGORY_HANDES+CATEGORY_DRAW)
  e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e4:SetCode(EVENT_ATTACK_ANNOUNCE)
  e4:SetTarget(c99890180.distg)
  e4:SetOperation(c99890180.disop)
  c:RegisterEffect(e4)
end
c99890180.listed_names={99890170}
--(1) Reveal to search "Fate Lancer, Cu Chulainn"
function c99890180.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return not e:GetHandler():IsPublic() end
  local e1=Effect.CreateEffect(e:GetHandler())
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_PUBLIC)
  e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
  e:GetHandler():RegisterEffect(e1)
end
function c99890180.thfilter1(c)
  return c:IsCode(99890170) and c:IsAbleToHand()
end
function c99890180.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890180.thfilter1,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
  Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function c99890180.thop1(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890180.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
    Duel.ConfirmCards(1-tp,g)
    if c:IsRelateToEffect(e) then
      Duel.BreakEffect()
      Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
  end
end
--(2) Search on leave field
function c99890180.thfilter2(c)
  return c:IsSetCard(0x989) and bit.band(c:GetType(),0x81)==0x81 and not c:IsCode(99890170) and c:IsAbleToHand()
end
function c99890180.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890180.thfilter2,tp,LOCATION_DECK,0,1,nil) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function c99890180.thop2(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890180.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end
--(3) Destroy
function c99890180.destg(e,tp,eg,ep,ev,re,r,rp,chk)
  local d=Duel.GetAttackTarget()
  if chk ==0 then return Duel.GetAttacker()==e:GetHandler() and d and d:IsDefensePos() end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,d,1,0,0)
end
function c99890180.desop(e,tp,eg,ep,ev,re,r,rp)
  local d=Duel.GetAttackTarget()
  if d~=nil and d:IsRelateToBattle() and d:IsDefensePos() then
    Duel.Destroy(d,REASON_EFFECT)
  end
end
--(4) Discard
function c99890180.distg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,1-tp,1)
end
function c99890180.disop(e,tp,eg,ep,ev,re,r,rp)
  local g=Duel.GetFieldGroup(tp,0,LOCATION_HAND)
  if g:GetCount()>0 then
    local sg=g:RandomSelect(1-tp,1)
    Duel.SendtoGrave(sg,REASON_EFFECT+REASON_DISCARD)
    local tc=sg:GetFirst()
    if tc:IsType(TYPE_MONSTER) and Duel.IsPlayerCanDraw(tp,1)
    and Duel.SelectYesNo(tp,aux.Stringid(99890180,4)) then
      Duel.Hint(HINT_OPSELECTED,1-tp,aux.Stringid(99890180,5))
      Duel.Draw(tp,1,REASON_EFFECT)
    end
  end
end