.. _FAQ:

*********************************
Frequently Asked Questions (FAQ)
*********************************

.. contents::
   :depth: 2
   :local:

.. _RestartTask:

How do I restart a DEAD task?
=============================

On platforms that utilize Rocoto workflow software (including Hera and Orion), if something goes wrong with the workflow, a task may end up in the DEAD state:

.. code-block:: console

   $ rocotostat -w land_analysis.xml -d land_analysis.db

   CYCLE                TASK     JOBID        STATE   EXIT STATUS   TRIES   DURATION
   =======================================================================================
   200001030000     prep_obs  61746034    SUCCEEDED             0       1       11.0
   200001030000     pre_anal  61746035    SUCCEEDED             0       1       13.0
   200001030000     analysis  61746081    SUCCEEDED             0       1       76.0
   200001030000    post_anal  61746109    SUCCEEDED             0       1        4.0
   200001030000   plot_stats  61746110    SUCCEEDED             0       1       70.0
   200001030000     forecast  61746128         DEAD           256       1          -


This means that the dead task has not completed successfully, so the workflow has stopped. Once the issue has been identified and fixed (by referencing the log files in ``$LANDDAROOT/ptmp/test/com/output/logs``), users can re-run the failed task using the ``rocotorewind`` command:

.. code-block:: console

   rocotorewind -w land_analysis.xml -d land_analysis.db -v 10 -c 200001030000 -t forecast

where ``-c`` specifies the cycle date (first column of ``rocotostat`` output) and ``-t`` represents the task name
(second column of ``rocotostat`` output). After using ``rocotorewind``, the next time ``rocotorun`` is used to
advance the workflow, the job will be resubmitted.

