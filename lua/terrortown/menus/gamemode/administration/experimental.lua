--- @ignore

CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 100
CLGAMEMODESUBMENU.title = "submenu_administration_experimental_title"

function CLGAMEMODESUBMENU:Populate(parent)
	local form = vgui.CreateTTT2Form(parent, "header_experimental_tweaks")

	form:MakeHelp({
		label = "help_unique_playermodels"
	})

	local unique_pm = form:MakeCheckBox({
		serverConvar = "ttt_unique_playermodels",
		label = "label_unique_playermodels"
	})

	form:MakeHelp({
		label = "help_gang_models"
	})

	form:MakeCheckBox({
		serverConvar = "ttt2_gang_models",
		label = "label_gang_models",
		master = unique_pm
	})

	form:MakeHelp({
		label = "help_shelby_detective"
	})

	form:MakeCheckBox({
		serverConvar = "ttt2_shelby_detective",
		label = "label_shelby_detective"
	})

	form:MakeHelp({
		label = "help_overtime_radar"
	})

	form:MakeCheckBox({
		serverConvar = "ttt_overtime_radar",
		label = "label_overtime_radar"
	})

	local tarkov = vgui.CreateTTT2Form(parent, "header_tarkov")

	tarkov:MakeHelp({
		label = "help_suppression"
	})

	tarkov:MakeCheckBox({
		serverConvar = "ttt_suppression",
		label = "label_suppression"
	})

end
