**Project**: networking-lesson1
  - **VPC**: mynetwork
    - **Subnet**: 10.128.0.0/20
      - **Instance**: mynet-us-vm
        - **nic0**: mynetwork
    - **Subnet**: 10.132.0.0/20
        - **Instance**: mynet-eu-vm
            - **nic0**: mynetwork
  - **VPC**: management
    - **Subnet**: 10.130.0.0/20
        - **Instance**: mgmt-eu-vm
            - **nic0**: management
            - **nic0**: 10.132.0.0/20
            - **nic1**: 172.20.0.0/20
  - **VPC**: privatenet
    - **Subnet**: 172.16.0.0/24
        - **Instance**: pnet-eu-vm
            - **nic0**: privatenet
    - **Subnet**: 172.20.0.0/20
        - **Instance**: pnet-eu-vm
            - **nic0**: privatenet