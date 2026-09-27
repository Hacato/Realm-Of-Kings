--OTNN Eremerian Onslaught
--Scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
  --Activate Trap: Destroy and Rank Boost
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_DESTROY)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
  e1:SetTarget(s.destg)
  e1:SetOperation(s.desop)
  c:RegisterEffect(e1)
  
  --Grave effect: Indes / Untargetable for OTNN Xyz
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetType(EFFECT_TYPE_QUICK_O)
  e2:SetRange(LOCATION_GRAVE)
  e2:SetCode(EVENT_FREE_CHAIN)
  e2:SetCountLimit(1,id+1000) -- separate count limit
  e2:SetCondition(s.indcon)
  e2:SetCost(aux.bfgcost) -- banish this card as cost
  e2:SetOperation(s.indop)
  c:RegisterEffect(e2)
  
  --Track the turn this card was sent to the GY
  local e3=Effect.CreateEffect(c)
  e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
  e3:SetCode(EVENT_TO_GRAVE)
  e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
  e3:SetOperation(s.regturn)
  c:RegisterEffect(e3)
end

-- Store the turn sent to GY
function s.regturn(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  c:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,Duel.GetCurrentPhase())
  
end

--Filters
function s.otnnfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x993) and c:IsType(TYPE_XYZ)
end
function s.desfilter(c)
  return c:IsOnField() and c:IsDestructable()
end

--(1) Destroy / Rank Boost
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  local g=Duel.GetMatchingGroup(s.otnnfilter,tp,LOCATION_MZONE,0,nil)
  if chk==0 then return #g>0 and Duel.IsExistingMatchingCard(s.desfilter,tp,0,LOCATION_ONFIELD,1,nil) end
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
  local g=Duel.GetMatchingGroup(s.otnnfilter,tp,LOCATION_MZONE,0,nil)
  if #g==0 then return end
  local total=0
  -- Detach materials
  for tc in aux.Next(g) do
    local ct=tc:GetOverlayCount()
    if ct>0 then
      local mat=tc:RemoveOverlayCard(tp,1,ct,REASON_EFFECT)
      total=total+mat
    end
  end
  if total==0 then return end
  -- Target and destroy up to total cards
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
  local dg=Duel.SelectMatchingCard(tp,s.desfilter,tp,0,LOCATION_ONFIELD,1,total,nil)
  if #dg>0 and Duel.Destroy(dg,REASON_EFFECT)~=0 then
    -- Boost Rank for all OTNN Xyz
    local og=Duel.GetMatchingGroup(s.otnnfilter,tp,LOCATION_MZONE,0,nil)
    for tc in aux.Next(og) do
      local e1=Effect.CreateEffect(e:GetHandler())
      e1:SetType(EFFECT_TYPE_SINGLE)
      e1:SetCode(EFFECT_UPDATE_RANK)
      e1:SetValue(total)
      e1:SetReset(RESET_EVENT+0x1fe0000)
      tc:RegisterEffect(e1)
    end
  end
end

--(2) Grave Indes / Untargetable
function s.indcon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  -- Cannot activate during the turn it was sent to the GY
  return Duel.GetTurnCount()~=c:GetTurnID()
end

function s.indop(e,tp,eg,ep,ev,re,r,rp)
  local g=Duel.GetMatchingGroup(s.otnnfilter,tp,LOCATION_MZONE,0,nil)
  for tc in aux.Next(g) do
    -- Indestructible by battle
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
    e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
    e1:SetValue(1)
    e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
    tc:RegisterEffect(e1)
    -- Indestructible by effects
    local e2=e1:Clone()
    e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
    e2:SetValue(function(e,re) return e:GetOwnerPlayer()~=re:GetOwnerPlayer() end)
    tc:RegisterEffect(e2)
    -- Cannot be targeted by opponent
    local e3=e1:Clone()
    e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
    e3:SetValue(function(e,re,rp) return rp~=e:GetOwnerPlayer() end)
    tc:RegisterEffect(e3)
  end
end