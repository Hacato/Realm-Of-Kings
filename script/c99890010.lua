--Fate Servant Summoning Ritual
--Scripted by Raivost, modified by Hacato
function c99890010.initial_effect(c)
  --Activate
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_ACTIVATE)
  e0:SetCode(EVENT_FREE_CHAIN)
  c:RegisterEffect(e0)
  --(1) Ritual Summon
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99890010,0))
  e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetRange(LOCATION_FZONE)
  e1:SetTarget(c99890010.sptg)
  e1:SetOperation(c99890010.spop)
  c:RegisterEffect(e1)
  --(2) Shuffle condition
  local e2=Effect.CreateEffect(c)
  e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
  e2:SetCode(EVENT_SPSUMMON_SUCCESS)
  e2:SetRange(LOCATION_FZONE)
  e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
  e2:SetCondition(c99890010.sccon)
  e2:SetOperation(c99890010.scop)
  c:RegisterEffect(e2)
  --(3) Search
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(99890010,2))
  e3:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e3:SetType(EFFECT_TYPE_IGNITION)
  e3:SetRange(LOCATION_FZONE)
  e3:SetCountLimit(1,99890010)
  e3:SetCost(c99890010.thcost)
  e3:SetTarget(c99890010.thtg)
  e3:SetOperation(c99890010.thop)
  c:RegisterEffect(e3)
end

--(1) Ritual Summon
function c99890010.spfilter(c,e,tp,m1,m2,ft)
  if not c:IsSetCard(0x989) or bit.band(c:GetType(),0x81)~=0x81
  or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) then return false end
  local mg=m1:Filter(Card.IsCanBeRitualMaterial,c,c)
  mg:Merge(m2)
  if c.mat_filter then
    mg=mg:Filter(c.mat_filter,nil)
  end
  if mg:IsContains(c) then mg:RemoveCard(c) end
  if ft>0 then
    return mg:CheckWithSumGreater(Card.GetRitualLevel,c:GetLevel(),c)
  else
    return mg:IsExists(c99890010.spmfilterf,1,nil,tp,mg,c)
  end
end
function c99890010.spmfilterf(c,tp,mg,rc)
  if c:IsControler(tp) and c:IsLocation(LOCATION_MZONE) and c:GetSequence()<5 then
    Duel.SetSelectedCard(c)
    return mg:CheckWithSumGreater(Card.GetRitualLevel,rc:GetLevel(),rc)
  else return false end
end
function c99890010.spmfilter(c)
  return c:GetLevel()>0 and c:IsSetCard(0x989) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end
function c99890010.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    local mg1=Duel.GetRitualMaterial(tp)
    local mg2=Duel.GetMatchingGroup(c99890010.spmfilter,tp,LOCATION_DECK,0,nil)
    local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
    return ft>-1 and Duel.IsExistingMatchingCard(c99890010.spfilter,tp,LOCATION_HAND,0,1,nil,e,tp,mg1,mg2,ft)
  end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end
function c99890010.spop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  local mg1=Duel.GetRitualMaterial(tp)
  local mg2=Duel.GetMatchingGroup(c99890010.spmfilter,tp,LOCATION_DECK,0,nil)
  local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,c99890010.spfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp,mg1,mg2,ft)
  local tc=g:GetFirst()
  if tc then
    local mg=mg1:Filter(Card.IsCanBeRitualMaterial,tc,tc)
    mg:Merge(mg2)
    if mg:IsContains(tc) then mg:RemoveCard(tc) end
    local mat=nil
    if ft>0 then
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
      mat=mg:SelectWithSumGreater(tp,Card.GetRitualLevel,tc:GetLevel(),tc)
    else
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
      mat=mg:FilterSelect(tp,c99890010.spmfilterf,1,1,nil,tp,mg,tc)
      Duel.SetSelectedCard(mat)
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
      local mat2=mg:SelectWithSumGreater(tp,Card.GetRitualLevel,tc:GetLevel(),tc)
      mat:Merge(mat2)
    end
    tc:SetMaterial(mat)
    local mat2=mat:Filter(Card.IsLocation,nil,LOCATION_DECK)
    mat:Sub(mat2)
    Duel.ReleaseRitualMaterial(mat)
    Duel.Remove(mat2,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
    Duel.BreakEffect()
    Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
    tc:CompleteProcedure()
  end
end

--(2) Shuffle condition (fixed)
function c99890010.scfilter(c,tp)
  return c:IsSetCard(0x989) and c:IsSummonType(SUMMON_TYPE_RITUAL) and c:GetSummonPlayer()==tp
end
function c99890010.sccon(e,tp,eg,ep,ev,re,r,rp)
  return eg:IsExists(c99890010.scfilter,1,nil,tp) and re:GetHandler()==e:GetHandler()
end
function c99890010.scop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local rc=eg:GetFirst()
  -- Store the material group instead of relying on the monster
  local mat=rc:GetMaterial():Filter(Card.IsLocation,nil,LOCATION_REMOVED)
  if #mat==0 then return end
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99890010,1))
  e1:SetCategory(CATEGORY_TODECK)
  e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
  e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
  e1:SetRange(LOCATION_FZONE)
  e1:SetLabelObject(mat)
  e1:SetLabel(Duel.GetTurnCount())
  e1:SetCondition(c99890010.tdcon)
  e1:SetTarget(c99890010.tdtg)
  e1:SetOperation(c99890010.tdop)
  c:RegisterEffect(e1)
end
function c99890010.tdcon(e,tp,eg,ep,ev,re,r,rp)
  return Duel.GetTurnPlayer()==tp and Duel.GetTurnCount()>e:GetLabel()
end
function c99890010.tdfilter(c)
  return c:IsLocation(LOCATION_REMOVED) and c:IsAbleToDeck()
end
function c99890010.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
  local g=e:GetLabelObject()
  if not g then return false end
  local tg=g:Filter(c99890010.tdfilter,nil)
  if chk==0 then return #tg>0 end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,#tg,0,0)
end
function c99890010.tdop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if not c:IsRelateToEffect(e) then return end
  local g=e:GetLabelObject()
  if not g then return end
  local tg=g:Filter(c99890010.tdfilter,nil)
  if #tg>0 then
    Duel.SendtoDeck(tg,nil,2,REASON_EFFECT)
  end
end

--(3) Search
function c99890010.thcostfilter(c)
  return c:IsType(TYPE_MONSTER) and c:IsSetCard(0xF09) and c:IsAbleToDeckAsCost()
end
function c99890010.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890010.thcostfilter,tp,LOCATION_HAND,0,1,nil) end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
  local g=Duel.SelectMatchingCard(tp,c99890010.thcostfilter,tp,LOCATION_HAND,0,1,1,nil)
  Duel.SendtoDeck(g,nil,2,REASON_COST)
end
function c99890010.thfilter(c)
  return c:IsSetCard(0x989) and c:IsType(TYPE_MONSTER)
    and bit.band(c:GetType(),0x81)==0x81 and c:IsAbleToHand()
end
function c99890010.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(c99890010.thfilter,tp,LOCATION_DECK,0,1,nil) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function c99890010.thop(e,tp,eg,ep,ev,re,r,rp)
  if not e:GetHandler():IsRelateToEffect(e) then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,c99890010.thfilter,tp,LOCATION_DECK,0,1,1,nil)
  if #g>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end