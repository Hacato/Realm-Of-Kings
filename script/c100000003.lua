--Galaxy Photon Bounzer
local s,id=GetID()
function s.initial_effect(c)
	--Special summon self and a monster from GY if a "Galaxy", "Photon" or "Bounzer" monster is destroyed
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

--Check if a "Galaxy", "Photon" or "Bounzer" monster was destroyed and sent to GY
function s.cfilter(c,tp)
	return c:IsReason(REASON_DESTROY) and c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
		and ((c:IsSetCard(0x55) or c:IsSetCard(0x7b) or c:IsSetCard(0x6b)) and c:IsMonster())
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

--Target filter for destroyed "Galaxy", "Photon" or "Bounzer" monsters
function s.tgfilter(c,e,tp)
	return s.cfilter(c,tp) and c:IsLocation(LOCATION_GRAVE) and c:IsCanBeEffectTarget(e)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) and s.tgfilter(chkc,e,tp) end
	local g=eg:Filter(s.tgfilter,nil,e,tp)
	if chk==0 then return #g>0 and Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=g:Select(tp,1,1,nil)
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,sg,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) or not tc or not tc:IsRelateToEffect(e) then return end
	
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	
	local g=Group.FromCards(c,tc)
	if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)==2 then
		--Gain ATK equal to the original ATK of the targeted monster
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(tc:GetBaseAttack())
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)
	end
end