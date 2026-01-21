--Advanced Dark Magician
local s, id = GetID()
function s.initial_effect(c)
  --link summon
  Link.AddProcedure(c,s.matfilter,2,2)
  c:EnableReviveLimit()
  -- Ritual Summon from hand or GY.
  local e1=Ritual.CreateProc({handler=c,lvtype=RITPROC_EQUAL,filter=s.ritfilter,extrafil=s.extrafil,extraop=s.extraop,matfilter=s.forcedgroup,location=LOCATION_HAND+LOCATION_GRAVE})
  e1:SetType(EFFECT_TYPE_IGNITION)
  e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DECKDES)
  e1:SetRange(LOCATION_MZONE)
  e1:SetCountLimit(1,id)
  c:RegisterEffect(e1)
  local e2=Effect.CreateEffect(c)
  e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e2:SetCategory(CATEGORY_DESTROY)
  e2:SetCode(EVENT_BATTLE_START)
  e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DAMAGE_STEP)
  e2:SetRange(LOCATION_MZONE)
  e2:SetCountLimit(1)
  e2:SetTarget(s.destg)
  e2:SetOperation(s.desop)
  c:RegisterEffect(e2)
end
s.listed_series={0x20a2}
s.material_setcode={0x20a2}
-- Link Summon material filter
function s.matfilter(c,lc,sumtype,tp)
  return c:IsSetCard(0x20a2) or
    (c:IsRace(RACE_SPELLCASTER,lc,sumtype,tp) and c:IsAttribute(ATTRIBUTE_DARK,lc,sumtype,tp))
end
-- Ritual Summon from hand/GY by sending from Deck.
function s.ritfilter(c)
  return c:IsRace(RACE_SPELLCASTER) and c:IsRitualMonster()
end
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
    return Duel.GetFieldGroup(tp,LOCATION_DECK,0)
end
function s.extraop(mat,e,tp,eg,ep,ev,re,r,rp,tc)
    return Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end
function s.forcedgroup(c,e,tp)
    return c:IsLocation(LOCATION_DECK) and c:IsRace(RACE_SPELLCASTER) and c:IsAbleToGrave()
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(1-tp) end
  local d=Duel.GetAttackTarget()
  local lnkg = e:GetHandler():GetLinkedGroup()
	if chk ==0 then	return Duel.GetAttacker()==e:GetHandler() and d~=nil and d:IsRelateToBattle()
    and #lnkg > 0 and Duel.IsExistingTarget(nil,tp,0,LOCATION_SZONE,1,nil) end

  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,nil,tp,0,LOCATION_SZONE,1,#lnkg,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
  local g=Duel.GetTargetCards(e)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end
