if SERVER then
	AddCSLuaFile()
else
	LANG.AddToLanguage("english", "awp_name", "AWP")
	LANG.AddToLanguage("english", "awp_desc", "AWP Sniper Rifle.\n\nOnly has five shots.")

	SWEP.PrintName = "awp_name"
	SWEP.Slot = 6
	SWEP.Icon = "vgui/ttt/icon_awp"

	-- client side model settings
	SWEP.UseHands = true -- should the hands be displayed
	SWEP.ViewModelFlip = false -- should the weapon be hold with the left or the right hand
	SWEP.ViewModelFOV = 64

	-- equipment menu information is only needed on the client
	SWEP.EquipMenuData = {
		type = "item_weapon",
		desc = "awp_desc"
	}
end

-- always derive from weapon_tttbase
SWEP.Base = "weapon_tttbase"

--[[Default GMod values]]--
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 1.3
SWEP.Primary.Recoil = 10
SWEP.Primary.Cone = 0.001
SWEP.Primary.Damage = 125
SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = 5
SWEP.Primary.DefaultClip = 5
SWEP.Primary.Sound = Sound("Weapon_AWP.Single")

SWEP.Secondary.Delay = 0.2
SWEP.Secondary.Sound = Sound("Default.Zoom")

SWEP.HeadshotMultiplier = 6

--[[Model settings]]--
SWEP.HoldType = "ar2"
SWEP.ViewModel = Model("models/weapons/cstrike/c_snip_awp.mdl")
SWEP.WorldModel = Model("models/weapons/w_snip_awp.mdl")

SWEP.IronSightsPos = Vector(5, -15, -2)
SWEP.IronSightsAng = Vector(2.6, 1.37, 3.5)

SWEP.StaminaLoss = 0.15
SWEP.StaminaCone = 50

--[[TTT config values]]--

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EQUIP1

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2,
-- then this gun can be spawned as a random weapon.
SWEP.AutoSpawnable = false

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_TRAITOR }

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = true

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
SWEP.IsSilent = false

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = false

-- add some zoom to the scope for this gun
function SWEP:SecondaryAttack()
	if (self.IronSightsPos and self:GetNextSecondaryFire() <= CurTime()) then
		-- set the delay for left and right click
		self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
		self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

		local bIronsights = not self:GetIronsights()
		self:SetIronsights(bIronsights)
		if SERVER then
			self:SetZoom(bIronsights)
		else
			self:EmitSound(self.Secondary.Sound)
		end
	end
end

function SWEP:SetZoom(state)
	if (SERVER and IsValid(self:GetOwner()) and self:GetOwner():IsPlayer()) then
		if (state) then
			self:GetOwner():SetFOV(20, 0.3)
		else
			self:GetOwner():SetFOV(0, 0.2)
		end
	end
end

function SWEP:ResetIronSights()
	self:SetIronsights(false)
	self:SetZoom(false)
end

function SWEP:PreDrop()
	self:ResetIronSights()
	return self.BaseClass.PreDrop(self)
end

function SWEP:Reload()
	if (self:Clip1() < self.Primary.ClipSize and self:GetOwner():GetAmmoCount(self.Primary.Ammo) > 0) then
		self:DefaultReload(ACT_VM_RELOAD)
		self:ResetIronSights()
	end
end

function SWEP:Holster()
	self:ResetIronSights()
	return true
end

-- draw the scope on the HUD
if CLIENT then
	local scope = surface.GetTextureID("sprites/scope")
	function SWEP:DrawHUD()
		if self:GetIronsights() then
			surface.SetDrawColor(0, 0, 0, 255)

			local x = ScrW() / 2.0
			local y = ScrH() / 2.0
			local scope_size = ScrH()

			-- crosshair
			local gap = 80
			local length = scope_size
			surface.DrawLine(x - length, y, x - gap, y)
			surface.DrawLine(x + length, y, x + gap, y)
			surface.DrawLine(x, y - length, x, y - gap)
			surface.DrawLine(x, y + length, x, y + gap)

			gap = 0
			length = 50
			surface.DrawLine(x - length, y, x - gap, y)
			surface.DrawLine(x + length, y, x + gap, y)
			surface.DrawLine(x, y - length, x, y - gap)
			surface.DrawLine(x, y + length, x, y + gap)

			-- cover edges
			local sh = scope_size / 2
			local w = (x - sh) + 2
			surface.DrawRect(0, 0, w, scope_size)
			surface.DrawRect(x + sh - 2, 0, w, scope_size)
			surface.SetDrawColor(255, 0, 0, 255)
			surface.DrawLine(x, y, x + 1, y + 1)

			-- scope
			surface.SetTexture(scope)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRectRotated(x, y, scope_size, scope_size, 0)
		else
			return self.BaseClass.DrawHUD(self)
		end
	end

	function SWEP:AdjustMouseSensitivity()
		return (self:GetIronsights() and 0.2) or nil
	end
end
