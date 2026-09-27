--Fiendish Chain Resonator
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon itself from the hand, then possibly draw 1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Grant effect to a DARK Dragon Synchro Monster
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetCondition(s.efcon)
	e2:SetOperation(s.efop)
	c:RegisterEffect(e2)
end

--Check for a face-up monster whose effects are negated
function s.negfilter(c)
	return c:IsFaceup() and c:IsDisabled()
end

function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(
		s.negfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil
	)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,LOCATION_HAND)

	--Show draw in the operation info if the opponent
	--currently controls a negated monster
	if Duel.IsExistingMatchingCard(
		s.negfilter,tp,0,LOCATION_MZONE,1,nil
	) then
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	end
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	if Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		--"also": check the opponent's field after the summon resolves
		if Duel.IsExistingMatchingCard(
			s.negfilter,tp,0,LOCATION_MZONE,1,nil
		) then
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end

--This card must have been used from the field as Synchro Material
function s.efcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return r==REASON_SYNCHRO
		and c:GetPreviousLocation()==LOCATION_MZONE
		and c:IsPreviousPosition(POS_FACEUP)
end

function s.efop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local rc=c:GetReasonCard()
	if not rc then return end
	if not rc:IsType(TYPE_SYNCHRO)
		or not rc:IsAttribute(ATTRIBUTE_DARK)
		or not rc:IsRace(RACE_DRAGON) then
		return
	end

	--The effects of all Attack Position monsters
	--your opponent controls are negated.
	local e1=Effect.CreateEffect(rc)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,LOCATION_MZONE)
	e1:SetTarget(s.distg)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	rc:RegisterEffect(e1,true)

	local e2=e1:Clone()
	e2:SetCode(EFFECT_DISABLE_EFFECT)
	rc:RegisterEffect(e2,true)
end

function s.distg(e,c)
	return c:IsAttackPos()
end