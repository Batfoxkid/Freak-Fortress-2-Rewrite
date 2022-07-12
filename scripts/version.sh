# https://github.com/redsunservers/SuperZombieFortress/blob/master/scripts/version.sh
cd build/addons/sourcemod/scripting

export PLUGIN_VERSION=$(sed -En '/#define PLUGIN_VERSION\W/p' freak_fortress_2.sp)
echo "PLUGIN_VERSION<<EOF" >> $GITHUB_ENV
echo $PLUGIN_VERSION | grep -o '[0-9]*\.[0-9]*' >> $GITHUB_ENV
echo 'EOF' >> $GITHUB_ENV

sed -i -e 's/#define PLUGIN_VERSION.*".*"/#define PLUGIN_VERSION "'$PLUGIN_VERSION'.'$PLUGIN_VERSION_REVISION'"/g' ff2r_default_abilities.sp
sed -i -e 's/#define PLUGIN_VERSION.*".*"/#define PLUGIN_VERSION "'$PLUGIN_VERSION'.'$PLUGIN_VERSION_REVISION'"/g' ff2r_menu_abilities.sp
sed -i -e 's/#define PLUGIN_VERSION_REVISION.*".*"/#define PLUGIN_VERSION_REVISION "'$PLUGIN_VERSION_REVISION'"/g' freak_fortress_2.sp