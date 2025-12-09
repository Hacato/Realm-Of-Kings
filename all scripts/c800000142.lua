--Favorite HERO Fusion
local s,id=GetID()
function s.initial_effect(c)
	--Fusion Summon 1 "Elemental HERO" Fusion Monster from your Extra Deck, using monsters from your hand, Deck or field as Fusion Material, including at least 1 Normal monster
	local e1=Fusion.CreateSummonEff{handler=c,
		fusfilter=aux.FilterBoolFunction(Card.IsSetCard,0x3008),
		matfilter=aux.FALSE,
		extrafil=s.fextra,
		extraop=s.extraop,
		extratg=s.extratg}
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
end
s.listed_series={0x3008}
function s.fextrafil(c)
	return c:IsAbleToGrave() and c:IsCanBeFusionMaterial()
end
function s.fcheck(tp,sg,fc)
	return sg:IsExists(Card.IsType,1,nil,TYPE_NORMAL)
end
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(s.fextrafil),tp,LOCATION_HAND+LOCATION_DECK,0,nil),s.fcheck
end
function s.extraop(e,tc,tp,sg)
	--Send materials to GY
	Duel.SendtoGrave(sg,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	--Apply Extra Deck summoning restriction for the rest of the turn
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTarget(s.splimit)
	Duel.RegisterEffect(e1,tp)
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_MZONE)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not (c:IsSetCard(0x3008) or c:IsSetCard(0x9) or c:IsSetCard(0x1f) or c:IsSetCard(0x19d))
end