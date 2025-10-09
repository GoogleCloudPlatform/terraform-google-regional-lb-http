/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  per_module_roles = {
    root = [
      "roles/storage.admin",
      "roles/compute.admin",
      "roles/run.admin",
      "roles/iam.serviceAccountUser",
      "roles/certificatemanager.owner",
      "roles/vpcaccess.admin",
      "roles/iam.serviceAccountAdmin"
    ]
    backend = [
      "roles/storage.admin",
      "roles/compute.admin",
      "roles/run.admin",
      "roles/iam.serviceAccountUser",
      "roles/certificatemanager.owner",
      "roles/vpcaccess.admin",
      "roles/iam.serviceAccountAdmin",
      "roles/iap.admin"
    ]
    frontend = [
      "roles/storage.admin",
      "roles/compute.admin",
      "roles/run.admin",
      "roles/iam.serviceAccountUser",
      "roles/certificatemanager.owner",
      "roles/vpcaccess.admin",
      "roles/iam.serviceAccountAdmin"
    ]
  }

  extra_project_roles_for_tests = {}

  // Applied to all service accounts.
  extra_required_folder_roles_for_tests = [
    "roles/compute.xpnAdmin"
  ]

  // A list of items like:
  // { module_name = "x", project_role = "role1"}
  // { module_name = "x", project_role = "role2"}
  // { module_name = "y", project_role = "role3"}
  module_role_combinations = flatten(
    [for module_name, _ in module.project :
      [for role in setunion(local.per_module_roles[module_name], lookup(local.extra_project_roles_for_tests, module_name, [])) : {
        module_name  = module_name
        project_role = role
        }
      ]
    ]
  )
  module_folder_role_combinations = flatten(
    [for module_name, _ in module.project :
      [for role in extra_required_folder_roles_for_tests : {
        module_name = module_name
        folder_role = role
        }
      ]
    ]
}

resource "google_service_account" "int_test" {
  for_each = module.project

  project      = each.value.project_id
  account_id   = "ci-account"
  display_name = "ci-account"
}

resource "google_folder_iam_member" "int_test" {
  for_each = {
    for combination in local.module_folder_role_combinations :
    "${combination.module_name}.${combination.folder_role}" => {
      service_account = google_service_account.int_test[combination.module_name]
      folder_role     = combination.folder_role
    }
  }

  folder = "folders/${var.folder_id}"
  role   = each.value.folder_role
  member = "serviceAccount:${each.value.service_account.email}"
}

resource "google_project_iam_member" "int_test" {
  for_each = {
    for combination in local.module_role_combinations :
    "${combination.module_name}.${combination.project_role}" => {
      service_account = google_service_account.int_test[combination.module_name]
      project_role    = combination.project_role
    }
  }

  project = each.value.service_account.project
  role    = each.value.project_role
  member  = "serviceAccount:${each.value.service_account.email}"
}

resource "google_service_account_key" "int_test" {
  for_each = module.project

  service_account_id = google_service_account.int_test[each.key].id
}
