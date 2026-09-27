--OTNN Tail Red - Riser Chain
--Scripted by Raivost
function c99930040.initial_effect(c)
  c:EnableReviveLimit()
  --Cannot be Xyz Summoned. Must be Special Summoned by using a Rank 5+ "OTNN" Xyz Monster as material
  Xyz.AddProcedure(c,nil,5,1,c99930040.ovfilter,aux.Stringid(99930040,0))
  local e0=Effect.CreateEffect(c)
  e0:SetType(EFFECT_TYPE_SINGLE)
  e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
  e0:SetCode(EFFECT_SPSUMMON_CONDITION)
  e0:SetValue(c99930040.splimit)
  c:RegisterEffect(e0)
  --(1) This card gains 1 Rank for each material attached to it
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_UPDATE_RANK)
  e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
  e1:SetRange(LOCATION_MZONE)
  e1:SetValue(c99930040.rankval)
  c:RegisterEffect(e1)
  --(2) If this card attacks, before damage calculation: It gains ATK equal to its Rank x 500 until the end of the Damage Step
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(99930040,0))
  e2:SetCategory(CATEGORY_ATKCHANGE)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e2:SetCode(EVENT_ATTACK_ANNOUNCE)
  e2:SetOperation(c99930040.atkop)
  c:RegisterEffect(e2)
  --(3) If this card destroys a monster by battle: You can attach that monster to this card as material
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(99930040,1))
  e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e3:SetCode(EVENT_BATTLE_DESTROYING)
  e3:SetCondition(aux.bdocon)
  e3:SetTarget(c99930040.attachtg)
  e3:SetOperation(c99930040.attachop)
  c:RegisterEffect(e3)
  --(4) At the start of the Damage Step, if this card attacks a monster: You can attach that monster, then make a second attack with double ATK and opponent can't activate cards/effects
  local e4=Effect.CreateEffect(c)
  e4:SetDescription(aux.Stringid(99930040,2))
  e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e4:SetCode(EVENT_BATTLE_CONFIRM)
  e4:SetCondition(c99930040.attach2con)
  e4:SetTarget(c99930040.attach2tg)
  e4:SetOperation(c99930040.attach2op)
  c:RegisterEffect(e4)
  -- Apply double ATK and restriction when making the second attack from this effect
  local e4b=Effect.CreateEffect(c)
  e4b:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
  e4b:SetCode(EVENT_BATTLE_CONFIRM)
  e4b:SetCondition(c99930040.atkdoublecon)
  e4b:SetOperation(c99930040.atkdoubleop)
  c:RegisterEffect(e4b)
  --(5) While this card has a material owned by opponent: If this card destroys a monster by battle: Inflict damage equal to that monster's original ATK
  local e5=Effect.CreateEffect(c)
  e5:SetDescription(aux.Stringid(99930040,3))
  e5:SetCategory(CATEGORY_DAMAGE)
  e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
  e5:SetCode(EVENT_BATTLE_DESTROYING)
  e5:SetCondition(c99930040.damcon)
  e5:SetTarget(c99930040.damtg)
  e5:SetOperation(c99930040.damop)
  c:RegisterEffect(e5)
end

--Xyz Summon restrictions
function c99930040.splimit(e,se,sp,st)
  return (st&SUMMON_TYPE_XYZ)==SUMMON_TYPE_XYZ
end
function c99930040.ovfilter(c)
  return c:IsFaceup() and c:IsSetCard(0x993) and c:IsType(TYPE_XYZ) and c:GetRank()>=5
end

--(1) Gain Rank equal to material count
function c99930040.rankval(e,c)
  return c:GetOverlayCount()
end

--(2) Gain ATK
function c99930040.atkop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  if c:IsRelateToEffect(e) and c:IsFaceup() then
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_SINGLE)
    e1:SetCode(EFFECT_UPDATE_ATTACK)
    e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_DAMAGE)
    e1:SetValue(c:GetRank()*500)
    c:RegisterEffect(e1)
  end
end

