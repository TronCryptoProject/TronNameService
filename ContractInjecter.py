#!/usr/bin/python

import os, glob,json

CONTRACT_BUILD_DIR = os.getenv("CONTRACT_BUILD_DIR", "~/")
INJECTER_FILE_DIR = os.getenv("INJECTER_FILE_DIR", "~/")
injector_dict = {}

for filepath in glob.iglob(os.path.join(CONTRACT_BUILD_DIR,"*.json")):
    if os.path.isfile(filepath):
        with open(filepath, "r") as in_file:
            json_data = json.load(in_file)

        injector_dict[json_data["contractName"]] = {
            "abi": json_data["abi"],
            "bytecode": json_data["bytecode"],
            "address": json_data["networks"]["*"]["address"]
        }

with open(os.path.join(INJECTER_FILE_DIR,"injecter.json"), "w") as out_file:
    json.dump(injector_dict, out_file, indent=4, sort_keys=True)


        

