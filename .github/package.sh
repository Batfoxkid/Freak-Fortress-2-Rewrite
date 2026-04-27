# Epic Scout Package
mkdir -p Epic-Scout/addons/sourcemod/configs/freak_fortress_2
mkdir -p Epic-Scout/addons/sourcemod/plugins
cp -r custom/epic_scout/models Epic-Scout
cp -r custom/epic_scout/materials Epic-Scout
cp -r custom/epic_scout/sound Epic-Scout
cp addons/sourcemod/configs/freak_fortress_2/non-default/epicscout.cfg Epic-Scout/addons/sourcemod/configs/freak_fortress_2/epicscout.cfg
rm addons/sourcemod/configs/freak_fortress_2/non-default/epicscout.cfg

# Gray Mann Package
mkdir -p Gray-Mann/addons/sourcemod/configs/freak_fortress_2
mkdir -p Gray-Mann/addons/sourcemod/plugins
cp -r custom/gray_mann/models Gray-Mann
cp -r custom/gray_mann/materials Gray-Mann
cp -r custom/gray_mann/sound Gray-Mann
cp addons/sourcemod/configs/freak_fortress_2/non-default/graymann.cfg Gray-Mann/addons/sourcemod/configs/freak_fortress_2/graymann.cfg
rm addons/sourcemod/configs/freak_fortress_2/non-default/graymann.cfg

# Blitzkrieg Package
mkdir -p Blitzkrieg/addons/sourcemod/configs/freak_fortress_2
mkdir -p Blitzkrieg/addons/sourcemod/plugins
cp -r custom/blitzkrieg/models Blitzkrieg
cp -r custom/blitzkrieg/materials Blitzkrieg
cp -r custom/blitzkrieg/sound Blitzkrieg
cp addons/sourcemod/configs/freak_fortress_2/non-default/blitzkrieg.cfg Blitzkrieg/addons/sourcemod/configs/freak_fortress_2/blitzkrieg.cfg
rm addons/sourcemod/configs/freak_fortress_2/non-default/blitzkrieg.cfg

# Update Package
mkdir -p Update-Package/addons/sourcemod
cp -r addons/sourcemod/scripting/plugins Update-Package/addons/sourcemod
cp -r addons/sourcemod/translations Update-Package/addons/sourcemod
cp -r addons/sourcemod/gamedata Update-Package/addons/sourcemod
cp -r scripts Update-Package

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
cp -r scripts New-Install-Package