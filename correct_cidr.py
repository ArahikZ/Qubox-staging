import argparse
import ipaddress
import os
import shutil
import yaml


def main() -> bool:
    parser = argparse.ArgumentParser(
        prog='correcct_cidr',
        description="Used to update the CIDR of ip address, but can be used to update IP address with the '-u' flag.")
    parser.add_argument('-u', '--update', action='store_true', default=False)
    args = parser.parse_args()

    print('Defaulting CIDR to a /27')
    contents = yaml_contents()
    nic_name = list(contents['network']['ethernets'].keys())[0]

    if args.update:
        while True:
            ip_address = input("Enter required IP address: ")
            gateway = input("Enter desired gateay address: ")
            answer = input(f'Is the follwing info correct\nIP Address; {ip_address}\nGateway: {gateway} \n(y/n) ')
            if answer.lower() not in 'y/n' or answer.lower() != 'yes' or answer.lower() != 'no':
                print("Invalid option. Try again...\n")
                continue
            elif answer == 'n' or answer == 'no':
                continue
            else:
                break
    else:
        try:
            gateway = contents['network']['ethernets'][nic_name]['gateway4']
            ip_address = contents['network']['ethernets'][nic_name]['addresses'][0]
        except KeyError:
            raise KeyError('No contents found make sure you ran the setup.sh file first.')

    print(f'Your NIC: {nic_name}')
    print(f'Your IP address: {ip_address}')
    print(f'Your gateway: {gateway}')

    new_address = ip_address.split('/')[0]

    try:
        ip = ipaddress.ip_address(new_address)
        gtw = ipaddress.ip_address(gateway)

    except ValueError:
        raise ValueError('Ip Address or Gateway is malformed, please check address and try again' \
                f' IP: {new_address} Gateway: {gateway}')

    new_address = new_address + '/27'

    print(f'Your new address: {new_address}')

    yaml_output = f"""network:
  version: 2
  renderer: networkd
  ethernets:
    {nic_name}:
      dhcp4: no
      addresses:
        - {new_address}
      gateway4: {gateway}
      nameservers:
        addresses: [10.104.48.31, 10.104.48.32, 10.104.48.33, 10.95.128.31, 10.95.128.5]"""

    print(f'Updating yaml to:\n{yaml_output}\n')
    if saved_network_config_to_temp_file(yaml_output, 'netplan_temp_file.yaml'):
        print('Saving to tempory file failed.')
        return 1

    if moved_network_config():
        print('Overriding config file with temp file failed.')
        return 1

    print('CIRD update complete')
    return 0


def yaml_contents() -> yaml:
    with open('/etc/netplan/01-netcfg.yaml', 'r') as file:
        return yaml.safe_load(file)


def saved_network_config_to_temp_file(yaml_output: str, file_path: str) -> bool:
    with open(file_path, 'w') as file:
        file.write(yaml_output)
    if not os.path.isfile(f'./{file_path}'):
        return True
    return False


def moved_network_config() -> bool:
    shutil.move('./netplan_temp_file.yaml', '/etc/netplan/01-netcfg.yaml')
    with open('/etc/netplan/01-netcfg.yaml', 'r') as file:
        if '/27' not in file.read():
            return True
    if os.path.isfile('./netplan_temp_file.yaml'):
        print("Replace/update process failed to remove temp config file. Removing file")
        try:
            os.remove('/etc/netplan/01-netcfg.yaml')
        except OSError as error:
            print(error)
            print(f'Failure to remove temp config file. Please manually delete from {os.getcwd()}')
            return True
    return False


if __name__ == "__main__":
    main()
