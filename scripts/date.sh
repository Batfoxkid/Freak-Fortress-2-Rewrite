SEC=$(date "+%s")
MIN=$(expr $((SEC)) / 60)
echo "DATA_VERSION<<EOF" >> $GITHUB_ENV
echo $MIN >> $GITHUB_ENV
echo 'EOF' >> $GITHUB_ENV