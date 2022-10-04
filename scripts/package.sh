# Epic Scout Package
mkdir -p custom/epic_scout/addons/sourcemod/configs/freak_fortress_2
mkdir -p custom/epic_scout/addons/sourcemod/configs/plugins
cp addons/sourcemod/configs/freak_fortress_2/non-default/epicscout.cfg custom/epic_scout/addons/sourcemod/configs/freak_fortress_2/epicscout.cfg
cp addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx custom/epic_scout/addons/sourcemod/plugins/ff2r_epic_abilities.smx
rm addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx

# Main Package
mkdir -p plugin
rmdir addons/sourcemod/configs/freak_fortress_2/non-default
cp -r addons/sourcemod/scripting/plugins plugin
cp -r addons/sourcemod/translations plugin
cp -r addons/sourcemod/gamedata plugin
cp -r addons/sourcemod/data plugin
cp -r addons/sourcemod/configs plugin