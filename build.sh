mkdir -p package
cd package

# install 3rd party python packages
pip3 install --target ./ boto3 tscribe

# copy index.py into package folder
cp ../index.py ./

# permissions
chmod -R 755 ./*

# check syntax of script
python3 -m py_compile index.py

# run the python test function
python3 -c 'import index; index.test()'

# remove any existing zip and compress python lambda into new zip
rm -f ../function.zip
zip -r9 -q ../function.zip .

# debug info
ls -lah ../function.zip