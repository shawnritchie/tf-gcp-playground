variable "peer_networks" {
  type = map(string)
  description = "List of vpc networks you would like to peer together in a mesh"
  default = {}
}