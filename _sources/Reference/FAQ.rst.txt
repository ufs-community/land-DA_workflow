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

   rocotostat -w land_analysis.xml -d land_analysis.db
   CYCLE              TASK       JOBID       STATE EXIT STATUS  TRIES   DURATION
   =============================================================================
   200001030000    prepexp    16779414   SUCCEEDED           0      1       11.0
   200001030000    prepobs    16779415   SUCCEEDED           0      1        0.0
   200001030000   prepbmat    16779416   SUCCEEDED           0      1        9.0
   200001030000     runana    16779434   SUCCEEDED           0      1       68.0
   200001030000    runfcst           -        DEAD         256      1     2186.0


This means that the dead task has not completed successfully, so the workflow has stopped. Once the issue has been identified and fixed (by referencing the log files), users can re-run the failed task using the ``rocotorewind`` command:

.. COMMENT: Where are the log files actually?

.. code-block:: console

   rocotorewind -w land_analysis.xml -d land_analysis.db -v 10 -c 200001030000 -t runfcst

where ``-c`` specifies the cycle date (first column of ``rocotostat`` output) and ``-t`` represents the task name
(second column of ``rocotostat`` output). After using ``rocotorewind``, the next time ``rocotorun`` is used to
advance the workflow, the job will be resubmitted.

