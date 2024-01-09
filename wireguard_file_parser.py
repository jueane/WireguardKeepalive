#!/usr/bin/python

import configparser
import ipaddress

import find_wireguard_config_files
from WGConfig import WgConfig


def change_last_octet_to_1(ip_address):
    try:
        # ip_address = ipaddress.IPv4Address(ip_address_str)
        network_address = ipaddress.IPv4Network(f"{ip_address.network_address}/24", strict=False)
        new_ip_address = network_address.network_address + 1
        return str(new_ip_address)
    except ipaddress.AddressValueError as e:
        print(f"Error: {e}")
        return None


def get_subnet_first_ip(file_path):
    config = configparser.ConfigParser()
    config.read(file_path)

    if 'Interface' in config:
        interface_section = config['Interface']
        if 'Address' in interface_section:
            address_value = interface_section['Address']
            # 解析IP地址或IP段
            address = ipaddress.ip_interface(address_value)
            # 获取对应的网段的第一个IP
            subnet_first_ip = address.network.network_address

            gate_ip = change_last_octet_to_1(address.network)
            return gate_ip
        else:
            return "Address not found in [Interface] section."
    else:
        return "[Interface] section not found in the configuration file."


wg_config_list = []


def get_all_ips():
    all_files = find_wireguard_config_files.find_all()
    for wg_name, file_path in all_files.items():
        # print('wg config: ', wg_config)
        address_wg = get_subnet_first_ip(file_path)
        print(f"{wg_name}: {address_wg}  {file_path}")
        wg_config_list.append(WgConfig(file_path, wg_name, address_wg))
    return wg_config_list

# get_all_ips()
