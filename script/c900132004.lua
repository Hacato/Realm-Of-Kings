--scripted by AsahiRei
local s,id=GetID()
function s.initial_effect(c)
    --pendulum summon
    Pendulum.AddProcedure(c)
    --search & gain LP
    c:RegisterEffect(YuYuYu.DestroyPendulumEffect(c,aux.Stringid(id,0),{category=CATEGORY_DRAW,hopt=id,target=s.drtg,effect=s.drop,setoperationinfo=s.opinfo}))
    c:RegisterEffect(YuYuYu.DestroyEffect(c,aux.Stringid(id,1),{category=CATEGORY_DRAW,hopt=id,target=s.drtg2,operation=s.drop2}))
	--gains atk
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetCondition(s.condtion)
	e1:SetValue(1000)
	e1:SetCountLimit(1,{id,1})
	c:RegisterEffect(e1)
end
s.listed_series={SETCARD_YUYUYU}
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
end
function s.opinfo(e,tp,eg,ep,ev,re,r,rp)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.Draw(tp,1,REASON_EFFECT)~=0 then
		Duel.DiscardHand(tp,aux.TRUE,1,1,REASON_EFFECT+REASON_DISCARD)
	end
end
function s.drtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,1) end
end
function s.drop2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Draw(tp,1,REASON_EFFECT)
end
function s.condtion(e)
	local ph=Duel.GetCurrentPhase()
	return (ph==PHASE_DAMAGE or ph==PHASE_DAMAGE_CAL)
end
Duel.LoadScript("yuyuyu-utility.lua")