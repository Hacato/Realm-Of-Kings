--Lord Of The... RANDoM BULLSHIT GOOO!!!!!
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--4 Tuners with different names + 1 non-Tuner monster
	Synchro.AddProcedure(c,nil,4,4,Synchro.NonTunerEx(Card.IsType,TYPE_MONSTER),1,1,nil,nil,s.tuncheck)
	--When this card is Summoned: banish it face-down
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetTarget(s.rmtg)
	e1:SetOperation(s.rmop)
	c:RegisterEffect(e1)
end

--The 4 Tuners used for the Synchro Summon must all have different names
function s.tuncheck(g,sc,tp)
	return #g==4 and g:GetClassCount(Card.GetCode)==4
end

function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToRemove(tp,POS_FACEDOWN) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetHandler(),1,0,0)
end

function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.Remove(c,POS_FACEDOWN,REASON_EFFECT)
	end
end