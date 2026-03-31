--Greater Terrorking Archfiend
local s,id=GetID()
function s.initial_effect(c)
    c:SetUniqueOnField(1,0,id)
    --link sum
    c:EnableReviveLimit()
	--Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsCode,35975813),1,1)
	Link.AddProcedure(c,s.matfilter,1,1,s.lcheck)
	--maintain
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.mtcon)
	e1:SetOperation(s.mtop)
	c:RegisterEffect(e1)
	--immune
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.efilter)
	c:RegisterEffect(e2)
	--negate and destroy
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_CHAIN_SOLVING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
	--disable
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_BATTLE_START)
	e4:SetOperation(s.disop2)
	c:RegisterEffect(e4)
	--disable bdes
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e5:SetCode(EVENT_BATTLED)
	e5:SetRange(LOCATION_MZONE)
	e5:SetOperation(s.disop3)
	c:RegisterEffect(e5)
	--move
	local e6=Effect.CreateEffect(c)
	e6:SetDescription(aux.Stringid(id,0))
	e6:SetType(EFFECT_TYPE_IGNITION)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCountLimit(1)
	e6:SetTarget(s.seqtg)
	e6:SetOperation(s.seqop)
	c:RegisterEffect(e6)
    --sp sum
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(id,1))
	e7:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e7:SetType(EFFECT_TYPE_QUICK_O)
	e7:SetCode(EVENT_FREE_CHAIN)
	e7:SetRange(LOCATION_MZONE)
	e7:SetCountLimit(1)
	e7:SetCost(s.spcost)
	e7:SetTarget(s.sptg)
	e7:SetOperation(s.spop)
	c:RegisterEffect(e7)
end
s.listed_series={0x45}
s.listed_names={35975813}
s.roll_dice=true
function s.matfilter(c,lc,stype,tp)--link sum
	return c:IsSetCard(0x45,lc,stype,tp) and not c:IsType(TYPE_LINK,lc,stype,tp)
end
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSummonCode,1,nil,lc,sumtype,tp,35975813)
end
function s.mtcon(e,tp,eg,ep,ev,re,r,rp)--maintain
	return Duel.GetTurnPlayer()==tp
end
function s.mtop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.CheckLPCost(tp,1600) then
		Duel.PayLPCost(tp,1600)
	else
		Duel.Destroy(e:GetHandler(),REASON_COST)
	end
end
function s.efilter(e,re,rp,c)--immune
	return e:GetHandlerPlayer()~=re:GetOwnerPlayer() and not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)--dice roll
	if ep==tp then return end
	if not re:IsHasProperty(EFFECT_FLAG_CARD_TARGET) then return false end
	local tg=Duel.GetChainInfo(ev,CHAININFO_TARGET_CARDS)
	if not tg or not tg:IsContains(e:GetHandler()) or not Duel.IsChainDisablable(ev) then return false end
	local rc=re:GetHandler()
	local dc=Duel.TossDice(tp,1)
	if dc==2 or dc==4 or dc==5 then
	    if Duel.NegateEffect(ev) and rc:IsRelateToEffect(re) then
		    Duel.Destroy(rc,REASON_EFFECT)
	    end
    end
end
function s.disop2(e,tp,eg,ep,ev,re,r,rp)--neg effs of battling m
	local tc=e:GetHandler():GetBattleTarget()
	if tc then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1,true)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2,true)
	end
end
function s.disop3(e,tp,eg,ep,ev,re,r,rp)--neg effs of a m des by b
	local c=e:GetHandler()
	local tc=c:GetBattleTarget()
	if tc and tc:IsType(TYPE_EFFECT) and tc:IsStatus(STATUS_BATTLE_DESTROYED) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_EXC_GRAVE)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD_EXC_GRAVE)
		tc:RegisterEffect(e2)
	end
end
function s.seqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)--move
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
end
function s.seqop(e,tp,eg,ep,ev,re,r,rp)
	Duel.MoveSequence(e:GetHandler(),math.log(Duel.SelectDisableField(tp,1,LOCATION_MZONE,0,0),2))
end
function s.filter(c)--sp sum
	return c.roll_dice and c:IsSetCard(0x45) and c:IsType(TYPE_MONSTER)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckReleaseGroupCost(tp,s.filter,1,false,nil,e:GetHandler()) end
	local g=Duel.SelectReleaseGroupCost(tp,s.filter,1,1,false,nil,e:GetHandler())
	Duel.Release(g,REASON_COST)
end
function s.spfilter(c,e,tp,pos)
	return c.roll_dice and c:IsSetCard(0x45) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,pos)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return --Duel.GetLocationCount(tp,LOCATION_MZONE)>=0 
	Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp,POS_FACEUP) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if not e:GetHandler():IsRelateToEffect(e) then return end
	--if Duel.GetLocationCount(tp,LOCATION_MZONE)>=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,POS_FACEUP)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end