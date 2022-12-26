# Environments
echo "SCRIPTS_PATH=addons/sourcemod/scripting" >> $GITHUB_ENV
cp scripts/compile.sh addons/sourcemod/scripting/compile.sh
cd addons/sourcemod/scripting

# Set Version
export PLUGIN_VERSION=$(sed -En '/#define PLUGIN_VERSION\W/p' freak_fortress_2.sp)
echo "PLUGIN_VERSION<<EOF" >> $GITHUB_ENV
echo $PLUGIN_VERSION | grep -o '[0-9]*\.[0-9]*' >> $GITHUB_ENV
echo 'EOF' >> $GITHUB_ENV

sed -i -e 's/#define PLUGIN_VERSION_REVISION.*".*"/#define PLUGIN_VERSION_REVISION "'$PLUGIN_VERSION_REVISION'"/g' freak_fortress_2.sp
for file in $(find -type f -name "ff2r_*.sp")
do
  sed -i -e 's/#define PLUGIN_VERSION.*".*"/#define PLUGIN_VERSION "'$PLUGIN_VERSION'"."'$PLUGIN_VERSION_REVISION'"/g' $file
done

# Install Required Includes
cd include
wget "https://raw.githubusercontent.com/DoctorMcKay/sourcemod-plugins/master/scripting/include/morecolors.inc"
wget "https://raw.githubusercontent.com/peace-maker/DHooks2/dynhooks/sourcemod_files/scripting/include/dhooks.inc"
wget "https://raw.githubusercontent.com/asherkin/TF2Items/master/pawn/tf2items.inc"
wget "https://raw.githubusercontent.com/FlaminSarge/tf2attributes/master/scripting/include/tf2attributes.inc"
