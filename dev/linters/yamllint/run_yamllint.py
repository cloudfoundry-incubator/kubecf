import os
from yamllint import cli

bazel_working_dir = os.environ['BUILD_WORKING_DIRECTORY']

if bazel_working_dir:
    os.chdir(bazel_working_dir)

cli.run()
