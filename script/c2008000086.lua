--Guidance of the Voiceless Voice
--Scripted by Mardras
local s,id=GetID()
function s.initial_effect(c)
    --search
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
    e1:SetCategory(CATEGORY_TOGRAVE+CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_TODECK)
    e1:SetType(EFFECT_TYPE_ACTIVATE)
    e1:SetCode(EVENT_FREE_CHAIN)
    e1:SetCountLimit(1,{id,0},EFFECT_COUNT_CODE_DUEL)
    e1:SetCost(s.actcost)
    e1:SetTarget(s.acttg)
    e1:SetOperation(s.actop)
    c:RegisterEffect(e1)
    --Ritual Summon 1 LIGHT Ritual (Warrior/Dragon) monster
    local e2=Ritual.CreateProc({handler=c,lvtype=RITPROC_GREATER,filter=s.ritfilter,desc=aux.Stringid(id,1),stage2=s.stage2})
    e2:SetType(EFFECT_TYPE_QUICK_O)
    e2:SetCode(EVENT_FREE_CHAIN)
    e2:SetRange(LOCATION_FZONE)
    e2:SetCountLimit(1,{id,1},EFFECT_COUNT_CODE_DUEL)
    c:RegisterEffect(e2)
    --rm this c to take no bdmg this turn + shuffle 1 Rit S to Spsumm "Lo"
    local e3=Effect.CreateEffect(c)
    e3:SetDescription(aux.Stringid(id,2))
    e3:SetCategory(CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)--
    e3:SetType(EFFECT_TYPE_QUICK_O)
    e3:SetCode(EVENT_FREE_CHAIN)
    e3:SetRange(LOCATION_FZONE+LOCATION_GRAVE)
    e3:SetCountLimit(1,{id,2},EFFECT_COUNT_CODE_DUEL)
    e3:SetCost(aux.bfgcost)
    e3:SetTarget(s.target)
    e3:SetOperation(s.operation)
    c:RegisterEffect(e3)
end
s.listed_names={25801745,id}
s.listed_series={SET_VOICELESS_VOICE}
function s.tgfilter(c)--Tribute 1 non-Ritual "Voiceless Voice" m from your h/D to search up to 3 "VV" Ritual Ms w diff names
    return c:IsSetCard(SET_VOICELESS_VOICE) and c:IsMonster() and not c:IsType(TYPE_RITUAL)
end
function s.actcost(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil) end
    Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
    local tc=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil):GetFirst()
    if tc then
        Duel.SendtoGrave(tc,REASON_COST|REASON_RELEASE)
    end
end
function s.thfilter(c)
    return c:IsSetCard(SET_VOICELESS_VOICE) and c:IsType(TYPE_RITUAL) and c:IsMonster() and c:IsAbleToHand()
end
function s.acttg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
	if chk==0 then return aux.SelectUnselectGroup(g,e,tp,1,3,aux.dncheck,0) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_DECK)
	Duel.SetChainLimit(aux.FALSE)
end
function s.actop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil)
    if #g>0 then
        local sg=aux.SelectUnselectGroup(g,e,tp,1,3,aux.dncheck,1,tp,HINTMSG_ATOHAND)
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
        if Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>=4 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
            local dg=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_HAND,0,1,1,nil)
            if #dg>0 then
                Duel.SendtoDeck(dg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
            end
        end
    end
end
function s.ritfilter(c)--Ritual Summon 1 LIGHT Ritual (Warrior or Dragon) Monster
	return c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_WARRIOR|RACE_DRAGON)
end
function s.stage2(mat,e,tp,eg,ep,ev,re,r,rp,tc)
	--Cannot be destroyed by card effects
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(3001)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD)
	tc:RegisterEffect(e1)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)--rm this c to take no bdmg this turn
    if chk==0 then return true end
    Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE|LOCATION_REMOVED)
end
function s.rsfilter(c)
    return c:IsType(TYPE_RITUAL) and c:IsSpell() and c:IsAbleToDeck()
end
function s.lofilter(c,e,tp)
    return c:IsCode(25801745) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
    --avoid bdmg this turn
    local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_AVOID_BATTLE_DAMAGE)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetTargetRange(1,0)
	e1:SetValue(1)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
    --Shuffle 1 Ritual S from your h/GY/rm to Spsumm "Lo" from your GY/rm
    if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.rsfilter,tp,LOCATION_HAND|LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil) 
       and Duel.IsExistingMatchingCard(s.lofilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,nil,e,tp)
       and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
       Duel.BreakEffect()
       Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
       local sc=Duel.SelectMatchingCard(tp,s.rsfilter,tp,LOCATION_HAND|LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil):GetFirst()
       if sc and Duel.SendtoDeck(sc,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)~=0 then
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
            local tc=Duel.SelectMatchingCard(tp,s.lofilter,tp,LOCATION_GRAVE|LOCATION_REMOVED,0,1,1,nil,e,tp):GetFirst()
            if tc then
                Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
            end
        end
    end
end