--Overlord Nazarick's Combat Maids
--Scripted by Raivost
function c800000094.initial_effect(c)
  --Activate
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_ACTIVATE)
  e0:SetCode(EVENT_FREE_CHAIN)
  c:RegisterEffect(e0)
  --(1) Special Summon Pleiades
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(800000094,0))
  e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_SZONE)
  e1:SetCountLimit(1)
  e1:SetCondition(c800000094.spcon)
  e1:SetTarget(c800000094.sptg)
  e1:SetOperation(c800000094.spop)
  c:RegisterEffect(e1)
  --(2) Add OverLord Spell/Trap
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(800000094,1))
  e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e2:SetType(EFFECT_TYPE_IGNITION)
  e2:SetRange(LOCATION_SZONE)
  e2:SetCountLimit(1,800000094)
  e2:SetCost(c800000094.thcost)
  e2:SetTarget(c800000094.thtg)
  e2:SetOperation(c800000094.thop)
  c:RegisterEffect(e2)
end
--(1) Special Summon Pleiades
function c800000094.spcon(e,tp,eg,ep,ev,re,r,rp)
  return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)<Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
end
function c800000094.spfilter(c,e,tp)
  return c:IsSetCard(0xB92) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function c800000094.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    and Duel.IsExistingMatchingCard(c800000094.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) end
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end
function c800000094.spop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,c800000094.spfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
  if g:GetCount()>0 then
    Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
  end
end
--(2) Add OverLord Spell/Trap
function c800000094.costfilter(c)
  return c:IsSetCard(0xB92) and c:IsReleasable()
end
function c800000094.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c800000094.costfilter,tp,LOCATION_MZONE,0,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
  local g=Duel.SelectMatchingCard(tp,c800000094.costfilter,tp,LOCATION_MZONE,0,1,1,nil)
  Duel.Release(g,REASON_COST)
end
function c800000094.thfilter(c)
  return c:IsSetCard(0x992) and c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsAbleToHand()
end
function c800000094.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c800000094.thfilter,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function c800000094.thop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c800000094.thfilter,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end