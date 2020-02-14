#!/bin/bash
# set -x
CLI_ARGUMENT_COUNT="1"

#
# Build function.zip locally , deploy AWS infrastructure and then upload function.zip and deploy as a Lambda.
#

#
# Test to see if this script was called with an AWS profile parameter locally
#
if [ "$#" == "${CLI_ARGUMENT_COUNT}" ];
then 
    PROFILE_PARAM=$(echo -e "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
else
    echo 
    echo "Usage: ./deploy-locally-macos.sh <aws-profile>"
    echo
    echo
    echo "Example ./deploy-locally-macos.sh my-aws-dev-profile"
    echo
    exit 0
fi

#
# If --profile has been set then I assume I am running this script on a local machine.
# Test to see if local machine is a mac if so build image locally.
#

if [[ "$OSTYPE" == "darwin"* ]]; then

    #
    # Test for awscli and install if necessary
    #
    if ! [ -x $(command -v aws --version) ]; then
        echo "awscli is  missing...installing..."
        brew install awscli
        brew upgrade awscli
        brew link --overwrite awscli
    else
        echo "awscli is already installed..."
    fi

    #
    # Test for docker-machine and install if necessary
    #
    if ! [ -x $(command -v docker-machine --version) ]; then
        echo "docker-machine  is  missing...installing..."
        brew install docker-machine
        brew upgrade docker-machine
        brew unlink docker-machine && brew link docker-machine
        sudo chown ${USER}:staff /usr/local/Caskroom
    else
        echo "docker-machine is already installed..."
    fi

    #
    # Test for virtualbox and install if necessary
    #
    if ! [ -x $(command -v virtualbox --version) ]; then
        echo "aws virtualbox is  missing...installing..."
        brew install virtualbox
        brew upgrade virtualbox
        brew unlink virtualbox && brew link virtualbox
        sudo chown ${USER}:staff /usr/local/Caskroom
    else
        echo "virtualbox is already installed..."
    fi

    # The following may be needed to run on your mac to enable virtualbox to run.
    # 1 Restart your mac in Recovery mode (cmd + R)
    # 2 Open a Terminal and enter:  spctl kext-consent add VB5E2TV963
    # 3 Restart your mac.

    #
    # Create a docker-machine called default
    #
    yes | docker-machine rm  default
    docker-machine create --driver virtualbox default
    docker-machine env default

    #
    # Point local docker process to docker-machine environment
    #
    eval $(docker-machine env default)

    #
    # Clean-up after any previous builds. Use existing Dockerfile to create a Docker container and 
    # our deployment package inside it.
    #
    rm -Rf ${PWD}/package
    docker rm transcriber:local
    docker build -t transcriber:local .
    docker run -v ${PWD}:/var/app -w /var/app -it transcriber:local /bin/sh -c "chmod +x build.sh && ./build.sh; exit"
else
    echo
    echo "You are not using macOS... Goodbye..."
    echo

    exit 0
fi

#
# Deploy our newly built function to AWS.
#
chmod 775 ${PWD}/deploy.sh
${PWD}/deploy.sh ${PROFILE_PARAM}

