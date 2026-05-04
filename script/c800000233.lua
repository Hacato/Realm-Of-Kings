--Imaginary Arc Turnover
local s,id=GetID()
local SET_METARION=0x80b

function s.initial_effect(c)
	--Negate activation
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetCondition(s.negcon)
	e1:SetTarget(s.negtg)
	e1:SetOperation(s.negop)
	c:RegisterEffect(e1)

	--GY: Fusion Summon by shuffling LIGHT monsters
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(Fusion.SummonEffTG(s.fusfilter,s.matfilter,s.fextra,Fusion.ShuffleMaterial))
	e2:SetOperation(Fusion.SummonEffOP(s.fusfilter,s.matfilter,s.fextra,Fusion.ShuffleMaterial))
	c:RegisterEffect(e2)
end

s.listed_series={SET_METARION}

function s.metfilter(c)
	return c:IsFaceup() and c:IsSetCard(SET_METARION) and c:IsType(TYPE_FUSION)
end

function s.negcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and Duel.IsChainNegatable(ev)
		and Duel.IsExistingMatchingCard(s.metfilter,tp,LOCATION_MZONE,0,1,nil)
end

function s.negtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	local rc=re:GetHandler()
	if rc:IsRelateToEffect(re) and rc:IsDestructable() then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end

function s.negop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) then
		local rc=re:GetHandler()
		if rc:IsRelateToEffect(re) then
			Duel.Destroy(rc,REASON_EFFECT)
		end
	end
end

function s.fusfilter(c)
	return c:IsSetCard(SET_METARION) and c:IsType(TYPE_FUSION)
end

function s.matfilter(c)
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsAbleToDeck()
end

--Add LIGHT monsters from your GY as Fusion Material
function s.fextra(e,tp,mg)
	return Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil)
end