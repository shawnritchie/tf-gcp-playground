Load Balance: TCP Proxy Load Balancing

**PROPERTIES**
- Direction:      External
- Type:           Global
- VPC Routing:    GLOBAL/REGIONAL
- Mode:           Proxy
- Traffic:        TCP


**Direction**
- Internal: Traffic originating in the VPC
- External: Traffic originating from the internet

**Load Balancing Type**
- GLOBAL: Any cast IP address 
    - Distribution: Multiple load balancers distributed across regions
- REGIONAL: Backends are all in the same region
    - Distirbution: Multiple load balancers distributed in multiple zones

**Load Balancing Mode**
- Proxy: terminate incoming client connections and open new connections form the load balancer
- Pass-through: do not terminate client connections.

**Traffic**
- HTTP/HTTPS
- SSL Excluding port 80/8080
- TCP Excluding port 80/8080
- UDP
- ESP/ICMP