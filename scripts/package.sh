# Epic Scout Package
mkdir -p custom/epic_scout/addons/sourcemod/configs/freak_fortress_2
mkdir -p custom/epic_scout/addons/sourcemod/plugins
cp addons/sourcemod/configs/freak_fortress_2/non-default/epicscout.cfg custom/epic_scout/addons/sourcemod/configs/freak_fortress_2/epicscout.cfg
cp addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx custom/epic_scout/addons/sourcemod/plugins/ff2r_epic_abilities.smx
rm addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx

# Default Package
rmdir addons/sourcemod/configs/freak_fortress_2/non-default
mkdir -p custom/ff2r_defaults/addons/sourcemod
cp -r addons/sourcemod/configs custom/ff2r_defaults/addons/sourcemod/

# Main Package
mkdir -p plugin/addons/sourcemod
cp -r addons/sourcemod/scripting/plugins plugin/addons/sourcemod
cp -r addons/sourcemod/translations plugin/addons/sourcemod
cp -r addons/sourcemod/gamedata plugin/addons/sourcemod
cp -r addons/sourcemod/data plugin/addons/sourcemod