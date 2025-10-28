--Fate Ascended Saber, Artoria Pendragon
--Scripted by Raivost
function c99890030.initial_effect(c)
  c:EnableReviveLimit()
  --Special Summon condition
  local e0=Effect.CreateEffect(c)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  e0:SetValue(aux.FALSE)
  c:RegisterEffect(e0)
  --(1) Reveal to search "Fate Saber, Artoria Pendragon"
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99890030,0))
  e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_TODECK)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_HAND)
  e1:SetCountLimit(1,99890030)
  e1:SetCost(c99890030.thcost)
  e1:SetTarget(c99890030.thtg1)
  e1:SetOperation(c99890030.thop1)
  c:RegisterEffect(e1)
  --(2) Search on leave field
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99890030,1))
  e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_LEAVE_FIELD)
  e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
  e2:SetTarget(c99890030.thtg2)
  e2:SetOperation(c99890030.thop2)
  c:RegisterEffect(e2)
  --(3) Gain ATK/DEF
  local e3=Effect.CreateEffect(c)
  e3:SetType(EFFECT_TYPE_FIELD)
  e3:SetCode(EFFECT_UPDATE_ATTACK)
  e3:SetRange(LOCATION_MZONE)
  e3:SetTargetRange(LOCATION_MZONE,0)
  e3:SetCondition(c99890030.atkcon)
  e3:SetTarget(c99890030.atktg)
  e3:SetValue(500)
  c:RegisterEffect(e3)
  local e4=e3:Clone()
  e4:SetCode(EFFECT_UPDATE_DEFENSE)
  c:RegisterEffect(e4)
  --(4) Indes by Spell
  local e5=Effect.CreateEffect(c)
  e5:SetType(EFFECT_TYPE_FIELD)
  e5:SetCode(EFFECT_INDESTRUCTABLE_COUNT)
  e5:SetRange(LOCATION_MZONE)
  e5:SetTargetRange(LOCATION_MZONE,0)
  e5:SetTarget(c99890030.indestg)
  e5:SetValue(c99890030.indesval)
  c:RegisterEffect(e5)
end
c99890030.listed_names={99890020}
--(1) Reveal to search "Fate Saber, Artoria Pendragon"
function c99890030.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return not e:GetHandler():IsPublic() end
  local e1=Effect.CreateEffect(e:GetHandler())
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_PUBLIC)
  e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
  e:GetHandler():RegisterEffect(e1)
end
function c99890030.thfilter1(c)
  return c:IsCode(99890020) and c:IsAbleToHand()
end
function c99890030.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890030.thfilter1,tp,LOCATION_DECK,0,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
  Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end
function c99890030.thop1(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890030.thfilter1,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 and Duel.SendtoHand(g,nil,REASON_EFFECT)>0 then
    Duel.ConfirmCards(1-tp,g)
    if c:IsRelateToEffect(e) then
      Duel.BreakEffect()
      Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
  end
end
--(2) Search on leave field
function c99890030.thfilter2(c)
  return c:IsSetCard(0x989) and bit.band(c:GetType(),0x81)==0x81 and not c:IsCode(99890020) and c:IsAbleToHand()
end
function c99890030.thtg2(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890030.thfilter2,tp,LOCATION_DECK,0,1,nil) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function c99890030.thop2(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890030.thfilter2,tp,LOCATION_DECK,0,1,1,nil)
  if g:GetCount()>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end
--(3) Gain ATK/DEF
function c99890030.atkcon(e)
  return e:GetHandler():IsAttackPos()
end
function c99890030.atktg(e,c)
  return c:IsSetCard(0x989) and c~=e:GetHandler()
end
--(4) Indes by Spell
function c99890030.indestg(e,c)
  return c:IsSetCard(0x989)
end
function c99890030.indesval(e,re,r,rp)
  if bit.band(r,REASON_EFFECT)~=0 and re:IsActiveType(TYPE_SPELL) then
    return 1
  else return 0 end
end