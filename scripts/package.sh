# Epic Scout Package
mkdir -p Epic-Scout/addons/sourcemod/configs/freak_fortress_2
mkdir -p Epic-Scout/addons/sourcemod/plugins
cp -r custom/epic_scout/models Epic-Scout
cp -r custom/epic_scout/materials Epic-Scout
cp -r custom/epic_scout/sound Epic-Scout
cp addons/sourcemod/configs/freak_fortress_2/non-default/epicscout.cfg Epic-Scout/addons/sourcemod/configs/freak_fortress_2/epicscout.cfg
rm addons/sourcemod/configs/freak_fortress_2/non-default/epicscout.cfg
cp addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx Epic-Scout/addons/sourcemod/plugins/ff2r_epic_abilities.smx
rm addons/sourcemod/scripting/plugins/ff2r_epic_abilities.smx

# Update Package
mkdir -p Update-Package
cp -r addons/sourcemod/scripting/plugins Update-Package
cp -r addons/sourcemod/translations Update-Package
cp -r addons/sourcemod/gamedata Update-Package

# Full Package
rmdir addons/sourcemod/configs/freak_fortress_2/non-default
mkdir -p New-Install-Package/addons/sourcemod
cp -r custom/ff2r_defaults/models New-Install-Package
cp -r custom/ff2r_defaults/materials New-Install-Package
cp -r custom/ff2r_defaults/sound New-Install-Package
cp -r addons/sourcemod/scripting/plugins New-Install-Package/addons/sourcemod
cp -r addons/sourcemod/translations New-Install-Package/addons/sourcemod
cp -r addons/sourcemod/gamedata New-Install-Package/addons/sourcemod
cp -r addons/sourcemod/data New-Install-Package/addons/sourcemod
cp -r addons/sourcemod/configs New-Install-Package/addons/sourcemod