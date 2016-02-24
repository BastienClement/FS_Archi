local Archimonde = LibStub("AceAddon-3.0"):NewAddon("FSArchimonde", "AceEvent-3.0", "AceConsole-3.0")

local SYMBOLES = { 6, 7, 4, 5 }
local SYMBOLES_NAME = { "CARRE (2)", "CROIX (3)", "TRIANGLE (1)", "LUNE (4)" }
local SYMBOLES_ICON = {
	"ability_fixated_state_blue",
	"ability_fixated_state_red",
	"ability_fixated_state_green",
	"talentspec_druid_balance"
}

-------------------------------------
-- TRIANGLE | CARRE | CROIX | LUNE --
-------------------------------------

function Archimonde:OnInitialize()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ENCOUNTER_START")
end

local pending = false
local affected = {}

function Archimonde:COMBAT_LOG_EVENT_UNFILTERED(_, _, event, ...)
	if event == "SPELL_AURA_APPLIED" then
		local target, _, _, spell = select(7, ...)
		if spell == 187050 then
			table.insert(affected, target)
			if not pending then
				pending = true
				C_Timer.After(0.2, function()
					pending = false
					
					local soakers = {}
					
					for _, unit in FS:IterateGroup() do
						if UnitGroupRolesAssigned(unit) ~= "TANK" then
							if UnitDebuff(unit, GetSpellInfo(spell)) then
								--table.insert(affected, unit)
							elseif not UnitIsDeadOrGhost(unit) then
								table.insert(soakers, unit)
							end
						end
					end
					
					for i, target in ipairs(affected) do
						local soak_a, soak_b, soak_c
						if i < 3 then
							soak_a = table.remove(soakers, 1)
							soak_b = table.remove(soakers, 1)
							soak_c = table.remove(soakers, 1)
						else
							soak_a = table.remove(soakers)
							soak_b = table.remove(soakers)
							soak_c = table.remove(soakers)
						end
						
						local symbole = SYMBOLES[i]
						if GetRaidTargetIndex(target) ~= symbole then
							SetRaidTargetIcon(target, symbole)
							C_Timer.After(15, function()
								SetRaidTarget(target, 0)
							end)
						end
						
						local aura, _, _, _, _, _, expires = UnitDebuff(target, GetSpellInfo(187050))
						local duration = (expires - GetTime()) - 0.2
						
						local targetname = UnitName(target)
						
						FS:Send("BigWigs", {
							{ "Emphasized", 0, SYMBOLES_NAME[i] .. " (on YOU)" },
							{ "Emphasized", 0, SYMBOLES_NAME[i] .. " (on YOU)", delay = 2 },
							{ "Sound" , 0, "Warning" },
						}, targetname)
						
						local multicast_targets = {}
						if soak_a then table.insert(multicast_targets, (UnitName(soak_a))) end
						if soak_b then table.insert(multicast_targets, (UnitName(soak_b))) end
						if soak_c then table.insert(multicast_targets, (UnitName(soak_c))) end
						
						if #multicast_targets > 0 then
							FS:Send("BigWigs", {
								{ "Emphasized", 0, SYMBOLES_NAME[i] },
								{ "Emphasized", 0, SYMBOLES_NAME[i], delay = 2 },
								{ "Sound" , 0, "Warning" }
							}, "RAID", multicast_targets)
						end
						
						local that_soakers = {}
						if soak_a then that_soakers[UnitName(soak_a)] = true end
						if soak_b then that_soakers[UnitName(soak_b)] = true end
						if soak_c then that_soakers[UnitName(soak_c)] = true end
						
						FS:Send("Marks", {
							target = UnitName(target),
							marker = symbole,
							soakers = that_soakers
						})
						
						C_Timer.After(2 + (0.1 * i), function()
							SendChatMessage(("%s soaked by %s, %s, %s"):format(
								UnitName(target),
								soak_a and UnitName(soak_a) or "?",
								soak_b and UnitName(soak_b) or "?",
								soak_c and UnitName(soak_c) or "?"
							), "RAID")
						end)
					end
					
					wipe(affected)
				end)
			end
		end
	end
end

function Archimonde:ENCOUNTER_START()
	wipe(affected)
end

