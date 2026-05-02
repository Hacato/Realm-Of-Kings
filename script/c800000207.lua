--Snake Clown
--Scripted by Hacato
local s,id=GetID()
local CARD_IMAGINARY_ACTOR=800000205
function s.initial_effect(c)
	--Always treated as an "Imaginary Arc" card
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x79b)
	c:RegisterEffect(e0)

	--Reveal 1 "Imaginary Arc" monster; Special Summon this card, then maybe Fusion Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,1})
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--If sent to GY as Fusion Material: change 1 opponent's monster Type to Reptile
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.racecon)
	e2:SetTarget(s.racetg)
	e2:SetOperation(s.raceop)
	c:RegisterEffect(e2)
end
s.listed_series={0x79b,0x80b}
s.listed_names={CARD_IMAGINARY_ACTOR}

function s.costfilter(c)
	return c:IsSetCard(0x79b) and c:IsMonster() and not c:IsPublic()
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local rc=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND,0,1,1,e:GetHandler()):GetFirst()
	Duel.ConfirmCards(1-tp,rc)
	Duel.ShuffleHand(tp)
	e:SetLabel(rc:IsCode(CARD_IMAGINARY_ACTOR) and 1 or 0)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND)
end

function s.fusfilter(c,e,tp,mg)
	return c:IsSetCard(0x80b) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and c:CheckFusionMaterial(mg,nil,tp)
end
function s.actorfilter(c)
	return c:IsCode(CARD_IMAGINARY_ACTOR)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local revealed_actor=e:GetLabel()==1
	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	if not revealed_actor then return end

	local hg=Duel.GetMatchingGroup(s.actorfilter,tp,LOCATION_HAND,0,nil)
	local fg=Duel.GetMatchingGroup(Card.IsAbleToGrave,tp,LOCATION_MZONE,0,nil)
	local mg=hg+fg
	if #hg==0 or #fg==0 then return end
	if Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg)
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local fc=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mg):GetFirst()
		if not fc then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FMATERIAL)
		local mat1=hg:FilterSelect(tp,function(mc,fc) return fc:CheckFusionMaterial(mg,mc,tp) end,1,1,nil,fc):GetFirst()
		if not mat1 then return end
		local mat2=fg:FilterSelect(tp,function(mc,fc,mat1)
			local sg=Group.FromCards(mat1,mc)
			return fc:CheckFusionMaterial(sg,nil,tp)
		end,1,1,nil,fc,mat1):GetFirst()
		if not mat2 then return end
		local mat=Group.FromCards(mat1,mat2)
		fc:SetMaterial(mat)
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
		Duel.BreakEffect()
		Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		fc:CompleteProcedure()
	end
end

function s.racecon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_FUSION)
end
function s.racetg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup() end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
end
function s.raceop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_RACE)
		e1:SetValue(RACE_REPTILE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end