--(3) Attach when destroys by battle
function c99930040.attachtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) end
end
function c99930040.attachop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local tc=c:GetBattleTarget()
  if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsAbleToChangeControler() 
  and not tc:IsImmuneToEffect(e) and not tc:IsHasEffect(EFFECT_NECRO_VALLEY) then
    local og=tc:GetOverlayGroup()
    if og:GetCount()>0 then
      Duel.SendtoGrave(og,REASON_RULE)
    end
    Duel.Overlay(c,Group.FromCards(tc))
  end
end

--(4) Attach at start of Damage Step, then second attack with double ATK
function c99930040.attach2con(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local bc=c:GetBattleTarget()
  -- First attack of the Battle Phase, attacking a monster
  return c==Duel.GetAttacker() and bc and bc:IsMonster()
end
function c99930040.attach2tg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsType(TYPE_XYZ) end
end
function c99930040.attach2op(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local tc=c:GetBattleTarget()
  if not c:IsRelateToEffect(e) or not c:IsFaceup() or not tc or not tc:IsRelateToBattle() then return end
  
  -- Attach the monster
  if tc:IsAbleToChangeControler() and not tc:IsImmuneToEffect(e) and not tc:IsHasEffect(EFFECT_NECRO_VALLEY) then
    local og=tc:GetOverlayGroup()
    if og:GetCount()>0 then
      Duel.SendtoGrave(og,REASON_RULE)
    end
    if Duel.Overlay(c,Group.FromCards(tc))~=0 then
      -- Grant second attack
      local e1=Effect.CreateEffect(c)
      e1:SetType(EFFECT_TYPE_SINGLE)
      e1:SetCode(EFFECT_EXTRA_ATTACK)
      e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
      e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_BATTLE)
      e1:SetValue(1)
      c:RegisterEffect(e1)
      
      -- Mark that this card used this effect and should get bonuses on second attack
      c:RegisterFlagEffect(99930040,RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,0,1)
    end
  end
end

-- Apply double ATK and activation restriction when making second attack via the effect
function c99930040.atkdoublecon(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  -- Check if this is a second or later attack and we used the attach effect
  return c==Duel.GetAttacker() and c:GetFlagEffect(99930040)>0 and c:GetFlagEffect(99930041)==0
end
function c99930040.atkdoubleop(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  
  -- Mark that we already applied this once
  c:RegisterFlagEffect(99930041,RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,0,1)
  
  -- Get current ATK and double it
  local atk=c:GetAttack()
  local e1=Effect.CreateEffect(c)
  e1:SetType(EFFECT_TYPE_SINGLE)
  e1:SetCode(EFFECT_SET_ATTACK_FINAL)
  e1:SetValue(atk*2)
  e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_DAMAGE)
  c:RegisterEffect(e1)
  
  -- Opponent cannot activate cards/effects on the field
  local e2=Effect.CreateEffect(c)
  e2:SetType(EFFECT_TYPE_FIELD)
  e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
  e2:SetCode(EFFECT_CANNOT_ACTIVATE)
  e2:SetTargetRange(0,1)
  e2:SetValue(c99930040.aclimit)
  e2:SetReset(RESET_PHASE+PHASE_DAMAGE)
  Duel.RegisterEffect(e2,tp)
end

function c99930040.aclimit(e,re,tp)
  local rc=re:GetHandler()
  return rc:IsOnField()
end

--(5) Inflict damage equal to original ATK (only when has opponent's material)
function c99930040.damcon(e,tp,eg,ep,ev,re,r,rp)
  if not aux.bdocon(e,tp,eg,ep,ev,re,r,rp) then return false end
  local og=e:GetHandler():GetOverlayGroup()
  return og:IsExists(Card.IsPreviousControler,1,nil,1-tp)
end
function c99930040.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  local bc=e:GetHandler():GetBattleTarget()
  local dam=bc:GetBaseAttack()
  if dam<0 then dam=0 end
  Duel.SetTargetPlayer(1-tp)
  Duel.SetTargetParam(dam)
  Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,dam)
end
function c99930040.damop(e,tp,eg,ep,ev,re,r,rp)
  local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
  local d=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
  Duel.Damage(p,d,REASON_EFFECT)
end