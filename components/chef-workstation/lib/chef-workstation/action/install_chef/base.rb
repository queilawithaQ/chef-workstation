require "chef-workstation/action/base"
require "fileutils"

module ChefWorkstation::Action::InstallChef
  class Base < ChefWorkstation::Action::Base
    MIN_CHEF_VERSION = Gem::Version.new("14.1.1")

    def perform_action
      if target_host.installed_chef_version >= MIN_CHEF_VERSION
        notify(:already_installed)
        return
      end
      @upgrading = true
      perform_local_install
    rescue ChefWorkstation::TargetHost::ChefNotInstalled
      perform_local_install
    end

    def upgrading?
      @upgrading
    end

    def perform_local_install
      package = lookup_artifact()
      notify(:downloading)
      local_path = download_to_workstation(package.url)
      notify(:uploading)
      remote_path = upload_to_target(local_path)
      notify(:installing)
      install_chef_to_target(remote_path)
      notify(:install_complete)
    rescue => e
      msg = e.respond_to?(:message) ? e.message : nil
      notify(:error, msg)
      raise
    end

    def perform_remote_install
      raise NotImplementedError
    end

    def lookup_artifact
      return @artifact_info if @artifact_info
      require "mixlib/install"
      c = train_to_mixlib(target_host.platform)
      Mixlib::Install.new(c).artifact_info
    end

    def train_to_mixlib(platform)
      c = {
        platform_version: platform.release,
        platform: platform.name,
        architecture: platform.arch,
        product_name: "chef",
        version: :latest,
        channel: :stable,
        platform_version_compatibility_mode: true
      }
      @artifact_info = Mixlib::Install.new(c).artifact_info
    end

    def version_to_install
      lookup_artifact.version
    end

    # TODO: Omnitruck has the logic to deal with translaton but
    # mixlib-install is filtering out results incorrectly
    def train_to_mixlib(platform)
      case platform.name
      when /windows/
        c[:platform] = "windows"
      when "redhat", "centos"
        c[:platform] = "el"
      when "amazon"
        c[:platform] = "el"
        if platform.release.to_i > 2010 # legacy Amazon version 1
          c[:platform_version] = "6"
        else
          c[:platform_version] = "7"
        end
      end
      c
    end

    def download_to_workstation(url_path)
      require "chef-workstation/file_fetcher"
      ChefWorkstation::FileFetcher.fetch(url_path)
    end

    def upload_to_target(local_path)
      installer_dir = setup_remote_temp_path()
      remote_path = File.join(installer_dir, File.basename(local_path))
      target_host.upload_file(local_path, remote_path)
      remote_path
    end

    def setup_remote_temp_path
      raise NotImplementedError
    end

    def install_chef_to_target(remote_path)
      raise NotImplementedError
    end
  end
end
