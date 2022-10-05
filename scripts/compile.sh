mkdir -p plugins
spcomp -E -O2 -v2 -i "include" -o "plugins/freak_fortress_2" freak_fortress_2.sp
for file in $(find -type f -name "ff2r_*.sp")
do
  echo -e "\nCompiling $file..."
  spcomp -E -O2 -v2 -i "include" -o "plugins/$file" $file
done