--YuYuYu Ritual Spell
--Scripted by Raivost, updated by Copilot as per Hacato's request
function c99910010.initial_effect(c)
  --(1) Ritual Summon
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(99910010,0))
  e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetTarget(c99910010.target)
  e1:SetOperation(c99910010.activate)
  c:RegisterEffect(e1)
end
function c99910010.filter(c,e,tp)
  return c:IsSetCard(0x991) and bit.band(c:GetType(),0x81)==0x81 and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,false)
end
function c99910010.target(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return false end
    local g=Duel.GetMatchingGroup(c99910010.filter,tp,LOCATION_HAND,0,nil,e,tp)
    if #g==0 then return false end
    local mg=Duel.GetRitualMaterial(tp)
    return g:IsExists(c99910010.ritualcheck,1,nil,mg)
  end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end
function c99910010.ritualcheck(c,mg)
  local testmg=mg:Clone()
  testmg:RemoveCard(c)
  return testmg:CheckWithSumGreater(Card.GetRitualLevel,c:GetLevel(),c)
end
function c99910010.eqfilter(c)
  return c:IsSetCard(0x991) and c:IsRace(RACE_FAIRY) and not c:IsForbidden()
end
function c99910010.activate(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,c99910010.filter,tp,LOCATION_HAND,0,1,1,nil,e,tp)
  local tc=g:GetFirst()
  if not tc then return end
  
  -- Ritual Material selection
  local mg=Duel.GetRitualMaterial(tp)
  mg:RemoveCard(tc)
  if tc:IsLocation(LOCATION_HAND) then
    mg:RemoveCard(tc)
  end
  
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
  local mat=mg:SelectWithSumGreater(tp,Card.GetRitualLevel,tc:GetLevel(),tc)
  if not mat or #mat==0 then return end
  
  tc:SetMaterial(mat)
  Duel.ReleaseRitualMaterial(mat)
  Duel.BreakEffect()
  if Duel.SpecialSummon(tc,SUMMON_TYPE_RITUAL,tp,tp,true,false,POS_FACEUP)~=0 then
    tc:CompleteProcedure()
    
    -- Equip effect
    local sea_of_trees=Duel.IsEnvironment(99910070)
    local b1=sea_of_trees and Duel.IsExistingMatchingCard(c99910010.eqfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
    local b2=Duel.IsExistingMatchingCard(c99910010.eqfilter,tp,LOCATION_HAND,0,1,nil)
    
    if (b1 or b2) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(99910010,1)) then
      Duel.BreakEffect()
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
      local eq
      if b1 then
        eq=Duel.SelectMatchingCard(tp,c99910010.eqfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil):GetFirst()
      else
        eq=Duel.SelectMatchingCard(tp,c99910010.eqfilter,tp,LOCATION_HAND,0,1,1,nil):GetFirst()
      end
      
      if eq then
        Duel.Equip(tp,eq,tc)
        -- Grant equip effect
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_EQUIP_LIMIT)
        e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        e1:SetValue(c99910010.eqlimit)
        e1:SetLabelObject(tc)
        eq:RegisterEffect(e1)
      end
    end
    
    -- LP loss at End Phase
    if Duel.GetFlagEffect(tp,99910010)==0 then
      Duel.RegisterFlagEffect(tp,99910010,RESET_PHASE+PHASE_END,0,1)
      local e2=Effect.CreateEffect(e:GetHandler())
      e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
      e2:SetCode(EVENT_PHASE+PHASE_END)
      e2:SetCountLimit(1)
      e2:SetReset(RESET_PHASE+PHASE_END)
      e2:SetOperation(c99910010.loseop)
      Duel.RegisterEffect(e2,tp)
    end
  end
end
function c99910010.eqlimit(e,c)
  return c==e:GetLabelObject()
end
function c99910010.loseop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_CARD,0,99910010)
  Duel.SetLP(tp,Duel.GetLP(tp)-1000)
end