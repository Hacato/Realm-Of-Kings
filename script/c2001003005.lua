--Offering to the Furies
local s,id=GetID()
function s.initial_effect(c)
    --Ritual Summon from Deck or GY
    local e1=Ritual.CreateProc({
        handler=c,
        lvtype=RITPROC_EQUAL,
        filter=aux.FilterBoolFunction(Card.IsCode,2001003001,2001003002,2001003003),
        extrafil=s.extragroup,
        extraop=s.extraop,
        location=LOCATION_DECK|LOCATION_GRAVE,
        stage2=s.stage2
    })
    e1:SetCountLimit(1,{id,1})
    c:RegisterEffect(e1)
    
    --Return to deck
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_TOHAND)
    e2:SetType(EFFECT_TYPE_IGNITION)
    e2:SetRange(LOCATION_GRAVE)
    e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
    e2:SetCountLimit(1,{id,2})
    e2:SetCost(s.thcost)
    e2:SetTarget(s.thtg)
    e2:SetOperation(s.thop)
    c:RegisterEffect(e2)
end

s.listed_names={2001003001,2001003002,2001003003, 2001003006} --Furies ID codes, Domain of the Furies

--Extra materials from GY that can be banished
function s.extragroup(e,tp,eg,ep,ev,re,r,rp,chk)
    return Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_GRAVE,0,nil)
end

--Filter for monsters in GY that can be banished as material
function s.matfilter(c)
    return c:IsMonster() and c:HasLevel() and c:IsAbleToRemove()
end

--Process banished materials
function s.extraop(mat,e,tp,eg,ep,ev,re,r,rp,tc)
    local mat2=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
    mat:Sub(mat2)
    Duel.ReleaseRitualMaterial(mat)
    Duel.Remove(mat2,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end

--filter "Domain of the Furies"
function s.settfilter(c,code)
    return c:IsCode(2001003006) and c:IsSSetable()
end

--After Ritual Summon, set "Domain of the Furies"
function s.stage2(mat,e,tp,eg,ep,ev,re,r,rp,tc)
    if not tc or Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
    
    local g=Duel.GetMatchingGroup(s.settfilter,tp,LOCATION_DECK,0,nil,tc:GetCode())
    if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,0)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
        local sg=g:Select(tp,1,1,nil)
        if #sg>0 then
            Duel.SSet(tp,sg)
        end
    end
end

--Shuffle self to deck cost
function s.thcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return e:GetHandler():IsAbleToDeckAsCost() end
    Duel.SendtoDeck(e:GetHandler(),nil,2,REASON_COST)
end

--Target filter for field or banished Furies
function s.thfilter(c)
    return (c:IsCode(2001003001) or c:IsCode(2001003002) or c:IsCode(2001003003)) and c:IsMonster() and c:IsAbleToHand() and 
           (c:IsLocation(LOCATION_MZONE) or c:IsLocation(LOCATION_REMOVED))
end

--Target function for returning a Fury monster to hand
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_REMOVED) and chkc:IsControler(tp) and s.thfilter(chkc) end
    if chk==0 then return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_MZONE+LOCATION_REMOVED,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_MZONE+LOCATION_REMOVED,0,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

--Operation for returning Fury monster to hand
function s.thop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.SendtoHand(tc,nil,REASON_EFFECT)
    end
end