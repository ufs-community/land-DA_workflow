From noaaepic/ubuntu20.04-intel-landda:develop

CMD ["/bin/bash"]

ENV HOME=/home
COPY . $HOME/land-offline_citest

WORKDIR $HOME/land-offline_citest

RUN pwd

RUN echo $(ls $HOME/land-offline_citest)

RUN mkdir build; cd build; source /opt/spack-stack/.bashenv; ecbuild ..; make -j 2
