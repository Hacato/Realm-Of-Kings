--Constructor Ridge Wyrm Handtoolon
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Materials: 2 "Constructor" monsters
	Fusion.AddProcMix(c,true,true,s.ffilter,s.ffilter)
	--Mill and add to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DECKDES+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
	--ATK boost for Wyrm monsters
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(LOCATION_MZONE,0)
	e2:SetTarget(s.atktg)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
end
s.listed_names={id}
s.listed_series={0x1568,0x1569} --Constructor, Blisstopia

--Fusion Material filter: "Constructor" monsters
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x1568,fc,sumtype,tp)
end

--Add to hand condition: Fusion Summoned or Special Summoned by "Constructor" card effect
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION) 
		or (re and re:GetHandler():IsSetCard(0x1568) and re:IsActiveType(TYPE_MONSTER+TYPE_SPELL+TYPE_TRAP))
end
--Add to hand filter
function s.thfilter(c)
	return (c:IsSetCard(0x1569) or c:IsSetCard(0x1568)) and not c:IsCode(id) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.thfilter(chkc) end
	if chk==0 then return Duel.IsPlayerCanDiscardDeck(tp,1)
		and Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DECKDES,nil,0,tp,1)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	--Mill top card
	if Duel.DiscardDeck(tp,1,REASON_EFFECT)>0 then
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) then
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		end
	end
end

--ATK boost target: Wyrm monsters you control
function s.atktg(e,c)
	return c:IsRace(RACE_WYRM)
end
--ATK boost value: 200 for each "Blisstopia" Field Spell in GY
function s.atkval(e,c)
	local ct=Duel.GetMatchingGroupCount(s.blissfilter,e:GetHandlerPlayer(),LOCATION_GRAVE,0,nil)
	return ct*200
end
function s.blissfilter(c)
	return c:IsSetCard(0x1569) and c:IsType(TYPE_FIELD)
end