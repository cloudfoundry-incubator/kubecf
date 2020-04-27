# A script to be used by the yaml_loader repository rule to convert a JSON object into a .bzl file.

import json
import sys

with open(sys.argv[1], "r") as stream:
    for key, value in json.load(stream).items():
        print(key + " = " + str(value) + "\n")
