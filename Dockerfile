ARG UFS_DIR=/usr/local/ufs-release-v1

## Build environment
##---------------------------------------------------------------------------------
FROM ubuntu:18.04 AS build-env

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    make \
    openssl \
    bats \
    libssl-dev \
    patch \
    python2.7 \
    libxml2-utils \
    pkg-config \
    gfortran-7 \
    g++-7

ENV CC=gcc-7
ENV CXX=g++-7
ENV FC=gfortran-7

## NCEPLIBS-external data
##---------------------------------------------------------------------------------
FROM ubuntu:18.04 AS NCEPLIBS-external-data

RUN apt-get update && apt-get install -y \
    git && \
    git config --global http.sslverify false && \
    git clone -b ufs-v1.0.0 --recursive https://github.com/NOAA-EMC/NCEPLIBS-external

## NCEPLIBS-external build
##---------------------------------------------------------------------------------
FROM build-env as NCEPLIBS-external-build

ARG UFS_DIR

COPY --from=NCEPLIBS-external-data /NCEPLIBS-external /NCEPLIBS-external

RUN mkdir ${UFS_DIR}

RUN cd /NCEPLIBS-external/cmake-src && \
    ./bootstrap --prefix=${UFS_DIR} && \
    make && \
    make install && \
    cd .. && \
    mkdir build && cd build && \
    ${UFS_DIR}/bin/cmake -DCMAKE_INSTALL_PREFIX=${UFS_DIR} .. 2>&1 | tee log.cmake && \
    make -j8 2>&1 | tee log.make

## NCEPLIBS data
##---------------------------------------------------------------------------------
FROM ubuntu:18.04 AS NCEPLIBS-data

RUN apt-get update && apt-get install -y \
    git && \
    git config --global http.sslverify false && \
    git clone -b ufs-v1.0.0 --recursive https://github.com/NOAA-EMC/NCEPLIBS

## NCEPLIBS build
##---------------------------------------------------------------------------------
FROM build-env as NCEPLIBS-build

ARG UFS_DIR
COPY --from=NCEPLIBS-external-build ${UFS_DIR} ${UFS_DIR}
COPY --from=NCEPLIBS-data /NCEPLIBS /NCEPLIBS

RUN cd NCEPLIBS && \
    mkdir build && \
    cd build && \
    ${UFS_DIR}/bin/cmake -DCMAKE_INSTALL_PREFIX=${UFS_DIR} -DEXTERNAL_LIBS_DIR=${UFS_DIR} .. 2>&1 | tee log.cmake && \
    make -j8 2>&1 | tee log.make && \
    make install 2>&1 | tee log.install

## UFS data
##---------------------------------------------------------------------------------
FROM ubuntu:18.04 AS ufs-data

RUN apt-get update && apt-get install -y \
    git && \
    git config --global http.sslverify false && \
    git clone -b ufs-v1.0.0 --recursive https://github.com/ufs-community/ufs-weather-model

## UFS build
##---------------------------------------------------------------------------------
FROM build-env AS ufs-build

ARG UFS_DIR

COPY --from=NCEPLIBS-build ${UFS_DIR} ${UFS_DIR}
COPY --from=ufs-data /ufs-weather-model /ufs-weather-model

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1 && \
    cd /ufs-weather-model && \
    . ${UFS_DIR}/bin/setenv_nceplibs.sh && \
    export CMAKE_Platform=linux.gnu && \
    bash build.sh 2>&1 | tee build.log && \
    test -f /ufs-weather-model/ufs_weather_model


## Test case data
##---------------------------------------------------------------------------------
FROM ubuntu:18.04 AS test_case

RUN apt-get update && apt-get install -y wget && wget https://ftp.emc.ncep.noaa.gov/EIB/UFS/simple-test-case.tar.gz


## Test case
##---------------------------------------------------------------------------------
FROM ufs-build AS ufs-test

COPY --from=test_case simple-test-case.tar.gz /
RUN tar -xvf /simple-test-case.tar.gz

# run model
CMD ["bash"]
