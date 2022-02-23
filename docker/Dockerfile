FROM nvidia/cuda:11.6.0-devel-ubuntu20.04

USER root

RUN apt update --quiet && \
DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends --no-install-suggests --yes apt-utils software-properties-common wget build-essential  libcrypto++-dev  python3-dev python3-pip libhdf5-serial-dev cmake git-core libboost-all-dev libfftw3-dev h5utils jq hdf5-tools liblapack-dev libatlas-base-dev libxml2-dev libfreetype6-dev pkg-config libxslt-dev libarmadillo-dev libace-dev libgtest-dev liblapacke-dev libplplot-dev gcc-multilib supervisor net-tools cpio libpugixml-dev jove libopenblas-base libopenblas-dev   librocksdb-dev 

RUN pip3 install -U pip setuptools testresources
RUN DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends --no-install-suggests --yes python3-tk
RUN pip3 install numpy scipy Cython tk-tools matplotlib scikit-image opencv_python pydicom scikit-learn sympy Pillow h5py pyxb
#RUN apt-get install --no-install-recommends --no-install-suggests --yes python3-psutil python3-lxml
#RUN pip3 install torch==1.4.0+cpu torchvision==0.5.0+cpu -f https://download.pytorch.org/whl/torch_stable.html
RUN pip3 install torch==1.5.0+cpu torchvision==0.6.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# for embedded python plot, we need agg backend
RUN mkdir -p /root/.config/matplotlib && touch /root/.config/matplotlib/matplotlibrc && echo "backend : agg" >> /root/.config/matplotlib/matplotlibrc

# compile dcmtk
RUN mkdir /opt/code && \
    cd /opt/code && \
    wget https://dicom.offis.de/download/dcmtk/dcmtk365/dcmtk-3.6.5.tar.gz && \
    tar xvf /opt/code/dcmtk-3.6.5.tar.gz && \
    mkdir /opt/code/dcmtk-3.6.5/build && \
    cd /opt/code/dcmtk-3.6.5/build && \
    cmake -DBUILD_SHARED_LIBS=ON ../ && make -j16 && make install && cd /opt/code && \
    rm -rf /opt/code/dcmtk-3.6.5 && rm -rf /opt/code/dcmtk-3.6.5.tar.gz

RUN cd /opt/code && \
    git clone https://github.com/google/googletest.git && \
    cd googletest && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release ../ && \
    make -j $(nproc) && make install && cd /opt/code && rm -rf /opt/code/googletest

#Set more environment variables in preparation for Gadgetron installation
ENV GADGETRON_HOME=/usr/local \
    ISMRMRD_HOME=/usr/local

ENV PATH=$PATH:$GADGETRON_HOME/bin:$ISMRMRD_HOME/bin \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ISMRMRD_HOME/lib:$GADGETRON_HOME/lib

# Clean up packages.
RUN  apt-get clean && \
   rm -rf /var/lib/apt/lists/*

#Set more environment variables in preparation for Gadgetron installation
ENV GADGETRON_HOME=/usr/local \
    ISMRMRD_HOME=/usr/local

ENV PATH=$PATH:$GADGETRON_HOME/bin:$ISMRMRD_HOME/bin \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ISMRMRD_HOME/lib:$GADGETRON_HOME/lib
    
ARG GADGETRON_URL=https://github.com/gadgetron/gadgetron
ARG GADGETRON_BRANCH=master

#ISMRMRD
RUN cd /opt/code && \
    git clone https://github.com/ismrmrd/ismrmrd.git && \
    cd ismrmrd && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make -j $(nproc) && \
    make install

RUN apt update --quiet && \
DEBIAN_FRONTEND=noninteractive apt install --no-install-recommends --no-install-suggests --yes nlohmann-json3-dev librange-v3-dev

#GADGETRON
RUN cd /opt/code && \
    git clone ${GADGETRON_URL} --branch ${GADGETRON_BRANCH} --single-branch && \
    cd gadgetron && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make -j $(nproc) && \
    make install && \
    #/opt/code/gadgetron/docker/manifest --key .io.gadgetron.gadgetron.sha1 --value `git rev-parse HEAD` && \
    cp /opt/code/gadgetron/docker/start_supervisor /opt/ && \
    cp /opt/code/gadgetron/docker/supervisord.conf /opt/

# Install Python interface.
RUN pip3 install gadgetron

#HASH for ISMRMRD
#RUN cd /opt/code/ismrmrd && \
#    /opt/code/gadgetron/docker/manifest --key .io.gadgetron.ismrmrd.sha1 --value `git rev-parse HEAD` 

#SIEMENS_TO_ISMRMRD
RUN cd /opt/code && \
    git clone https://github.com/ismrmrd/siemens_to_ismrmrd.git && \
    cd siemens_to_ismrmrd && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make -j $(nproc) && \
    make install 
   # /opt/code/gadgetron/docker/manifest --key .io.gadgetron.siemens_to_ismrmrd.sha1 --value `git rev-parse HEAD` 

#PHILIPS_TO_ISMRMRD
RUN cd /opt/code && \
    git clone https://github.com/ismrmrd/philips_to_ismrmrd.git && \
    cd philips_to_ismrmrd && \
    mkdir build && \
    cd build && \
    cmake ../ && \
    make -j $(nproc) && \
    make install
  #  /opt/code/gadgetron/docker/manifest --key .io.gadgetron.philips_to_ismrmrd.sha1 --value `git rev-parse HEAD` 

# aditions which aren't covered in the official images

#BART
ENV BART_DIR="/opt/code/bart"
ENV TOOLBOX_PATH="${BART_DIR}"
ENV PATH="${BART_DIR}:$PATH"
RUN cd /root \
 && wget https://github.com/mrirecon/bart/archive/v0.7.00.tar.gz \
 && tar xzf v0.7.00.tar.gz \
 && rm v0.7.00.tar.gz \
 && mv ./bart-0.7.00/ ${BART_DIR} \
 && cd ${BART_DIR} \
 && make \
 && make install \
 && echo "export BART_DIR=\"${BART_DIR}\"" >> /etc/profile.d/bart.sh \
 && echo "export TOOLBOX_PATH=\"${BART_DIR}\"" >> /etc/profile.d/bart.sh \
 && echo "PATH=\"${BART_DIR}:\$PATH\"" >> /etc/profile.d/bart.sh 

RUN apt update \
 && apt install -y --no-install-recommends sudo nano htop
RUN pip3 install sigpy pygrappa nibabel

# Clean up packages.
RUN  apt-get clean && \
   rm -rf /var/lib/apt/lists/*

# Set up the gadgetron user
ARG USERNAME=gadgetron
ARG USERPASS=meduser1
RUN useradd --create-home --user-group --uid=1010 "${USERNAME}"
# allow sudo w/o password
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USERNAME} \
 && chmod 0440 /etc/sudoers.d/${USERNAME}
# set password and standard shell
RUN echo "${USERNAME}:${USERPASS}" | chpasswd \
 && chsh -s /bin/bash "${USERNAME}"

USER ${USERNAME}
WORKDIR /home/${USERNAME}

#ENTRYPOINT ['gadgetron']
ENTRYPOINT ["sudo", "/usr/bin/bash"]

# gadgetron
EXPOSE 9002
EXPOSE 9023
# supervisord web interface	
EXPOSE 9001
# ReST API
EXPOSE 9080
# CloudBus relay
EXPOSE 8002
