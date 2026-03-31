--Alecto the Bringer of Madness
local s,id=GetID()
function s.initial_effect(c)
    c:EnableReviveLimit()
    
    --Ritual Summon
    local e1=Effect.CreateEffect(c)
    e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
    e1:SetType(EFFECT_TYPE_QUICK_O)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetRange(LOCATION_HAND)
    e1:SetHintTiming(0,TIMING_MAIN_END+TIMING_SUMMON+TIMING_SPSUMMON)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.con)
    e1:SetTarget(s.rstg)
    e1:SetOperation(s.rsop)
    c:RegisterEffect(e1)
end

function s.con(e,tp,eg,ep,ev,re,r,rp)
    return (Duel.GetCurrentPhase()==PHASE_MAIN1 or Duel.GetCurrentPhase()==PHASE_MAIN2)
end

s.listed_names={2001003005} -- Offering to the Furies

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
    if chk==0 then
        local c=e:GetHandler()
        local mg=Duel.GetRitualMaterial(tp)
        mg:RemoveCard(c) -- Remove itself from regular materials
        --Add banished monsters from GY as material, using proper filter
        local mg2=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil,c)
        return s.SelfRitualFilter(c,nil,RITPROC_EQUAL,e,tp,mg,mg2,nil,nil,8,nil,POS_FACEUP)
    end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,tp,LOCATION_HAND)
end

function s.rsop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
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
            --Negate effect implementation
            local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
            if #g>0 then
                Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1))
                local tc=g:Select(tp,1,1,nil):GetFirst()
                if tc then
                    Duel.HintSelection(tc,true)
                    --Negate effects
                    local e1=Effect.CreateEffect(c)
                    e1:SetType(EFFECT_TYPE_SINGLE)
                    e1:SetCode(EFFECT_DISABLE)
                    e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                    tc:RegisterEffect(e1)
                    local e2=Effect.CreateEffect(c)
                    e2:SetType(EFFECT_TYPE_SINGLE)
                    e2:SetCode(EFFECT_DISABLE_EFFECT)
                    e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
                    tc:RegisterEffect(e2)
                end
            end
        end
    end
end