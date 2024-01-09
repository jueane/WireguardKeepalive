#!/usr/bin/env python

import glob
import os


def find_all():
    file_pattern = '/etc/wireguard/*.conf'
    matching_files = glob.glob(file_pattern)

    result = {}
    for file_path in matching_files:
        wg_name = os.path.basename(file_path)
        file_name_without_extension = os.path.splitext(wg_name)[0]
        result[file_name_without_extension] = file_path

    return result

# files_dict = find_all()
# for file_name, file_path in files_dict.items():
#     print(f"{file_name}: {file_path}")
