To check on the job status, users on a system with a Slurm job scheduler may run: 

.. code-block:: console

   squeue -u $USER

To view the experiment status, run:

.. code-block:: console

   rocotostat -w land_analysis.xml -d land_analysis.db

If ``rocotorun`` was successful, the ``rocotostat`` command will print a status report to the console. For example:

.. code-block:: console

         CYCLE          TASK                       JOBID         STATE  EXIT STATUS   TRIES   DURATION
   ======================================================================================================
   202501190000          jcb                    11531200     SUCCEEDED            0       1       11.0
   202501190000    prep_data                    11531199     SUCCEEDED            0       1       25.0
   202501190000     pre_anal                    11531202     SUCCEEDED            0       1        5.0
   202501190000     analysis   druby://10.184.3.61:45183    SUBMITTING            -       0        0.0
   202501190000    post_anal                           -             -            -       -          -
   202501190000     forecast                           -             -            -       -          -
   202501190000   plot_stats                           -             -            -       -          -
   ======================================================================================================
   202501200000          jcb                    11531201     SUCCEEDED            0       1       11.0
   202501200000    prep_data                           -             -            -       -          -
   202501200000     pre_anal                           -             -            -       -          -
   202501200000     analysis                           -             -            -       -          -
   202501200000    post_anal                           -             -            -       -          -
   202501200000     forecast                           -             -            -       -          -
   202501200000   plot_stats                           -             -            -       -          -

Note that the status table printed by ``rocotostat`` only updates after each ``rocotorun`` command (whether issued manually or via cron/launch script automation). For each task, a log file is generated. These files are stored in ``${BASEDIR}/ptmp/<envir>/com/output/logs``. 

The experiment has successfully completed when all tasks say SUCCEEDED under STATE. Other potential statuses are: QUEUED, SUBMITTING, RUNNING, and DEAD. Users may view the log files to determine why a task may have failed.