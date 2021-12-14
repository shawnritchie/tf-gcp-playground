terraform {
  required_version = ">= 1.0"
  experiments = [module_variable_optional_attrs]
  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

locals {
  customerId = "C015bbxfj"
  domain     = "spinvadors.com"
  groupName  = "org-admin-group"
  groups = [
    "gcp-organization-admins",
    "gcp-network-admins",
    "gcp-billing-admins",
    "gcp-security-admins",
    "gcp-devops",
    "gcp-developers"
  ]
  folders = {
    production = {
      name = "production"
    },
    development = {
      name = "development"
    },
    prod_shared = {
      name = "shared"
      parent = "production"
    },
    dev_shared = {
      name = "shared"
      parent = "development"
    }
  }
  projects = [
    {
      group     = "gcp-network-admins"
      folder    = "development"
      project   = "example-vpc-host-dev"
      services  = []
      roles     = ["roles/owner"]
    },
    {
      group     = "gcp-network-admins"
      folder    = "production"
      project   = "example-vpc-host-prod"
      services  = []
      roles     = ["roles/owner"]
    }
  ]
  groups_org_policy = {
    "gcp-organization-admins" = [
      "roles/resourcemanager.organizationAdmin",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator",
      "roles/billing.admin",
      "roles/iam.organizationRoleAdmin",
      "roles/orgpolicy.policyAdmin",
      "roles/securitycenter.admin",
      "roles/cloudsupport.admin"
    ],
    "gcp-network-admins" = [
      "roles/compute.networkAdmin",
      "roles/compute.xpnAdmin",
      "roles/compute.securityAdmin",
      "roles/resourcemanager.folderViewer"
    ],
    "gcp-security-admins" = [
      "roles/orgpolicy.policyAdmin",
      "roles/orgpolicy.policyViewer",
      "roles/iam.securityReviewer",
      "roles/iam.organizationRoleViewer",
      "roles/securitycenter.admin",
      "roles/resourcemanager.folderIamAdmin",
      "roles/logging.privateLogViewer",
      "roles/logging.configWriter",
      "roles/container.viewer",
      "roles/compute.viewer",
      "roles/bigquery.dataViewer"
    ],
    "gcp-devops" = [
      "roles/resourcemanager.folderViewer"
    ]
  }
  flattened_group_org_policy = flatten([
    for grp, roles in local.groups_org_policy: [
      for role in roles: {
        group = grp
        role = role
      }
    ]
  ])
  groups_folder_policy = {
    gcp-devops = {
      folder = "production"
      roles = [
        "roles/logging.admin",
        "roles/errorreporting.admin",
        "roles/servicemanagement.quotaAdmin",
        "roles/monitoring.admin",
        "roles/compute.admin",
        "roles/container.admin"
      ]
    }
    gcp-developers = {
      folder = "development"
      roles = [
        "roles/compute.admin",
        "roles/container.admin"
      ]
    }
  }
  flattened-group-folder-policy = flatten([
      for key, policy in local.groups_folder_policy: [
        for role in policy.roles: {
          folder      = policy.folder
          role        = role
          member      = "group:${key}${local.spinvadorsEmail}"
        }
    ]
  ])
  service_accounts = {
    "example-vpc-host-prod": [{
      group: "gcp-organization-admins"
      service_account: "sa-organization-admins"
    },
    {
      group: "gcp-network-admins"
      service_account: "sa-network-admins"
    },
    {
      group: "gcp-billing-admins"
      service_account: "sa-billing-admins"
    },
    {
      group: "gcp-security-admins"
      service_account: "sa-security-admins"
    }]
    "example-vpc-host-dev": [{
      group: "gcp-devops"
      service_account: "sa-devops"
    },
    {
      group: "gcp-developers"
      service_account: "sa-developers"
    }]
  }
  flatten_service_accounts = flatten([for project, accounts in local.service_accounts: [
    for acc in accounts: merge(acc, {"project": project})
  ]])
  spinvadorsEmail = "@${local.domain}"
}


data "google_organization" "org" {
  domain = local.domain
}

resource "google_cloud_identity_group" "custom_group" {
  for_each = toset(local.groups)

  display_name = each.value
  initial_group_config = "EMPTY"

  parent = "customers/${local.customerId}"

  group_key {
    id = "${each.value}${local.spinvadorsEmail}"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

resource "google_organization_iam_member" "organization_group_roles" {
  for_each = {
    for grp_role in local.flattened_group_org_policy :
          "${grp_role.group}-${grp_role.role}" => grp_role
  }

  org_id  = data.google_organization.org.org_id
  role    = each.value.role
  member = "group:${each.value.group}${local.spinvadorsEmail}"

  depends_on = [google_cloud_identity_group.custom_group]
}

resource "google_folder" "org_folders" {
  for_each = {
    for key, prop in local.folders: key => prop.name if lookup(prop, "parent", "") == ""
  }
  display_name = each.value
  parent       = data.google_organization.org.id
}

resource "google_folder" "org_child_folders" {
  for_each = {
    for key, prop in local.folders: key => {
      for f in google_folder.org_folders: "folder" => {
        name = prop.name
        parent_id = f.id
      } if lookup(prop, "parent", "") == f.display_name
    } if lookup(prop, "parent", "") != ""
  }

  display_name = each.value.folder.name
  parent       = each.value.folder.parent_id

  depends_on = [google_folder.org_folders]
}

resource "google_folder_iam_member" "folder" {
  for_each = {
    for p in local.flattened-group-folder-policy: "${p.folder}-${p.role}-${p.member}" => merge(p, { folder_id: flatten([
        for f in google_folder.org_folders: [
          f.id
        ] if p.folder == f.display_name
      ])
    })
  }

  folder = each.value.folder_id[0]
  role = each.value.role
  member = each.value.member

  depends_on = [google_folder.org_folders]
}

module "projects" {
  source = "../../../../../modules/services/project"

  for_each = {
    for p in local.projects: "${p.folder}-${p.project}" => merge(p, {
      folder_id: flatten([
          for f in google_folder.org_folders: [
            f.id
          ] if p.folder == f.display_name
        ])
    })
  }

  project_name    = each.value.project
  billing_account = var.billing_account
  service_api     = each.value.services
  default_roles   = each.value.roles
  folder_id       = each.value.folder_id[0]
  members         = [
    "group:${each.value.group}${local.spinvadorsEmail}"
  ]
}

resource "google_service_account" "service_account" {
  for_each = {
    for sa in local.flatten_service_accounts: "${sa.project}-${sa.service_account}" => merge(sa, {
      "projectId": [for p in module.projects: p.project_id if p.project_name == sa.project]
    })
  }

  account_id   = each.value.service_account
  display_name = each.value.service_account
  project      = each.value.projectId[0]

  depends_on = [module.projects]
}

resource "google_cloud_identity_group_membership" "group_membership" {

  for_each = {
    for sa in local.flatten_service_accounts: "${sa.project}-${sa.service_account}" => merge(sa, {
      "groudId": [for g in google_cloud_identity_group.custom_group: g.name if g.display_name == sa.group]
    }, {
      "serviceAccountEmail": [for gsa in google_service_account.service_account: gsa.email if gsa.display_name == sa.service_account]
    })
  }

  group    = each.value.groudId[0]

  preferred_member_key {
    id = each.value.serviceAccountEmail[0]
  }

  roles {
    name = "MEMBER"
  }

  depends_on = [google_cloud_identity_group.custom_group, google_service_account.service_account]
}
