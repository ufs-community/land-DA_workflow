From noaaepic/ubuntu20.04-intel-ue-landda:develop

CMD ["/bin/bash"]

ENV HOME=/opt
WORKDIR $HOME

#remove org land-offline_workflow
RUN rm -rf $HOME/land-offline_workflow
COPY . $HOME/land-offline_workflow

# set env vars
ENV LANDDA_INPUTS=$HOME/landda-data/inputs
ENV EPICHOME=/opt
ENV JEDI_INSTALL=${EPICHOME}
ENV TEST_BASEDIR=${EPICHOME}/landda-data/cycle_land/DA_GHCN_test/mem000/restarts/vector

#build & unit testing
WORKDIR $HOME/land-offline_workflow
RUN source /opt/spack-stack/.bashenv; mkdir build; cd build; pwd; ecbuild ..; make -j2; ctest -V --stop-on-failure
