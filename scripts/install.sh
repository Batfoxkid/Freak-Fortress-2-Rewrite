# Create build folder
mkdir build
cd build

# Install SourceMod
wget --input-file=http://sourcemod.net/smdrop/$SM_VERSION/sourcemod-latest-linux
tar -xzf $(cat sourcemod-latest-linux)

# Copy sp to build dir
cp -r ../addons/sourcemod/scripting addons/sourcemod
cd addons/sourcemod/scripting

# Install Dependency
wget "https://www.doctormckay.com/download/scripting/include/morecolors.inc" -O include/morecolors.inc
wget "https://raw.githubusercontent.com/peace-maker/DHooks2/dynhooks/sourcemod_files/scripting/include/dhooks.inc" -O include/dhooks.inc
wget "https://raw.githubusercontent.com/asherkin/TF2Items/master/pawn/tf2items.inc" -O include/tf2items.inc
wget "https://raw.githubusercontent.com/FlaminSarge/tf2attributes/master/tf2attributes.inc" -O include/tf2attributes.inc

# Install Third-Parties
wget "https://raw.githubusercontent.com/nosoop/SM-TFCustAttr/master/scripting/include/tf_custom_attributes.inc" -O include/tf_custom_attributes.inc
wget "https://raw.githubusercontent.com/nosoop/SM-TFEconData/master/scripting/include/tf_econ_data.inc" -O include/tf_econ_data.inc
wget "https://raw.githubusercontent.com/nosoop/SM-TFCustomWeaponsX/master/scripting/include/cwx.inc" -O include/cwx.inc
wget "https://raw.githubusercontent.com/nosoop/SM-TFUtils/master/scripting/include/tf2utils.inc" -O include/tf2utils.inc
wget "https://raw.githubusercontent.com/Flyflo/SM-Goomba-Stomp/master/addons/sourcemod/scripting/include/goomba.inc" -O include/goomba.inc