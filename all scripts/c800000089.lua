--YuYuYu Yuuki Yuuna, Mankai
local s,id=GetID()
function s.initial_effect(c)
    --Link Summon
    c:EnableReviveLimit()
    Link.AddProcedure(c,s.matfilter,2,99,s.matcheck)
    
    --Allow using Fairy "YuYuYu" cards in S/T zone as Link Material (max 3)
    local e0=Effect.CreateEffect(c)
    e0:SetType(EFFECT_TYPE_FIELD)
    e0:SetCode(EFFECT_EXTRA_MATERIAL)
    e0:SetProperty(EFFECT_FLAG_PLAYER_TARGET|EFFECT_FLAG_CANNOT_DISABLE|EFFECT_FLAG_SET_AVAILABLE)
    e0:SetRange(LOCATION_EXTRA)
    e0:SetTargetRange(1,0)
    e0:SetOperation(aux.TRUE)
    e0:SetValue(s.extraval)
    c:RegisterEffect(e0)
    
    --Trigger on Ritual Monster Special Summon
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
    e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
    e1:SetCode(EVENT_SPSUMMON_SUCCESS)
    e1:SetProperty(EFFECT_FLAG_DELAY)
    e1:SetRange(LOCATION_MZONE)
    e1:SetCountLimit(1,id)
    e1:SetCondition(s.drcon)
    e1:SetTarget(s.drtg)
    e1:SetOperation(s.drop)
    c:RegisterEffect(e1)
    
    --Inflict damage when this card destroys a monster by battle
    local e2=Effect.CreateEffect(c)
    e2:SetDescription(aux.Stringid(id,1))
    e2:SetCategory(CATEGORY_DAMAGE)
    e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
    e2:SetCode(EVENT_BATTLE_DESTROYING)
    e2:SetCondition(aux.bdcon)
    e2:SetTarget(s.damtg)
    e2:SetOperation(s.damop)
    c:RegisterEffect(e2)
    
    --Add Pendulum and Ritual Spell when destroyed/leaves field
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TOHAND)
    e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
    e3:SetProperty(EFFECT_FLAG_DELAY)
    e3:SetCode(EVENT_BATTLE_DESTROYED)
    e3:SetCondition(s.thcon1)
    e3:SetTarget(s.thtg)
    e3:SetOperation(s.thop)
    c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EVENT_LEAVE_FIELD)
    e4:SetCondition(s.thcon2)
    c:RegisterEffect(e4)
end

s.listed_series={0x991}

--Link Material filters
function s.matfilter(c,lc,sumtype,tp)
    return c:IsSetCard(0x991,lc,sumtype,tp)
end

function s.matcheck(g,lc,sumtype,tp)
    return g:IsExists(Card.IsType,1,nil,TYPE_RITUAL+TYPE_PENDULUM,lc,sumtype,tp)
end

--Extra Material for S/T zone
function s.exmfilter(c,tp)
    return c:IsFaceup() and c:IsSetCard(0x991) and c:IsRace(RACE_FAIRY) 
        and c:IsOriginalType(TYPE_MONSTER) and c:GetSequence()<5
end

function s.extraval(chk,summon_type,e,...)
    if chk==0 then
        local tp,sc=...
        if summon_type~=SUMMON_TYPE_LINK or not (sc and sc:GetCode()==id) then
            return Group.CreateGroup()
        else
            return Duel.GetMatchingGroup(s.exmfilter,tp,LOCATION_SZONE,0,nil,tp)
        end
    end
end

--Shuffle and draw effect
function s.drfilter(c,tp,lg)
    return c:IsFaceup() and c:IsSetCard(0x991) and c:IsType(TYPE_RITUAL) 
        and c:IsSummonType(SUMMON_TYPE_SPECIAL) and lg:IsContains(c)
end

function s.drcon(e,tp,eg,ep,ev,re,r,rp)
    local lg=e:GetHandler():GetLinkedGroup()
    return eg:IsExists(s.drfilter,1,nil,tp,lg)
end

function s.tdfilter(c)
    return c:IsSetCard(0x991) and c:IsRace(RACE_FAIRY) and c:IsMonster() and c:IsAbleToDeck()
end

function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsPlayerCanDraw(tp,1)
        and Duel.IsExistingMatchingCard(s.tdfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_GRAVE)
    Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.drop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
    local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    if #g>0 and Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)>0 
        and g:GetFirst():IsLocation(LOCATION_DECK) then
        Duel.ShuffleDeck(tp)
        Duel.BreakEffect()
        Duel.Draw(tp,1,REASON_EFFECT)
    end
end

--Battle damage effect
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    local bc=e:GetHandler():GetBattleTarget()
    local dam=bc:GetAttack()
    if dam<0 then dam=0 end
    Duel.SetTargetPlayer(1-tp)
    Duel.SetTargetParam(dam)
    Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,dam)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
    local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
    Duel.Damage(p,d,REASON_EFFECT)
end

--Add to hand effects
function s.thcon1(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
end

function s.thcon2(e,tp,eg,ep,ev,re,r,rp)
    local c=e:GetHandler()
    return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_MZONE)
        and c:GetReasonPlayer()==1-tp and c:IsReason(REASON_EFFECT)
end

function s.penfilter(c)
    return c:IsSetCard(0x991) and c:IsType(TYPE_PENDULUM) and c:IsFaceup() and c:IsAbleToHand()
end

function s.ritfilter(c)
    return c:IsSetCard(0x991) and c:IsType(TYPE_RITUAL) and c:IsSpell() and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.penfilter,tp,LOCATION_EXTRA,0,1,nil)
        and Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_GRAVE,0,1,nil) end
    Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g1=Duel.SelectMatchingCard(tp,s.penfilter,tp,LOCATION_EXTRA,0,1,1,nil)
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
    local g2=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_GRAVE,0,1,1,nil)
    g1:Merge(g2)
    if #g1>0 then
        Duel.SendtoHand(g1,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,g1)
    end
end