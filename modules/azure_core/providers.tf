# /*
# Copyright (c) 2024 Dell Inc., or its subsidiaries. All Rights Reserved.

# Licensed under the Mozilla Public License Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://mozilla.org/MPL/2.0/


# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# */

terraform {
  required_version = ">=1.5.0"

  required_providers {
    powerflex = {
      version = "1.6.0"
      source  = "registry.terraform.io/dell/powerflex"
    }
  }
}

provider "powerflex" {
  username = var.username
  password = var.password
  endpoint = var.endpoint
  insecure = var.insecure
  timeout  = 120

  ## The provider can also be set using environment variables
  ## If environment variables are set it will override this configuration
  ## Example environment variables
  # POWERFLEX_USERNAME="username"
  # POWERFLEX_PASSWORD="password"
  # POWERFLEX_ENDPOINT="https://yourhost.host.com"
  # POWERFLEX_INSECURE="true"
  # POWERFLEX_TIMEOUT="120"
}

