--Aquamarine Moon Aurelia
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon itself from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id) -- once per turn this way
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	--On Special Summon: search 1 "Aquamarine" Spell/Trap
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
	--If banished from GY: Fusion Summon
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_REMOVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.fuscon)
	e3:SetTarget(s.fustg)
	e3:SetOperation(s.fusop)
	c:RegisterEffect(e3)
end
s.listed_series={0x30cd}

--Special Summon condition
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x30cd)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

--Search effect
function s.thfilter(c)
	return c:IsSetCard(0x30cd) and c:IsSpellTrap() and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--Fusion Summon when banished from GY
function s.fuscon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_GRAVE)
end

-- materials must be monsters you can banish from your FIELD and/or GY
local function matfilter(c,fc)
	return c:IsMonster() and c:IsCanBeFusionMaterial(fc) and c:IsAbleToRemove()
end

-- Only allow picking Fusion monsters that are actually summonable with our pool
local function can_summon_with_pool(fc,tp,mg)
	if not (fc:IsSetCard(0x30cd) and fc:IsType(TYPE_FUSION)) then return false end
	if not fc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) then return false end
	if Duel.GetLocationCountFromEx(tp,tp,nil,fc)<=0 then return false end
	local chkf = Duel.GetLocationCountFromEx(tp,tp,nil,fc)>0 and PLAYER_NONE or tp
	local mg_fc = mg:Filter(matfilter,nil,fc)
	return fc:CheckFusionMaterial(mg_fc,chkf)
end

function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		-- build the allowed material pool (field + GY, banish)
		local mg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
		-- gather only Aquamarine Fusions that are actually fuseable with that pool
		local sg=Duel.GetMatchingGroup(function(c)
			if not (c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION)) then return false end
			if Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then return false end
			-- build a per-candidate filtered pool and test it
			local mgc=mg:Filter(matfilter,nil,c)
			local chkf = Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and PLAYER_NONE or tp
			return c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
				and c:CheckFusionMaterial(mgc,chkf)
		end,tp,LOCATION_EXTRA,0,nil)
		return #sg>0
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	-- build material pool again (field + GY only)
	local pool=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	-- build list of actually summonable Aquamarine Fusions
	local candidates=Duel.GetMatchingGroup(function(c)
		if not (c:IsSetCard(0x30cd) and c:IsType(TYPE_FUSION)) then return false end
		if Duel.GetLocationCountFromEx(tp,tp,nil,c)<=0 then return false end
		if not c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) then return false end
		local mg=pool:Filter(matfilter,nil,c)
		local chkf = Duel.GetLocationCountFromEx(tp,tp,nil,c)>0 and PLAYER_NONE or tp
		return c:CheckFusionMaterial(mg,chkf)
	end,tp,LOCATION_EXTRA,0,nil)
	if #candidates==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local fc=candidates:Select(tp,1,1,nil):GetFirst()
	if not fc then return end

	-- prepare the legal material pool for the chosen Fusion
	local mg=pool:Filter(matfilter,nil,fc)
	local chkf = Duel.GetLocationCountFromEx(tp,tp,nil,fc)>0 and PLAYER_NONE or tp
	local mat=Duel.SelectFusionMaterial(tp,fc,mg,chkf)
	if not mat or #mat==0 then return end

	fc:SetMaterial(mat)
	Duel.Remove(mat,POS_FACEUP,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	if Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)>0 then
		fc:CompleteProcedure()
	end
end
