#
# Copyright:: Copyright Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "chef-workstation-app"
license "Apache-2.0"
skip_transitive_dependency_licensing
license_file "LICENSE"

# These three lines are updated automatically by Expeditor
default_version "0.2.99"
source sha1: "a427e6ac7acba19d34b2949c5397dfa6f538ca72" if windows?
source sha1: "185180880bbd9ad0aa9a5b9a213fde7e1a594d06" if linux?

platform_name = if macos?
                  "darwin"
                elsif windows?
                  "win32"
                else
                  "linux"
                end

source_url = "https://packages.chef.io/files/unstable/chef-workstation-app/#{version}/chef-workstation-app-#{version}-#{platform_name}.zip"
app_install_path = "#{install_dir}/components/chef-workstation-app"

# These electron dependencies are pulled in/created
# by this build. They may have dependencies that aren't met
# on the install target - in which case the tray application
# will not be runnable.  That does not affect the rest of
# the chef-workstation installation, so we will whitelist the
# dependencies to allow it to continue in any case.
if linux?
  whitelist_file(%r{components/chef-workstation-app/libGLESv2\.so})
  whitelist_file(%r{components/chef-workstation-app/chef-workstation-app})
end

# The macOS zip file is weird. We can't really expand it because it expands directly into the .app.
# To get around this we download it as a zip and unzip it as part of postinst.
if macos?
  build do
    mkdir app_install_path
    command "curl -Lsf -o #{app_install_path}/chef-workstation-app-mac.zip #{source_url}"
  end
else
  source url: source_url

  build do
    mkdir app_install_path
    copy "#{project_dir}/*", app_install_path
  end
end



