--Illusory Servant of Tisiphone
local s,id=GetID()
function s.initial_effect(c)
    --Must be Special Summoned by its own effect
    c:EnableReviveLimit()
    
    --Negate equipped monster's effects and take control
    local e1=Effect.CreateEffect(c)
    e1:SetType(EFFECT_TYPE_EQUIP)
    e1:SetCode(EFFECT_DISABLE)
    c:RegisterEffect(e1)
    
    local e2=Effect.CreateEffect(c)
    e2:SetType(EFFECT_TYPE_EQUIP)
    e2:SetCode(EFFECT_SET_CONTROL)
    e2:SetValue(function(e,c) return e:GetHandlerPlayer() end)
    c:RegisterEffect(e2)
    
    --Special Summon when equipped to a monster and controlling Level 8 Ritual
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,0))
    e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_POSITION)
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_SZONE)
    e3:SetCountLimit(1,{id,1})
    e3:SetCondition(s.spcon)
    e3:SetTarget(s.sptg)
    e3:SetOperation(s.spop)
    c:RegisterEffect(e3)
    
    --If banished, banish a card from opponent's GY
    local e4=Effect.CreateEffect(c)
    e4:SetDescription(aux.Stringid(id,1))
    e4:SetCategory(CATEGORY_REMOVE)
    e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e4:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
    e4:SetCode(EVENT_REMOVE)
    e4:SetCountLimit(1,{id,2})
    e4:SetTarget(s.bantg)
    e4:SetOperation(s.banop)
    c:RegisterEffect(e4)
end

--Check if controlling a Level 8 Ritual Monster
function s.ritualfilter(c)
    return c:IsFaceup() and c:IsRitualMonster() and c:IsLevel(8)
end

--Condition for Special Summon
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
    return e:GetHandler():GetEquipTarget() and Duel.IsExistingMatchingCard(s.ritualfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Target for Special Summon
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 
        and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,true,true) end
    Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

--Operation for Special Summon and position change
function s.spop(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    if not c:IsRelateToEffect(e) then return end
    
    if Duel.SpecialSummon(c,0,tp,tp,true,true,POS_FACEUP)>0 then
        --Optional: Change battle position of 1 monster
        if Duel.IsExistingMatchingCard(Card.IsCanChangePosition,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) 
           and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
            
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
            local g=Duel.SelectMatchingCard(tp,Card.IsCanChangePosition,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil)
            if #g>0 then
                Duel.ChangePosition(g:GetFirst(),POS_FACEUP_DEFENSE,POS_FACEDOWN_DEFENSE,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)
            end
        end
    end
end

--Target for banish effect
function s.bantg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
    if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(1-tp) and chkc:IsAbleToRemove() end
    if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,nil) end
    
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
    local g=Duel.SelectTarget(tp,Card.IsAbleToRemove,tp,0,LOCATION_GRAVE,1,1,nil)
    Duel.SetOperationInfo(0,CATEGORY_REMOVE,g,1,0,0)
end

--Operation for banish effect
function s.banop(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstTarget()
    if tc and tc:IsRelateToEffect(e) then
        Duel.Remove(tc,POS_FACEUP,REASON_EFFECT)
    end
end