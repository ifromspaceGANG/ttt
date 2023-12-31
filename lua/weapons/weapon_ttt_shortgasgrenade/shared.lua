if ( SERVER ) then
AddCSLuaFile( "shared.lua" )
resource.AddFile("materials/VGUI/ttt/icon_gas_grenade.vmt")
end

if ( CLIENT ) then
SWEP.PrintName          = "Gas Grenade"          
SWEP.Slot               = 3
SWEP.SlotPos            = 0

   SWEP.EquipMenuData = {
      type = "Grenade",
      desc = "Does damage over time in an area.\nWill not kill the victims, instead brings them to 1 hp.\nDamages All Players!"
};
end
SWEP.Icon = "VGUI/ttt/icon_gas_grenade"
SWEP.Base				= "weapon_tttbasegrenade"
SWEP.Kind               = WEAPON_NADE
SWEP.HoldType           = "grenade"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel			= "models/weapons/v_eq_smokegrenade.mdl"
SWEP.WorldModel			= "models/weapons/w_eq_smokegrenade.mdl"

SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "GASAMMO"
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.LimitedStock = true
SWEP.AllowDrop = false

SWEP.Primary.Sound			= Sound("Default.PullPin_Grenade")
SWEP.Primary.Recoil			= 0
SWEP.Primary.Unrecoil		= 0
SWEP.Primary.Damage			= 0
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0
SWEP.Primary.Delay			= 1
SWEP.Primary.Ammo			= "SLAM"
SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= 1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Next = CurTime()
SWEP.Primed = 0

function SWEP:Reload()
	return false
end

function SWEP:Deploy()
	return true
end

function SWEP:Holster()
	self.Next = CurTime()
	self.Primed = 0
	return true
end

function SWEP:ShootEffects()
	self.Weapon:SendWeaponAnim( ACT_VM_THROW ) 		// View model animation
	//self.Owner:MuzzleFlash()								// Crappy muzzle light
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
end


function SWEP:PrimaryAttack()
	if self.Next < CurTime() and self.Primed == 0 and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
		self.Next = CurTime() + self.Primary.Delay
		
		self.Weapon:SendWeaponAnim(ACT_VM_PULLPIN)
		self.Primed = 1
		//self.Weapon:EmitSound(self.Primary.Sound)
	end
	 

end

function SWEP:Think()
	if self.Next < CurTime() then
		if self.Primed == 1 and not self.Owner:KeyDown(IN_ATTACK) then
			self.Weapon:SendWeaponAnim(ACT_VM_THROW)
			self.Primed = 2
			self.Next = CurTime() + .3
		elseif self.Primed == 2 then
			self.Primed = 0
			self.Next = CurTime() + self.Primary.Delay
			
			if SERVER then
				local ent = ents.Create("cse_ent_shortgasgrenade")
				ent:SetOwner(self.Owner)
				ent.Owner = self.Owner
				ent:SetPos(self.Owner:GetShootPos())
				ent:SetAngles(Angle(1,0,0))
				if (self.Weapon:GetNWBool("upgraded") && SERVER) then
					ent:Upgrade()
					ent:SetNWBool("upgraded", true)
				end
				ent:Spawn()
				
				local phys = ent:GetPhysicsObject()
				phys:SetVelocity(self.Owner:GetAimVector() * 750)
				phys:AddAngleVelocity(Vector(math.random(-100,100),math.random(-100,100),math.random(-100,100)))
				
				self.Owner:RemoveAmmo(1,self.Primary.Ammo)
				
				if self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
					self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
					else 
					            timer.Simple(1, function() self.Owner:StripWeapon(self:GetClass()) end) -- Delay so anim is displayed, tends to look better
				end
			end
		end
	end
end

function SWEP:GetGrenadeName()
   return "ttt_smokegrenade_proj"
end

function SWEP:ShouldDropOnDie()
	return true
end