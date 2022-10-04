# Epic Scout Package
mkdir -p custom/epic_scout/addons/sourcemod/configs/freak_fortress_2
mkdir -p custom/epic_scout/addons/sourcemod/plugins
cp addons/sourcemod/configs/freak_fortress_2/non-default/epicscout.cfg custom/epic_scout/addons/sourcemod/configs/freak_fortress_2/epicscout.cfg
cp addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx custom/epic_scout/addons/sourcemod/plugins/ff2r_epic_abilities.smx
rm addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx

# Update Package
mkdir -p plugin/addons/sourcemod
cp -r addons/sourcemod/scripting/plugins update
cp -r addons/sourcemod/translations update
cp -r addons/sourcemod/gamedata update

# Full Package
rmdir addons/sourcemod/configs/freak_fortress_2/non-default
mkdir -p custom/ff2r_defaults/addons/sourcemod
cp -r addons/sourcemod/scripting/plugins custom/ff2r_defaults/addons/sourcemod
cp -r addons/sourcemod/translations custom/ff2r_defaults/addons/sourcemod
cp -r addons/sourcemod/gamedata custom/ff2r_defaults/addons/sourcemod
cp -r addons/sourcemod/data custom/ff2r_defaults/addons/sourcemod
cp -r addons/sourcemod/configs custom/ff2r_defaults/addons/sourcemod