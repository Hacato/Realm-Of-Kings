--Number C69: Heraldry Crest - Crowned Coat of Arms
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,5,5,s.ovfilter,aux.Stringid(id,0))
	c:EnableReviveLimit()
	--return up to 2 of your rm ms to the GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetTarget(s.rttg)
	e1:SetOperation(s.rtgop)
	c:RegisterEffect(e1)
	--Sp Summ 1 "Number C69: Heraldry Crest of Horror" from your Ex D by using this c you control as mat
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e2:SetCountLimit(1)
	e2:SetCost(aux.dxmcostgen(1,1,nil))
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2,false,REGISTER_FLAG_DETACH_XMAT)
end
s.listed_series={0x76,0x92}
s.xyz_number=69
s.listed_names={2407234,11522979,2008000044,101208045,101208046}
function s.ovfilter(c,tp,xyzc)--Alternative Xyz Summon
	return c:IsFaceup() and c:IsOriginalCodeRule(2407234)
end
function s.rtgfilter(c)--return up to 2 of your rm ms to the GY
	return c:IsFaceup() and c:IsSetCard(0x76) and c:IsMonster()
end
function s.rttg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_REMOVED) and s.filter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.rtgfilter,tp,LOCATION_REMOVED,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectTarget(tp,s.rtgfilter,tp,LOCATION_REMOVED,0,1,2,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end
function s.rtgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
	local sg=g:Filter(Card.IsRelateToEffect,nil,e)
	if #sg>0 then
		Duel.SendtoGrave(sg,REASON_EFFECT+REASON_RETURN)
	end
end
function s.spfilter(c,e,tp,mc)--Sp Summ 1 "Number C69: Heraldry Crest of Horror" from your Ex D by using this c you control as mat
	return c:IsCode(11522979) and mc:IsCanBeXyzMaterial(c,tp) and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local c=e:GetHandler()
		local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
		return (#pg<=0 or (#pg==1 and pg:IsContains(c))) and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not (c:IsFaceup() and c:IsRelateToEffect(e) and c:IsControler(tp) and not c:IsImmuneToEffect(e)) then return end
	local pg=aux.GetMustBeMaterialGroup(tp,Group.FromCards(c),tp,nil,nil,REASON_XYZ)
	if #pg>1 or (#pg==1 and not pg:IsContains(c)) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,c):GetFirst()
	if not sc then return end
	sc:SetMaterial(c)
	Duel.Overlay(sc,c)
	if Duel.SpecialSummon(sc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
		--Cannot be des by battle or c effs
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetDescription(3008)
		e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
		e1:SetValue(1)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		sc:RegisterEffect(e1,true)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		sc:RegisterEffect(e2,true)
		sc:CompleteProcedure()
		--Opp's ms must attack a "Heraldry Crest" ms
		local e3=Effect.CreateEffect(c)
	    e3:SetType(EFFECT_TYPE_FIELD)
	    e3:SetProperty(EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	    e3:SetCode(EFFECT_MUST_ATTACK)
	    e3:SetTargetRange(0,LOCATION_MZONE)
	    e3:SetCondition(function(e) return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsCode,2407234,11522979,2008000044,101208045,101208046),e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil) end)
	    e3:SetReset(RESET_PHASE|PHASE_END)
	    Duel.RegisterEffect(e3,tp)
		local e4=e3:Clone()
		e4:SetCode(EFFECT_MUST_ATTACK_MONSTER)
		e4:SetValue(aux.TargetBoolFunction(Card.IsCode,2407234,11522979,2008000044,101208045,101208046))
		Duel.RegisterEffect(e4,tp)
        --you choose your opp's btg
        local e5=e3:Clone()
		e5:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_SET_AVAILABLE+EFFECT_FLAG_IGNORE_IMMUNE)
        e5:SetCode(EFFECT_PATRICIAN_OF_DARKNESS)
        e5:SetTargetRange(0,1)
        Duel.RegisterEffect(e5,tp)
	    aux.RegisterClientHint(c,0,tp,1,0,aux.Stringid(id,3))
	end
end