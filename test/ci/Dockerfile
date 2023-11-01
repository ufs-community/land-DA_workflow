From noaaepic/ubuntu20.04-intel-landda:develop
#test new landda container updates

CMD ["/bin/bash"]

ENV HOME=/opt
WORKDIR $HOME

#remove org land-offline_workflow
RUN rm -rf $HOME/land-offline_workflow
COPY . $HOME/land-offline_workflow

# set env vars
ENV LANDDA_INPUTS=$HOME/inputs
ENV EPICHOME=/opt
ENV JEDI_INSTALL=${EPICHOME}/jedi
ENV TEST_BASEDIR=${EPICHOME}/test_base/mem000/restarts/vector"}

#build & unit testing
WORKDIR $HOME/land-offline_workflow
RUN source /opt/spack-stack/.bashenv; mkdir build; cd build; pwd; ecbuild ..; make -j2; ctest -V --stop-on-failure
