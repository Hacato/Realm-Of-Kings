--OTNN Tail Gear Change
--Scripted by Raivost (Updated Fix)
local s,id=GetID()
function s.initial_effect(c)
  c:SetUniqueOnField(1,0,id)

  --Activate
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_ACTIVATE)
  e0:SetCode(EVENT_FREE_CHAIN)
  c:RegisterEffect(e0)

  --(1) Rank Change (Quick Effect)
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e1:SetType(EFFECT_TYPE_QUICK_O)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetRange(LOCATION_SZONE)
  e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e1:SetCountLimit(1,id)
  e1:SetTarget(s.sptg)
  e1:SetOperation(s.spop)
  c:RegisterEffect(e1)

  --(2) GY effect
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW+CATEGORY_TOHAND)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_TO_GRAVE)
  e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e2:SetCondition(s.tdcon)
  e2:SetCountLimit(1,id+1)
  e2:SetTarget(s.tdtg)
  e2:SetOperation(s.tdop)
  c:RegisterEffect(e2)
end

--========================
-- (1) Rank Change Effect
--========================
function s.xyzfilter(c,e,tp)
  return c:IsFaceup() and c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
    and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c,c:GetOriginalRank(),c:GetCode())
end

function s.spfilter(c,e,tp,mc,rank,code)
  return c:IsSetCard(0x993)
    and c:IsType(TYPE_XYZ)
    and c:GetOriginalRank()==rank
    and not c:IsCode(code)
    and mc:IsCanBeXyzMaterial(c)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then
    return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.xyzfilter(chkc,e,tp)
  end
  if chk==0 then
    return Duel.GetLocationCountFromEx(tp,tp,nil)>0
      and Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil,e,tp)
  end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
  Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil,e,tp)
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
  local tc=Duel.GetFirstTarget()
  if not tc or not tc:IsRelateToEffect(e) or tc:IsFacedown() then return end
  if Duel.GetLocationCountFromEx(tp,tp,tc)<=0 then return end

  local rank=tc:GetOriginalRank()
  local code=tc:GetCode()

  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc,rank,code)
  local sc=g:GetFirst()
  if not sc then return end

  -- Transfer existing materials
  local mg=tc:GetOverlayGroup()
  if #mg>0 then
    Duel.Overlay(sc,mg)
  end

  -- Use target as material
  sc:SetMaterial(Group.FromCards(tc))
  Duel.Overlay(sc,Group.FromCards(tc))

  -- Xyz Summon
  Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
  sc:CompleteProcedure()
end

--========================
-- (2) GY Effect
--========================
function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  return c:IsPreviousLocation(LOCATION_SZONE) and c:IsReason(REASON_DESTROY)
end

function s.xyzgyfilter(c)
  return c:IsSetCard(0x993) and c:IsType(TYPE_XYZ) and c:IsAbleToExtra()
end

function s.nxyzgyfilter(c)
  return c:IsSetCard(0x993) and not c:IsType(TYPE_XYZ) and c:IsAbleToHand()
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then
    return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.xyzgyfilter(chkc)
  end
  if chk==0 then
    return Duel.IsExistingTarget(s.xyzgyfilter,tp,LOCATION_GRAVE,0,1,nil)
  end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
  Duel.SelectTarget(tp,s.xyzgyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
  local tc=Duel.GetFirstTarget()
  if not tc or not tc:IsRelateToEffect(e) then return end

  if Duel.SendtoDeck(tc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 then
    local hasXyz=Duel.IsExistingMatchingCard(function(c)
      return c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
    end,tp,LOCATION_MZONE,0,1,nil)

    if hasXyz then
      Duel.Draw(tp,1,REASON_EFFECT)
    else
      if Duel.IsExistingMatchingCard(s.nxyzgyfilter,tp,LOCATION_GRAVE,0,1,nil) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local g=Duel.SelectMatchingCard(tp,s.nxyzgyfilter,tp,LOCATION_GRAVE,0,1,1,nil)
        if #g>0 then
          Duel.SendtoHand(g,nil,REASON_EFFECT)
          Duel.ConfirmCards(1-tp,g)
        end
      end
    end
  end
end