From noaaepic/ubuntu20.04-intel-landda:develop

CMD ["/bin/bash"]

ENV HOME=/opt
WORKDIR $HOME

#remove org land-offline_workflow
RUN rm -rf $HOME/land-offline_workflow
COPY . $HOME/land-offline_workflow

#build pFUnit
ENV FC=mpiifort
ENV CC=mpiicc
ENV CXX=mpiicpc
RUN git clone https://github.com/Goddard-Fortran-Ecosystem/pFUnit.git
RUN mkdir -p $HOME/pFUnit/build; cd $HOME/pFUnit/build; ecbuild ..; make -j2; make install

# set env vars
ENV LANDDA_INPUTS=$HOME/landda-data/inputs
ENV EPICHOME=/opt
ENV JEDI_INSTALL=${EPICHOME}
ENV TEST_BASEDIR=${EPICHOME}/landda-data/cycle_land/DA_GHCN_test/mem000/restarts/vector
ENV pFUnit_DIR=${EPICHOME}/pFUnit/build/installed

#build & unit testing
WORKDIR $HOME/land-offline_workflow
RUN source /opt/spack-stack/.bashenv; mkdir build; cd build; pwd; ecbuild .. DCMAKE_PREFIX_PATH=$pFUnit_DIR; make -j2; ctest -V --stop-on-failure
