#!/bin/bash
set -e -x

# Deploy packages

# Get OSQP version
export OSQP_VERSION=`python setup.py --version`
if [[ ${OSQP_VERSION} == *"dev"* ]]; then
    export TEST_PYPI="true"
    export ANACONDA_LABEL="dev";
else
    export TEST_PYPI="false"
    export ANACONDA_LABEL="main";
fi

# Anaconda
echo "Deploying to Anaconda..."
anaconda -t $ANACONDA_TOKEN upload ${TRAVIS_BUILD_DIR}/conda-bld/**/*.tar.bz2 --user oxfordcontrol --force -l ${ANACONDA_LABEL}


# Pypi
cd ${TRAVIS_BUILD_DIR}

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    echo "Creating pip binary package..."
    python setup.py bdist_wheel
fi


# Source distribution
if [[ "$TRAVIS_OS_NAME" == "linux" && "$PYTHON_VERSION" == "3.6" ]]; then
	# Choose one python version to upload source distribution
	echo "Creating pip source package..."
	python setup.py sdist

        echo "Creating pip manylinux wheels package..."
        docker run --rm -e PLAT=$WHEELS_PLATFORM -v `pwd`:/io quay.io/pypa/manylinux1_x86_64 /io/ci/travis/build-wheels.sh
        mkdir dist/; cp wheelhouse/*.whl dist/
fi


if [[ -d "dist" && -n "$(ls -A dist)" ]]; then
    echo "Deploying to Pypi..."
    if [[ "$TEST_PYPI" == "true" ]]; then
	twine upload --repository testpypi --config-file ci/pypirc -p $PYPI_PASSWORD --skip-existing wheelhouse/*     # Test pypi repo
    elif [[ -n "$TRAVIS_TAG" ]]; then
	# Upload to main pypi repo if it is not dev and it is a tag
	twine upload --repository pypi --config-file ci/pypirc -p $PYPI_PASSWORD wheelhouse/*
    fi
    echo "Successfully deployed to Pypi"
fi

