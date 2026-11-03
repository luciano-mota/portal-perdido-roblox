--!strict
-- Poses originais locais: apresentação apenas, sem mover a raiz ou conceder dano.
local Motion={}

function Motion.pose(name: string, phase: number, stride: number, airborne: boolean, classId: string, attack: number?, time: number): CFrame
	local left=name:find("left")~=nil
	local side=if left then -1 else 1
	local swing=math.sin(phase)*stride
	local lift=math.max(0,math.sin(phase+side*math.pi/2))*stride
	local x,y,z=0,0,0
	local offset=Vector3.zero
	if name:find("shoulder") then
		x=-swing*side*0.6-0.06 z=side*0.06
		if airborne then x=0.6 z=side*0.2 end
	elseif name:find("hip") then
		x=swing*side*0.68 y=side*0.025*stride
		if airborne then x=if left then -0.38 else 0.22 end
	elseif name:find("knee") then x=-lift*0.95-(if airborne then 0.55 else 0.05)
	elseif name:find("ankle") then x=lift*0.35
	elseif name:find("elbow") then x=0.18+math.abs(swing)*0.18
	elseif name=="waist" then y=-swing*0.08 x=-stride*0.05
	elseif name=="root" or name=="rootjoint" then
		offset=Vector3.new(0,math.cos(phase*2)*stride*0.045+math.sin(time*2)*0.012,0)
		z=math.sin(phase)*stride*0.025
	elseif name=="neck" then y=swing*0.025 end
	if attack then
		local t=math.clamp(attack,0,1)
		local wind=math.sin(math.min(t/0.32,1)*math.pi/2)
		local release=math.clamp((t-0.32)/0.45,0,1)
		local recover=1-math.clamp((t-0.77)/0.23,0,1)
		if classId=="Guardian" then
			if name=="rightshoulder" then x=(1.7*wind-2.4*release)*recover y=-0.45*recover z=0.35*recover
			elseif name=="rightelbow" then x=0.55*(1-release)*recover
			elseif name=="leftshoulder" then x=0.65*recover z=-0.25*recover
			elseif name=="waist" then y=(0.4*wind-0.8*release)*recover end
		elseif classId=="Explorer" then
			if name=="leftshoulder" then x=1.45*recover y=0 z=0.5*recover
			elseif name=="rightshoulder" then x=1.1*recover y=0.7*wind*recover z=0.45*recover
			elseif name=="rightelbow" then x=1.65*wind*(1-release*0.6)*recover
			elseif name=="leftelbow" then x=0.04*recover
			elseif name=="leftwrist" then z=-0.5*recover
			elseif name=="waist" then y=0 end
		else
			if name=="rightshoulder" then x=(0.8*wind+0.65*release)*recover z=0.2*recover
			elseif name=="rightelbow" then x=0.9*(1-release)*recover
			elseif name=="leftshoulder" then x=0.65*recover z=-0.4*recover
			elseif name=="waist" then x=-0.08*recover y=0.16*recover end
		end
	end
	return CFrame.new(offset)*CFrame.Angles(x,y,z)
end

return Motion
