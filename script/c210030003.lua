--Royal Temple
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
    --Change name
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_FZONE)
	e2:SetValue(29762407)
	c:RegisterEffect(e2)
    --Act in hand
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_TRAP_ACT_IN_HAND)
	e3:SetRange(LOCATION_FZONE)
	e3:SetTargetRange(LOCATION_HAND,0)
    e3:SetCondition(s.actcon)
	e3:SetTarget(s.acttg)
	c:RegisterEffect(e3)
    --Special summon
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1)
	e3:SetCost(s.spcost)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end
s.listed_names={29762407}
local TrapMonster={97232518,44822037,86885905,21843307,20590515,
                   55838342,90440725,54297661,27062594,46984349,
                   28649820,67007102,93191801,60433216,20960340,
                   70406920,26905245,42237854,43959432,35100834,
                   87772572,4904633,92099232,92092092,23626223,
                   13955608,50277973,8522996,3129635,49514333,
                   79852326,54241725,100000212,511001590}
function s.thfilter(c)
	return c:IsCode(89194033,511001305,210030001,210030002,210030008) and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if #g>0 and Duel.GetFlagEffect(tp,id)==0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg=g:Select(tp,1,1,nil)
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
		Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	end
end

--Act in hand
function s.confilter(c,tp)
	return c:IsSummonLocation(LOCATION_EXTRA) and c:IsInMainMZone(tp)
end
function s.actcon(e,tp,eg,ep,ev,re,r,rp)
	return not Duel.IsExistingMatchingCard(s.confilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil,tp)
end
function s.acttg(e,c)
	return c:GetType()==TYPE_TRAP+TYPE_CONTINUOUS and (c:IsSetCard(0x1c2) or c:IsCode(table.unpack(TrapMonster)))
end

--Special Summon
function s.cfilter(c,e,tp,rp)
	if c:IsFacedown() or not c:IsCode(89194033,210030008) or not c:IsAttackAbove(4000) or not c:IsAbleToGraveAsCost() then return false end
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_EXTRA,0,1,nil,e,tp,rp,Group.FromCards(c,e:GetHandler()))
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then return e:GetHandler():IsAbleToGraveAsCost()
		and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_ONFIELD,0,1,nil,e,tp,rp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_ONFIELD,0,1,1,nil,e,tp,rp)
	g:AddCard(e:GetHandler())
	Duel.SendtoGrave(g,REASON_COST)
end
function s.spfilter(c,e,tp,rp,sg)
	if not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return false end
	if c:IsLocation(LOCATION_HAND+LOCATION_DECK) then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	else
		return Duel.GetLocationCountFromEx(tp,rp,sg,c)>0
	end
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_EXTRA,0,1,1,nil,e,tp,rp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end