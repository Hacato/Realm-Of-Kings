--Phantasm Mask Master
--Scripted by Hacato
local s,id=GetID()
function s.initial_effect(c)
	--Always treated as "Imaginary Arc"
	c:AddSetcodesRule(0x79b)

	--Reveal 1 "Metarion" Fusion Monster; Special Summon this card, then Special Summon listed material
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end
s.listed_series={0x79b,0x80b}

--Reveal Fusion
function s.fusfilter(c)
	return c:IsType(TYPE_FUSION) and c:IsSetCard(0x80b)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil)
	local tc=g:GetFirst()
	Duel.ConfirmCards(1-tp,tc)
	Duel.ShuffleExtra(tp)

	--Store material codes dynamically
	local mats=tc:GetMaterial()
	if mats then
		e:SetLabelObject(mats)
	end
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND)
end

function s.matfilter(c,e,tp,mg)
	if not mg then return false end
	for tc in aux.Next(mg) do
		if c:IsCode(tc:GetCode())
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false) then
			return true
		end
	end
	return false
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mg=e:GetLabelObject()
	if not mg then return end
	if not c:IsRelateToEffect(e) then return end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	if Duel.IsExistingMatchingCard(s.matfilter,tp,
		LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp,mg)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then

		Duel.BreakEffect()

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.matfilter,tp,
			LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp,mg)
		local sc=sg:GetFirst()

		if sc and Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)>0 then
			--Change this card's name to the other material
			for tc in aux.Next(mg) do
				if not sc:IsCode(tc:GetCode()) then
					local e1=Effect.CreateEffect(c)
					e1:SetType(EFFECT_TYPE_SINGLE)
					e1:SetCode(EFFECT_CHANGE_CODE)
					e1:SetValue(tc:GetCode())
					e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
					c:RegisterEffect(e1)
					break
				end
			end
		end
	end
end