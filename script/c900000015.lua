--Slayer-Demigod Of Divinity
local s,id=GetID()
function s.initial_effect(c)
	--Synchro Summon
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,s.tfilter,1,1,Synchro.NonTuner(nil),1,99)
	
	--Always treated as every attribute
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_ADD_ATTRIBUTE)
	e0:SetRange(LOCATION_MZONE+LOCATION_EXTRA)
	e0:SetValue(ATTRIBUTE_ALL)
	c:RegisterEffect(e0)
	
	--Multiple effects when summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_TODECK+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.sumcon)
	e1:SetTarget(s.sumtg)
	e1:SetOperation(s.sumop)
	c:RegisterEffect(e1)
	
	--Draw when opponent activates card/effect
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.drcon)
	e2:SetTarget(s.drtg)
	e2:SetOperation(s.drop)
	c:RegisterEffect(e2)
	
	--Fusion summon after battle destruction
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_BATTLE_DESTROYING)
	e3:SetCondition(s.fuscon)
	e3:SetTarget(s.fustg)
	e3:SetOperation(s.fusop)
	c:RegisterEffect(e3)
end

--Tuner filter
function s.tfilter(c,lc,stype,tp)
	return c:IsSetCard(0x2407,lc,stype,tp) and c:IsType(TYPE_TUNER,lc,stype,tp)
end

--Summon condition (Synchro Summoned)
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

--Summon target
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local g1=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_GRAVE,0,nil)
	local g2=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_REMOVED,0,nil)
	local g3=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK+LOCATION_HAND,0,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g1,2,0,0)
	if #g2>0 then
		Duel.SetOperationInfo(0,CATEGORY_TODECK,g2,#g2,0,0)
	end
	if #g3>0 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK+LOCATION_HAND)
	end
end

--Special summon filter for opponent's field
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x2407) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE,1-tp)
end

--Summon operation
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
	--Add 2 cards from GY to hand
	local g1=Duel.GetMatchingGroup(aux.NecroValleyFilter(aux.TRUE),tp,LOCATION_GRAVE,0,nil)
	if #g1>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local sg1=g1:Select(tp,2,2,nil)
		if #sg1>0 then
			Duel.SendtoHand(sg1,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,sg1)
		end
	elseif #g1>0 then
		Duel.SendtoHand(g1,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g1)
	end
	
	--Shuffle banished cards back to deck
	local g2=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_REMOVED,0,nil)
	if #g2>0 then
		Duel.SendtoDeck(g2,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
	
	--Special summon Slayer to opponent's field
	if Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 then
		local g3=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_DECK+LOCATION_HAND,0,nil,e,tp)
		if #g3>0 then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg3=g3:Select(tp,1,1,nil)
			if #sg3>0 then
				Duel.SpecialSummon(sg3,0,tp,1-tp,false,false,POS_FACEUP_DEFENSE)
				if sg3:GetFirst():IsLocation(LOCATION_DECK) then
					Duel.ShuffleDeck(tp)
				end
			end
		end
	end
end

--Draw condition
function s.drcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
end

--Draw target
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

--Draw operation
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end

--Fusion condition
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return c:IsRelateToBattle() and bc:IsLocation(LOCATION_GRAVE) and bc:IsType(TYPE_MONSTER)
end

--Fusion filter
function s.fusfilter(c,e,tp)
	return c:IsType(TYPE_FUSION) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
		and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE,0,1,nil,c,e:GetHandler())
end

--Material filter (must include this card) - FIXED
function s.matfilter(c,fc,thiscard)
	return c:IsCanBeFusionMaterial(fc) and (c==thiscard or c:IsType(TYPE_MONSTER))
end

--Fusion target
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>-1
		and Duel.IsExistingMatchingCard(s.fusfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

--Fusion operation
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<0 then return end
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tc=Duel.SelectMatchingCard(tp,s.fusfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp):GetFirst()
	if not tc then return end
	
	--Use proper fusion material selection
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_ONFIELD+LOCATION_HAND+LOCATION_GRAVE,0,nil,tc,c)
	mg:AddCard(c) --Ensure this card is included
	
	--Let the game determine proper fusion materials
	local mat=Duel.SelectFusionMaterial(tp,tc,mg,c)
	if not mat or #mat==0 then return end
	
	tc:SetMaterial(mat)
	local grave_mat=mat:Filter(Card.IsLocation,nil,LOCATION_GRAVE)
	local field_mat=mat:Filter(Card.IsLocation,nil,LOCATION_ONFIELD)
	local hand_mat=mat:Filter(Card.IsLocation,nil,LOCATION_HAND)
	
	if #grave_mat>0 then
		Duel.Remove(grave_mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	end
	if #field_mat>0 then
		Duel.SendtoGrave(field_mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	end
	if #hand_mat>0 then
		Duel.SendtoGrave(hand_mat,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	end
	
	Duel.BreakEffect()
	Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	tc:CompleteProcedure()
end