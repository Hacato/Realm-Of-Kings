--OTNN Break Burst
--Scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
  --(1) Negate Special Summon
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_DISABLE_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetCode(EVENT_SPSUMMON)
  e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
  e1:SetCondition(s.negcon)
  e1:SetTarget(s.negtg)
  e1:SetOperation(s.negop)
  c:RegisterEffect(e1)
end

--Condition: opponent is summoning and no chain yet
function s.negcon(e,tp,eg,ep,ev,re,r,rp)
  return tp~=ep and Duel.GetCurrentChain()==0
end

--Filter: face-up OTNN Xyz with 2+ materials
function s.negfilter(c)
  return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsSetCard(0x993) and c:GetOverlayCount()>=2
end

--Target
function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return Duel.IsExistingMatchingCard(s.negfilter,tp,LOCATION_MZONE,0,1,nil) end
  Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
  Duel.SetOperationInfo(0,CATEGORY_DISABLE_SUMMON,eg,eg:GetCount(),0,0)
  Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,eg:GetCount(),0,0)
  Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0) -- damage calculated later
end

--Operation
function s.negop(e,tp,eg,ep,ev,re,r,rp)
  local g=Duel.GetMatchingGroup(s.negfilter,tp,LOCATION_MZONE,0,nil)
  if #g==0 then return end

  -- Select 1 OTNN Xyz monster to detach
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVEXYZ)
  local tc=g:Select(tp,1,1,nil):GetFirst()

  local og=tc:GetOverlayGroup()
  if #og==0 then return end

  -- Detach all materials
  Duel.SendtoGrave(og,REASON_EFFECT)

  -- Negate the Special Summon
  Duel.NegateSummon(eg)

  -- Destroy the summoned monsters
  Duel.Destroy(eg,REASON_EFFECT)

  -- Calculate damage: half original ATK of destroyed monsters
  local dg=Duel.GetOperatedGroup()
  local atk=0
  for sc in aux.Next(dg) do
    local tatk=sc:GetTextAttack()
    if tatk>0 then atk=atk+tatk end
  end
  if atk>0 then
    Duel.Damage(1-tp,math.floor(atk/2),REASON_EFFECT)
  end
end