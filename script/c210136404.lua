--Amzoness Shaman
local s,id=GetID()
function s.initial_effect(c)
	--Link materials
	Link.AddProcedure(c,nil,2,2,s.lcheck)
	c:EnableReviveLimit()
    --Destroy and special summon
    local e1=Effect.CreateEffect(c)
    e1:GetCategory(CATEGORY_DESTROY+CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetTarget(s.destg)
    e1:SetOperation(s.desop)
    c:RegisterEffect(e1)
    --Switch ATK
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_PRE_DAMAGE_CALCULATE)
    e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,{id,1})
    e2:SetCondition(s.atkcon)
    e2:SetOperation(s.atkop)
    c:RegisterEffect(e2)
end
s.listed_series={0x4}
--Link materials
function s.lcheck(g,lc,sumtype,tp)
	return g:IsExists(Card.IsSetCard,1,nil,0x4,lc,sumtype,tp)
end

--Destroy and special summon
function s.desfilter(c,e,tp)
    return c:IsSetCard(0x4) and c:HasLevel()
        and Duel.IsExistingMatchingCard(aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,LOCATION_GRAVE,1,nil,c:GetLevel(),e,tp)
        and (c:IsFaceup() or c:IsLocation(LOCATION_HAND))
end
function s.spfilter(c,lv,e,tp)
	return c:HasLevel() and c:IsLevelBelow(lv) and (c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP) or c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp))
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
	local zone={}
	zone[0]=c:GetLinkedZone(0)
	zone[1]=c:GetLinkedZone(1)
    if chk==0 then return (Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone[tp])>0
		or Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone[1-tp])>0)
        and Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,nil,e,tp) end
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_MZONE)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
	local zone={}
	zone[0]=c:GetLinkedZone(0)
	zone[1]=c:GetLinkedZone(1)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
    local tc=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_MZONE,0,1,1,nil,e,tp):GetFirst()
    if tc and Duel.Destroy(tc,REASON_EFFECT)~=0 then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
        local ft1=Duel.GetLocationCount(tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone[tp])
        local ft2=Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp,LOCATION_REASON_TOFIELD,zone[1-tp])
        local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter),tp,LOCATION_GRAVE,LOCATION_GRAVE,1,1,nil,tc:GetLevel(),e,tp)
        if #g==0 or (ft1==0 and ft2==0) then return end
        local sg=g:GetFirst()
        local s1=ft1>0 and sg:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP)
        local s2=ft2>0 and sg:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,1-tp)
        if s1 and s2 then op=Duel.SelectOption(tp,aux.Stringid(id,0),aux.Stringid(id,1))
        elseif s1 then op=Duel.SelectOption(tp,aux.Stringid(id,0))
        elseif s2 then op=Duel.SelectOption(tp,aux.Stringid(id,1))+1
        else op=2 end
        if op==0 then Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP,zone[tp])
        elseif op==1 then Duel.SpecialSummon(sg,0,tp,1-tp,false,false,POS_FACEUP,zone[1-tp]) end
    end
end

--Switch ATK
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetAttacker()
	local bc=Duel.GetAttackTarget()
	if not bc then return false end
	if tc:IsControler(1-tp) then tc,bc=bc,tc end
	if tc:IsFaceup() and tc:IsSetCard(0x4) then
		e:SetLabelObject(tc)
		return true
	else return false end
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
	local tc=e:GetLabelObject()
	local bc=tc:GetBattleTarget()
	if tc:IsRelateToBattle() and not tc:IsImmuneToEffect(e) and tc:IsControler(tp) and not bc:IsControler(tp) then
        local atk1=tc:GetBaseAttack()
        local atk2=bc:GetBaseAttack()
        local e1=Effect.CreateEffect(c)
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_SET_BASE_ATTACK)
        e1:SetValue(atk2)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(c)
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_SET_BASE_ATTACK)
        e2:SetValue(atk1)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        bc:RegisterEffect(e2)
    end
end
