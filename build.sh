mkdir -p package
cd package

# install 3rd party python packages
# tscribe: https://github.com/kibaffo33/aws_transcribe_to_docx
pip3 install --target ./ boto3 tscribe

# copy index.py into package folder
cp ../index.py ./

# permissions
chmod -R 755 ./*

# check syntax of script
python3 -m py_compile index.py

# remove compiled bytecode to remain under lambdas 50MB zip limit
find . -name '*.pyc' -delete

# run the python test function
python3 -c 'import index; index.test()'

# remove any existing zip and compress python lambda into new zip
rm -f ../function.zip
zip -r9 -q ../function.zip .

# debug info
echo "debug info"
ls -lah ../function.zip
python3 --version
