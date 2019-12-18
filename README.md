

# Deploy the cloudformation
```sh
create-stack --stack-name "transcribe-on-s3-upload"
```

# Unnote out code in cloudformation and deploy a second time
```sh
update-stack --stack-name "transcribe-on-s3-upload"
```

# Run build script to create a lambda zip with the python packages baked in
```sh
./build.sh
```

# Deploy zip file over place holder lambda


