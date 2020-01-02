mkdir -p package
cd package

# install 3rd party python packages
pip3 install pipenv
pipenv install boto3 tscribe

# copy index.py into package folder
cp ../index.py ./

# permissions
chmod -R 755 ./*

# check syntax of script
python3 -m py_compile index.py

# run the python test function
python3 -c 'import index; index.test()'

# compress python lambda into zip
zip -r9 -q ../function.zip .