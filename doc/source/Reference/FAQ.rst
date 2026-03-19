.. _FAQ:

*********************************
Frequently Asked Questions (FAQ)
*********************************

.. contents::
   :depth: 2
   :local:

.. _DeadTask:

My tasks went DEAD. Why might this be?
========================================

The most common reason for the first few tasks to go DEAD is an improper path in the ``config.yaml`` file that gets propagated to the ``land_analysis.xml`` Rocoto XML file. 
In particular, ``exp_basedir`` must be set to the directory above ``land-DA_workflow``. For example, if ``land-DA_workflow`` resides at ``Users/Jane.Doe/landda/land-DA_workflow``, then ``exp_basedir`` must be set to ``Users/Jane.Doe/landda``. After correcting ``config.yaml``, users will need to regenerate the workflow XML by running: 

.. code-block:: console

   ./setup_wflow_env.py -p=<platform>

Then, rewind the DEAD tasks as described :ref:`below <RestartTask>` using ``rocotorewind``, and use ``rocotorun``/``rocotostat`` to advance/check on the workflow (see :numref:`Section %s <automated-run>` for how to do this). 

If the first few tasks run successfully, but future tasks go DEAD, users will need to check the experiment log files, located at ``$EXP_BASEDIR/ptmp/<envir>/com/output/logs``. It may also be useful to check that the JEDI directory and other paths and values are correct in ``config.yaml``. 


.. _RestartTask:

How do I restart a DEAD task?
=============================

On platforms that utilize Rocoto workflow software (including Ursa and Hercules), if something goes wrong with the workflow, a task may end up in the DEAD state:

.. code-block:: console

   $ rocotostat -w land_analysis.xml -d land_analysis.db

         CYCLE              TASK        JOBID           STATE   EXIT STATUS   TRIES   DURATION
   ==============================================================================================
   202501190000              jcb      8215490       SUCCEEDED            0       1        6.0
   202501190000        prep_data      8215491       SUCCEEDED            0       1       21.0
   202501190000         pre_anal      8215492       SUCCEEDED            0       1        6.0
   202501190000         analysis      8215496       SUCCEEDED            0       1      152.0
   202501190000        post_anal      8215519       SUCCEEDED            0       1       23.0
   202501190000         forecast      8215551       DEAD               256       1          -
   202501190000       plot_stats            -               -            -       -          -

This means that the DEAD task has not completed successfully, so the workflow has stopped. Once the issue has been identified and fixed (e.g., by referencing the log files in ``${BASEDIR}/ptmp/<envir>/com/output/logs``), users can rewind, or "undo," the failed task using the ``rocotorewind`` command:

.. code-block:: console

   rocotorewind -w land_analysis.xml -d land_analysis.db -v 10 -c 202501190000 -t forecast

where ``-c`` specifies the cycle date (first column of ``rocotostat`` output) and ``-t`` represents the task name
(second column of ``rocotostat`` output). This will set the number of tries to 0, as though the task has not been run. After using ``rocotorewind``, the next time ``rocotorun`` is used to advance the workflow, the job will be resubmitted.

.. _unavailable:

My task is UNAVAILABLE. How can I fix this?
============================================

Workload managers such as Slurm typically have a setting that indicates the minimum age of a completed job before its record is cleared from the list of jobs kept in memory. With Slurm, this minimum age is set using the ``MinJobAge`` configuration option, and the default value is often about 5 minutes (300 seconds). As long as users run ``rocotorun`` before the job accounting information disappears, this problem should not appear. To see the ``MinJobAge``, run: 

.. code-block:: console

   scontrol show config | grep MinJobAge

On a normal cluster, users can modify the ``slurm.conf`` file, which is often (but not always) found at ``/etc/slurm/slurm.conf``. Then, run ``scontrol reconfigure`` to tell Slurm to have all daemons reload the ``slurm.conf`` file. However, each node will have its own local ``slurm.conf``. The copy on the controller node (where the ``slurmctl`` deamon is running) actually handles the job accounting, so it may be possible to modify only that one. 

When working on the cloud, especially in AWS ParallelCluster, it is also important to note whether job accounting is turned on such that the historical database is tracking it. Run ``sacct`` and view the console output. A message stating that "Slurm accounting storage is disabled" indicates that it is not turned on. If it is turned on, Rocoto should be able to find the job with ``sacct`` even if the ``MinJobAge`` time has expired. ``MinJobAge`` is how long it takes for job status to age off of squeue, which relies on a different tracking mechanism. ``sacct`` looks at a database that stores everything that ever ran; however, it is incredibly slow, which is why it is only used if truly necessary. 
   

My forecast task goes DEAD or UNAVAILABLE, and the log file indicates an issue with the ``SINGULARITYENV_FI_PROVIDER`` and ``SINGULARITYENV_PREPEND_PATH`` variables. Why? 
============================================================================================================================================================================

This is often a sign that the user is running with the wrong executables. :term:`LND` and :term:`ATML` cases run with different executables. When running the Land DA System in a container, best practice is to create separate directories for LND and ATML experiments. Then, perform all steps from :ref:`Set Up the Container <SetUpContainer>` on in each directory. Run LND experiments in the LND directory and run ATML experiments in the ATML directory. This way, when users set the path to the executables in ``run_container_executable.sh``, each directory is using its own copy of that file. If LND and ATML experiments share a copy of ``run_container_executable.sh``, only one type of experiment can be run at a time. If users switch the path to the executables while configuring a new experiment, any currently running experiments will go DEAD or UNAVAILABLE with an error message similar to the following: 

.. code-block:: console

   running: /usr/bin/singularity exec -B /home:/home -B /home:/home /home/ubuntu/ubuntu22.04-intel-landda-cadre25.img prep_step
   INFO:    Environment variable SINGULARITYENV_FI_PROVIDER is set, but APPTAINERENV_FI_PROVIDER is preferred
   INFO:    Environment variable SINGULARITYENV_PREPEND_PATH is set, but APPTAINERENV_PREPEND_PATH is preferred
   WARNING: While bind mounting '/home:/home': destination is already in the mount point list
   + 2 + /opt/intel/mpi/2021.13/bin/mpiexec -n 78 /home/ubuntu/land-DA_workflow/exec/ufs_model



