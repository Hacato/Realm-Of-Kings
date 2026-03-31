--Megaera the Herald of Resentment
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    
    --Ritual Summon during battle
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_BATTLE_START)
    e1:SetRange(LOCATION_HAND)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.spcon)
    e1:SetTarget(s.rstg)
    e1:SetOperation(s.rsop)
    c:RegisterEffect(e1)
    
    --Ritual Summon when opponent Special Summons exactly 1 monster
    local e2=Effect.CreateEffect(c)
    e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
    e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e2:SetCode(EVENT_SPSUMMON_SUCCESS)
    e2:SetRange(LOCATION_HAND)
    e2:SetCountLimit(1,id)
    e2:SetCondition(s.sscon)
    e2:SetTarget(s.sstg)
    e2:SetOperation(s.ssop)
    c:RegisterEffect(e2)
end

s.listed_names={2001003005} -- Offering to the Furies

--Condition for battle effect
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    local a=Duel.GetAttacker()
    local d=Duel.GetAttackTarget()
    if not d then 
        return false 
    end
    if a:IsControler(tp) and d:IsControler(1-tp) then
        e:SetLabelObject(d)
        return true
    elseif d:IsControler(tp) and a:IsControler(1-tp) then
        e:SetLabelObject(a)
        return true
    end
    return false
end

--Condition for Special Summon effect
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
    return #eg==1 and eg:GetFirst():IsControler(1-tp)
end

--Helper function for ritual requirements
local function RitualCheck(sc,lv,forcedselection,_type,requirementfunc)
    local chk
    if _type==RITPROC_EQUAL then
        chk=function(g) return g:GetSum(requirementfunc or Auxiliary.RitualCheckAdditionalLevel,sc)<=lv end
    else
        chk=function(g,c) return g:GetSum(requirementfunc or Auxiliary.RitualCheckAdditionalLevel,sc) - (requirementfunc or Auxiliary.RitualCheckAdditionalLevel)(c,sc)<=lv end
    end
    return function(sg,e,tp,mg,c)
        local res=chk(sg,c)
        if not res then return false,true end
        local stop=false
        if forcedselection then
            local ret=forcedselection(e,tp,sg,sc)
            res=ret[1]
            stop=ret[2] or stop
        end
        if res and not stop then
            if _type==RITPROC_EQUAL then
                res=sg:CheckWithSumEqual(requirementfunc or Card.GetRitualLevel,lv,#sg,#sg,sc)
            else
                Duel.SetSelectedCard(sg)
                res=sg:CheckWithSumGreater(requirementfunc or Card.GetRitualLevel,lv,sc)
            end
            res=res and Duel.GetMZoneCount(tp,sg,tp)>0
        end
        return res,stop
    end
end

--Filter for monsters in GY that can be banished as material
function s.matfilter(c,rc)
    return c:IsMonster() and c:HasLevel() and c:IsAbleToRemove() and c~=rc
end

--Modified Filter function that allows self-ritual
function s.SelfRitualFilter(c,filter,_type,e,tp,m,m2,forcedselection,specificmatfilter,lv,requirementfunc,sumpos)
    if not c:IsOriginalType(TYPE_RITUAL) or not c:IsOriginalType(TYPE_MONSTER) or (filter and not filter(c)) 
        or not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true,sumpos) then return false end
    lv=lv or c:GetLevel()
    lv=math.max(1,lv)
    local mg=m:Filter(Card.IsCanBeRitualMaterial,c,c)
    mg:Sub(Group.FromCards(c)) -- Explicitly remove itself from material pool
    mg:Merge(m2)
    if c.mat_filter then
        mg:Match(c.mat_filter,c,tp)
    end
    if specificmatfilter then
        mg:Match(specificmatfilter,nil,c,mg,tp)
    end
    return aux.SelectUnselectGroup(mg,e,tp,1,lv,RitualCheck(c,lv,forcedselection,_type,requirementfunc),0)
end

function s.rstg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local tc=e:GetLabelObject()
    if chk==0 then
        local mg=Duel.GetRitualMaterial(tp)
        mg:RemoveCard(c) -- Remove itself from regular materials
        --Add banished monsters from GY as material, using proper filter
        local mg2=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil,c)
        return s.SelfRitualFilter(c,nil,RITPROC_EQUAL,e,tp,mg,mg2,nil,nil,8,nil,POS_FACEUP) 
            and tc and tc:IsAbleToRemove()
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_HAND)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,tc,1,0,0)
end

function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
    local c=e:GetHandler()
    local tc=eg:GetFirst()
    if chk==0 then
        local mg=Duel.GetRitualMaterial(tp)
        mg:RemoveCard(c) -- Remove itself from regular materials
        --Add banished monsters from GY as material, using proper filter
        local mg2=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil,c)
        return s.SelfRitualFilter(c,nil,RITPROC_EQUAL,e,tp,mg,mg2,nil,nil,8,nil,POS_FACEUP) 
            and tc and tc:IsAbleToRemove()
    end
    Duel.SetTargetCard(tc)
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_HAND)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,tc,1,0,0)
end

function s.rsop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=e:GetLabelObject()
    if not c:IsRelateToEffect(e) then return end
    
    local mg=Duel.GetRitualMaterial(tp)
    mg:RemoveCard(c) -- Remove itself from regular materials
    local mg2=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil,c)
    
    local mat=nil
    if c.ritual_custom_operation then
        c:ritual_custom_operation(mg,nil,RITPROC_EQUAL)
        mat=c:GetMaterial()
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
        mat=aux.SelectUnselectGroup(mg+mg2,e,tp,1,8,RitualCheck(c,8,nil,RITPROC_EQUAL),1,tp,HINTMSG_RELEASE)
    end
    
    if #mat>0 then
        local mat_gy=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
        local mat_field=mat-mat_gy
        
        c:SetMaterial(mat)
        if #mat_gy>0 then
            Duel.Remove(mat_gy,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
        end
        if #mat_field>0 then
            Duel.Release(mat_field,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
        end
        
        Duel.BreakEffect()
        if Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
            if tc and tc:IsRelateToBattle() then
                Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
            end
        end
    end
end

function s.ssop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    local tc=Duel.GetFirstTarget()
    if not c:IsRelateToEffect(e) then return end
    
    local mg=Duel.GetRitualMaterial(tp)
    mg:RemoveCard(c) -- Remove itself from regular materials
    local mg2=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil,c)
    
    local mat=nil
    if c.ritual_custom_operation then
        c:ritual_custom_operation(mg,nil,RITPROC_EQUAL)
        mat=c:GetMaterial()
    else
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
        mat=aux.SelectUnselectGroup(mg+mg2,e,tp,1,8,RitualCheck(c,8,nil,RITPROC_EQUAL),1,tp,HINTMSG_RELEASE)
    end
    
    if #mat>0 then
        local mat_gy=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
        local mat_field=mat-mat_gy
        
        c:SetMaterial(mat)
        if #mat_gy>0 then
            Duel.Remove(mat_gy,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
        end
        if #mat_field>0 then
            Duel.Release(mat_field,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
        end
        
        Duel.BreakEffect()
        if Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
            if tc and tc:IsRelateToEffect(e) then
                Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
            end
        end
    end
end