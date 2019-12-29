mkdir -p package

# install 3rd party python package
pip3 install --target ./package tscribe

# check syntax of script
python3 -m py_compile index.py

# copy index.py into package folder
cp index.py package/

# permissions
chmod -R 755 package/*

# compress python lambda into zip
cd package && zip -r9 -q ../function.zip .