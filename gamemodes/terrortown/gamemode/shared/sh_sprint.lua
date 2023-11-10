local function PlayerSprint(trySprinting, moveKey)
	if SERVER then return end

	local client = LocalPlayer()

	if trySprinting and not GetGlobalBool("ttt2_sprint_enabled", true) then return end
	if not trySprinting and not client.isSprinting or trySprinting and client.isSprinting then return end
	if client.isSprinting and (client.moveKey and not moveKey or not client.moveKey and moveKey) then return end

	client.sprintMultiplier = trySprinting and (1 + GetGlobalFloat("ttt2_sprint_max", 0)) or nil
	client.isSprinting = trySprinting
	client.moveKey = moveKey

	net.Start("TTT2SprintToggle")
	net.WriteBool(trySprinting)
	net.SendToServer()
end

if SERVER then
	util.AddNetworkString("TTT2SprintToggle")

	-- Set ConVars

	---
	-- @realm server
	local sprintEnabled = CreateConVar("ttt2_sprint_enabled", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Toggle Sprint (Def: 1)")

	---
	-- @realm server
	local maxSprintMul = CreateConVar("ttt2_sprint_max", "0.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The maximum speed modifier the player will receive (Def: 0.5)")

	---
	-- @realm server
	local consumption = CreateConVar("ttt2_sprint_stamina_consumption", "0.6", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The speed of the stamina consumption (per second; Def: 0.6)")

	---
	-- @realm server
	local stamreg = CreateConVar("ttt2_sprint_stamina_regeneration", "0.3", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "The regeneration time of the stamina (per second; Def: 0.3)")

	---
	-- @realm server
	local showCrosshair = CreateConVar("ttt2_sprint_crosshair", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Should the Crosshair be visible while sprinting? (Def: 0)")

	hook.Add("TTT2SyncGlobals", "AddSprintGlobals", function()
		SetGlobalBool(sprintEnabled:GetName(), sprintEnabled:GetBool())
		SetGlobalFloat(maxSprintMul:GetName(), maxSprintMul:GetFloat())
		SetGlobalFloat(consumption:GetName(), consumption:GetFloat())
		SetGlobalFloat(stamreg:GetName(), stamreg:GetFloat())
		SetGlobalBool(showCrosshair:GetName(), showCrosshair:GetBool())
	end)

	cvars.AddChangeCallback(sprintEnabled:GetName(), function(name, old, new)
		SetGlobalBool(name, tobool(new))
	end, "TTT2SprintENChange")

	cvars.AddChangeCallback(maxSprintMul:GetName(), function(name, old, new)
		SetGlobalFloat(name, new)
	end, "TTT2SprintSMulChange")

	cvars.AddChangeCallback(consumption:GetName(), function(name, old, new)
		SetGlobalFloat(name, new)
	end, "TTT2SprintSCChange")

	cvars.AddChangeCallback(stamreg:GetName(), function(name, old, new)
		SetGlobalFloat(name, new)
	end, "TTT2SprintSRChange")

	cvars.AddChangeCallback(showCrosshair:GetName(), function(name, old, new)
		SetGlobalBool(name, tobool(new))
	end, "TTT2SprintCHChange")

	net.Receive("TTT2SprintToggle", function(_, ply)
		if not sprintEnabled:GetBool() or not IsValid(ply) then return end

		local bool = net.ReadBool()

		ply.sprintMultiplier = bool and (1 + maxSprintMul:GetFloat()) or nil
		ply.isSprinting = bool
	end)
else 
	bind.Register("ttt2_sprint", function()
		if not LocalPlayer().preventSprint then
			PlayerSprint(true)
		end
	end,
	function()
		PlayerSprint(false)
	end, "header_bindings_ttt2", "label_bind_sprint", KEY_LSHIFT)
end

---
-- @realm shared
function UpdateSprint()
	local client

	if CLIENT then
		client = LocalPlayer()

		if not IsValid(client) then return end
	end

	local plys = client and {client} or player.GetAll()

	for i = 1, #plys do
		local ply = plys[i]

		if not ply:OnGround() then continue end

		local wantsToMove = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVERIGHT) or ply:KeyDown(IN_MOVELEFT)
		local stamina = ply:GetStamina()

		if stamina == 1 and (not stamina or not wantsToMove) then continue end
		if stamina == 0 and stamina and wantsToMove then
			ply.sprintResetDelayCounter = ply.sprintResetDelayCounter + FrameTime()

			-- If the player keeps sprinting even though they have no stamina, start refreshing stamina after 1.5 seconds automatically
			if CLIENT and ply.sprintResetDelayCounter > 1.5 then
				PlayerSprint(false, ply.moveKey)
			end

			continue
		end

		ply.sprintResetDelayCounter = 0

		if CLIENT then return end

		local modifier = {1} -- Multiple hooking support
		local newStamina = 0

		if not ply.isSprinting or not wantsToMove then
			---
			-- @realm shared
			hook.Run("TTT2StaminaRegen", ply, modifier)

			newStamina = math.Clamp(stamina + FrameTime() * modifier[1] * GetGlobalFloat("ttt2_sprint_stamina_regeneration"), 0, math.max(0, math.min(ply:Health() / 100, 1.0 - ply:GetNWInt("EffectAMT"))))
		elseif wantsToMove then
			---
			-- @realm shared
			hook.Run("TTT2StaminaDrain", ply, modifier)

			newStamina = math.max(stamina - FrameTime() * modifier[1] * GetGlobalFloat("ttt2_sprint_stamina_consumption"), 0)
		end

		ply:SetStamina(newStamina)

	end
end

---
-- A hook that is called once every frame/tick to modify the stamina regeneration.
-- @note This hook is predicted and should be therefore run on both server and client.
-- @param Player ply The player whose modifier should be set
-- @param table modifierTbl The table in which the modifier can be changed
-- @hook
-- @realm shared
function GM:TTT2StaminaRegen(ply, modifierTbl)

end

---
-- A hook that is called once every frame/tick to modify the stamina drain.
-- @note This hook is predicted and should be therefore run on both server and client.
-- @param Player ply The player whose modifier should be set
-- @param table modifierTbl The table in which the modifier can be changed
-- @hook
-- @realm shared
function GM:TTT2StaminaDrain(ply, modifierTbl)

end

local CMoveData = FindMetaTable("CMoveData")

function CMoveData:RemoveKeys(keys)
    local newbuttons = bit.band(self:GetButtons(), bit.bnot(keys))
    self:SetButtons(newbuttons)
end

hook.Add("SetupMove", "Nerf Jump", function(ply, mv)
    if ply:OnGround() and mv:KeyPressed(IN_JUMP) then

		local stamina = ply:GetStamina()

		if stamina < 0.25 then
			mv:RemoveKeys(IN_JUMP)
			return
		end

        ply:SetJumpPower(math.max(120, 160 * stamina))

		if SERVER then
			ply:SetStamina(math.max(stamina - 0.2, 0))
		end
	end
end)