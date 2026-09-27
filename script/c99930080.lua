--OTNN Twoearle
--Scripted by Hacato (Fixed)
local s,id=GetID()
function s.initial_effect(c)
  --(1) Special Summon from hand
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_FIELD)
  e1:SetCode(EFFECT_SPSUMMON_PROC)
  e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
  e1:SetRange(LOCATION_HAND)
  e1:SetCondition(s.hspcon)
  c:RegisterEffect(e1)

  --(2) To Hand
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,0))
  e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCode(EVENT_TO_GRAVE)
  e2:SetProperty(EFFECT_FLAG_DELAY)
  e2:SetCountLimit(1,id)
  e2:SetTarget(s.thtg)
  e2:SetOperation(s.thop)
  c:RegisterEffect(e2)

  --(3) Special Summon Xyz
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(id,1))
  e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e3:SetType(EFFECT_TYPE_IGNITION)
  e3:SetRange(LOCATION_MZONE)
  e3:SetCountLimit(1,id+1)
  e3:SetCondition(s.spcon)
  e3:SetTarget(s.sptg)
  e3:SetOperation(s.spop)
  c:RegisterEffect(e3)

  --(4) Gain Rank
  local e4=Effect.CreateEffect(c)
  e4:SetType(EFFECT_TYPE_XMATERIAL)
  e4:SetCode(EFFECT_UPDATE_RANK)
  e4:SetValue(s.rankval)
  c:RegisterEffect(e4)
end

--(1) Special Summon condition
function s.hspcon(e,c)
  if c==nil then return true end
  local tp=c:GetControler()
  return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
    and (
      Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE) >
      Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
      or not Duel.IsExistingMatchingCard(function(c)
          return c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
        end,tp,LOCATION_MZONE,0,1,nil)
    )
end

--(2) Search
function s.thfilter(c)
  return c:IsSetCard(0x993) and c:IsType(TYPE_SPELL) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
  end
  Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
  local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
  if #g>0 then
    Duel.SendtoHand(g,nil,REASON_EFFECT)
    Duel.ConfirmCards(1-tp,g)
  end
end

--(3) Xyz Summon condition
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
  return not Duel.IsExistingMatchingCard(function(c)
    return c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
  end,tp,LOCATION_MZONE,0,1,nil)
end

function s.spfilter(c,e,tp,mc)
  return c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
    and mc:IsCanBeXyzMaterial(c)
end

function s.matfilter(c)
  return c:IsSetCard(0x993) and not c:IsType(TYPE_XYZ)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    return Duel.GetLocationCountFromEx(tp,tp,nil)>0
      and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_MZONE,0,1,nil)
      and Duel.IsExistingMatchingCard(function(c)
          return c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
        end,tp,LOCATION_EXTRA,0,1,nil)
  end
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCountFromEx(tp,tp,nil)<=0 then return end

  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
  local mg=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_MZONE,0,1,1,nil)
  local mc=mg:GetFirst()
  if not mc then return end

  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local sg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mc)
  local sc=sg:GetFirst()
  if not sc then return end

  sc:SetMaterial(mg)
  Duel.Overlay(sc,mg)

  Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
  sc:CompleteProcedure()
end

--(4) Rank gain
function s.rankval(e,c)
  return Duel.GetFieldGroupCount(0,LOCATION_MZONE,LOCATION_MZONE)-1
end