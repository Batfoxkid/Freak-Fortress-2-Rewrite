# Go to build dir
cd build

# Create package dir
mkdir -p package/addons/sourcemod/translations
mkdir -p package/addons/sourcemod/plugins
mkdir -p package/addons/sourcemod/gamedata
mkdir -p package/addons/sourcemod/data
mkdir -p package/addons/sourcemod/configs

# Copy all required stuffs to package
cp -r ../addons/sourcemod/translations/ff2_rewrite.phrases.txt package/addons/sourcemod/translations
cp -r addons/sourcemod/plugins/freak_fortress_2.smx package/addons/sourcemod/plugins
cp -r addons/sourcemod/plugins/ff2r_default_abilities.smx package/addons/sourcemod/plugins
cp -r addons/sourcemod/plugins/ff2r_menu_abilities.smx package/addons/sourcemod/plugins
cp -r ../addons/sourcemod/gamedata/ff2.txt package/addons/sourcemod/gamedata
cp -r ../addons/sourcemod/data/freak_fortress_2 package/addons/sourcemod/data
cp -r ../addons/sourcemod/configs/freak_fortress_2 package/addons/sourcemod/configs
cp -r ../models package
cp -r ../materials package
cp -r ../sound package