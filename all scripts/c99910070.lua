--YuYuYu Sea of Trees
--Scripted by Raivost
function c99910070.initial_effect(c)
  --Activate
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_ACTIVATE)
  e0:SetCode(EVENT_FREE_CHAIN)
  c:RegisterEffect(e0)
  --(1) Search
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99910070,0))
  e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_FZONE)
  e1:SetCountLimit(1,99910070)
  e1:SetCost(c99910070.thcost)
  e1:SetTarget(c99910070.thtg)
  e1:SetOperation(c99910070.thop)
  c:RegisterEffect(e1)
  --(2) Equip from hand
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99910070,1))
  e2:SetCategory(CATEGORY_EQUIP)
  e2:SetType(EFFECT_TYPE_IGNITION)
  e2:SetRange(LOCATION_FZONE)
  e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e2:SetCountLimit(1)
  e2:SetTarget(c99910070.eqtg)
  e2:SetOperation(c99910070.eqop)
  c:RegisterEffect(e2)
  --(3) Gain LP when equipped monster sent to GY
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(99910070,2))
  e3:SetCategory(CATEGORY_RECOVER)
  e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
  e3:SetCode(EVENT_TO_GRAVE)
  e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
  e3:SetRange(LOCATION_FZONE)
  e3:SetCondition(c99910070.reccon)
  e3:SetTarget(c99910070.rectg)
  e3:SetOperation(c99910070.recop)
  c:RegisterEffect(e3)
end
--(1) Search
function c99910070.thcostfilter(c)
  return c:IsSetCard(0x991) and c:IsRace(RACE_FAIRY) and c:IsAbleToGraveAsCost()
end
function c99910070.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99910070.thcostfilter,tp,LOCATION_HAND,0,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
  local g=Duel.SelectMatchingCard(tp,c99910070.thcostfilter,tp,LOCATION_HAND,0,1,1,nil)
  Duel.SendtoGrave(g,REASON_COST)
end
function c99910070.thfilter(c)
  return c:IsSetCard(0x991) and not c:IsCode(99910070) and c:IsAbleToHand()
end
function c99910070.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99910070.thfilter,tp,LOCATION_DECK,0,1,nil) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function c99910070.thop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99910070.thfilter,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end
--(2) Equip from hand
function c99910070.eqfilter(c)
  return c:IsSetCard(0x991) and c:IsRace(RACE_FAIRY) and c:IsType(TYPE_MONSTER) and not c:IsForbidden()
end
function c99910070.eqtgfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x991)
end
function c99910070.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and c99910070.eqtgfilter(chkc) end
  if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
    and Duel.IsExistingMatchingCard(c99910070.eqfilter,tp,LOCATION_HAND,0,1,nil)
    and Duel.IsExistingTarget(c99910070.eqtgfilter,tp,LOCATION_MZONE,0,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SelectTarget(tp,c99910070.eqtgfilter,tp,LOCATION_MZONE,0,1,1,nil)
  Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_HAND)
end
function c99910070.eqop(e,tp,eg,ep,ev,re,r,rp)
  local tc=Duel.GetFirstTarget()
  if not tc or not tc:IsRelateToEffect(e) or not tc:IsFaceup() or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
  local g=Duel.SelectMatchingCard(tp,c99910070.eqfilter,tp,LOCATION_HAND,0,1,1,nil)
  local ec=g:GetFirst()
  if ec then
    Duel.Equip(tp,ec,tc)
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_EQUIP_LIMIT)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetReset(RESET_EVENT+RESETS_STANDARD)
    e1:SetValue(c99910070.eqlimit)
    e1:SetLabelObject(tc)
    ec:RegisterEffect(e1)
  end
end
function c99910070.eqlimit(e,c)
  return c==e:GetLabelObject()
end
--(3) Gain LP
function c99910070.recconfilter(c,tp)
  return c:IsPreviousLocation(LOCATION_SZONE) and c:GetPreviousTypeOnField()&TYPE_EQUIP~=0
    and c:IsSetCard(0x991) and c:IsRace(RACE_FAIRY) and c:IsPreviousControler(tp)
    and c:GetPreviousEquipTarget() and c:GetPreviousEquipTarget():IsSetCard(0x991)
end
function c99910070.reccon(e,tp,eg,ep,ev,re,r,rp)
  return eg:IsExists(c99910070.recconfilter,1,nil,tp)
end
function c99910070.rectg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.SetTargetPlayer(tp)
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  local ct=eg:FilterCount(c99910070.recconfilter,nil,tp)
  Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,500*ct)
end
function c99910070.recop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
  local ct=eg:FilterCount(c99910070.recconfilter,nil,tp)
  Duel.Recover(p,500*ct,REASON_EFFECT)
end