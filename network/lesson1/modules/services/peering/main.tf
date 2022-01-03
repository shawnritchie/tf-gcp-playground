
locals {
  peering = flatten([
    for from_network_name, from_network_id in var.peer_networks: [
      for to_network_name, to_network_id in var.peer_networks: {
        from_vpc_name   = from_network_name
        from_vpc_id     = from_network_id
        to_vpc_name     = to_network_name
        to_vpc_id       = to_network_id
      }
      if from_network_name != to_network_name
    ]
  ])
}

resource "google_compute_network_peering" "to" {
  for_each = {
    for peer in local.peering: "${peer.from_vpc_name}-${peer.to_vpc_name}" => peer
  }

  name         = each.key
  network      = each.value.from_vpc_id
  peer_network = each.value.to_vpc_id
}