From noaaepic/ubuntu22.04-intel21.10-landda:ue160-dev

CMD ["/bin/bash"]

ENV HOME=/opt
WORKDIR $HOME

# Get Land DA data
RUN wget https://noaa-ufs-land-da-pds.s3.amazonaws.com/develop-20240809/inputs.tar.gz && \
    tar -xvzf inputs.tar.gz && mv inputs/* /opt/land-DA_workflow/fix/

# set env vars
ENV FIXlandda=$HOME/land-DA_workflow/fix
ENV JEDI_INSTALL=$HOME
ENV FIXdir=/opt/land-DA_workflow/fix
ENV JEDI_EXECDIR=/opt/jedi-bundle/install/bin

# Fix UFS WM RT File paths
RUN ln -s /opt/land-DA_workflow/install/bin/ufs_model /opt/land-DA_workflow/build/ufs_model.fd/src/ufs_model.fd-build/
RUN sed -i '18 i PLATFORM=jet' /opt/land-DA_workflow/sorc/test/run_ufs_datm_lnd.sh
RUN mv /opt/land-DA_workflow/fix/DATM_input_data /opt/land-DA_workflow/fix/DATM_GSWP3_input_data && \
    ln -s /opt/land-DA_workflow/fix/DATM_GSWP3_input_data/gswp3/* /opt/land-DA_workflow/fix/DATM_GSWP3_input_data/
RUN mkdir -p /opt/land-DA_workflow/fix/FV3_input_data/INPUT && \ 
    ln -s /opt/land-DA_workflow/fix/FV3_fix_tiled/C96/* /opt/land-DA_workflow/fix/FV3_input_data/INPUT

#build & unit testing
WORKDIR $HOME/land-DA_workflow
#RUN source /opt/spack-stack/.bashenv; mkdir build; cd build; pwd; ecbuild ..; make -j2; ctest -V --stop-on-failure
RUN source /opt/spack-stack/spack-stack-1.6.0/.bashenv; cd build; pwd; ctest -V --stop-on-failure
