#!/usr/bin/python

import argparse

def parse_arguments():
    parser = argparse.ArgumentParser(description="Parse parameters with '='.")

    # 允许接收带 '=' 的参数
    parser.add_argument('params', nargs='*', help='Parameters in the form key=value')

    args = parser.parse_args()

    kv_dict = {}

    for param in args.params:
        if '=' in param:
            key, value = param.split('=', 1)  # 只分割一次
            kv_dict[key] = value
        else:
            print(f"Warning: '{param}' is not in key=value format and will be ignored.")

    return kv_dict

if __name__ == "__main__":
    kv = parse_arguments()
    print("Parsed key-value pairs:", kv)
