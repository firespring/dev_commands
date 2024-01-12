require 'docker'
require 'json'

# TODO: Make these configurable?
# Set docker write timeout to 1 hour
Excon.defaults[:write_timeout] = 3600

# Set docker read timeout to 1 hour
Excon.defaults[:read_timeout] = 3600

module Dev
  # Class contains many useful methods for interfacing with the docker api
  class Docker
    # Config object for setting top level docker config options
    Config = Struct.new(:min_version, :max_version) do
      def initialize
        self.min_version = nil
        self.max_version = nil
      end
    end

    class << self
      # Instantiates a new top level config object if one hasn't already been created
      # Yields that config object to any given block
      # Returns the resulting config object
      def config
        @config ||= Config.new
        yield(@config) if block_given?
        @config
      end

      # Alias the config method to configure for a slightly clearer access syntax
      alias_method :configure, :config

      # Returns the version of the docker engine running on the system
      def version
        @version ||= JSON.parse(::Docker.connection.get('/version'))['Version']
      end
    end

    def initialize
      check_version
    end

    # Checks the min and max version against the current docker version if they have been configured
    def check_version
      min_version = self.class.config.min_version
      raise "requires docker version >= #{min_version} (found #{self.class.version})" if min_version && !Dev::Common.new.version_greater_than(min_version, self.class.version)

      max_version = self.class.config.max_version
      raise "requires docker version < #{max_version} (found #{self.class.version})" if max_version && Dev::Common.new.version_greater_than(max_version, self.class.version)
    end

    # Prunes/removes all unused containers, networks, volumes, and images
    def prune
      prune_containers
      prune_networks
      prune_volumes
      prune_images
    end

    # Prunes/removes all unused containers
    def prune_containers
      _prune('containers')
    end

    # Prunes/removes all unused networks
    def prune_networks
      _prune('networks')
    end

    # Prunes/removes all unused volumes
    # Specify ALL_VOLUMES=false in your environment to only clean anonymous volumes (docker version 23.x+)
    def prune_volumes
      opts = {}
      opts[:filters] = {all: ['true']}.to_json if Dev::Common.new.version_greater_than('22.9999.0', self.class.version) && ENV['ALL_VOLUMES'].to_s.strip != 'false'
      _prune('volumes', opts:)
    end

    def prune_project_volumes(project_name:)
      project_name = project_name.to_s.strip
      raise 'No project name defined' if project_name.empty?

      ::Docker::Volume.all.each do |volume|
        next unless volume.info['Name'].start_with?(project_name)

        begin
          volume.remove
          LOG.info "Removed volume #{volume.id[0, 12]}"
        rescue => e
          LOG.error "Error removing volume #{volume.id[0, 12]}: #{e}"
        end
      end
    end

    # Prunes/removes all unused images
    def prune_images
      _prune('images')
    end

    # Private method which actually calls the prune endpoint on the docker api connection
    private def _prune(type, opts: {})
      response = ::Docker.connection.post("/#{type.downcase}/prune", opts)
      format_prune(type, response)
    rescue ::Docker::Error::ServerError => e
      # Specifically check for 'prune already running' error and retry if found
      if e.to_s.include?('already running')
        sleep 2
        retry
      end
      raise
    end

    # Callback method which formats the output from the prune method to give details on what was cleaned and how much space was reclaimed
    private def format_prune(type, response)
      info = JSON.parse(response)
      type = type.capitalize

      LOG.info "\nDeleted #{type.capitalize}"
      deleted_items = info["#{type}Deleted"] || []
      deleted_items.each { |it| LOG.info "  #{it}" }
      LOG.info "Total reclaimed space: #{Dev::Common.new.filesize(info['SpaceReclaimed'])}"
    end

    # Remove docker images with the "force" option set to true
    # This will remove the images even if they are currently in use and cause unintended side effects.
    def force_remove_images(name_and_tag)
      images = ::Docker::Image.all(filter: name_and_tag)
      ::Docker::Image.remove(images[0].id, force: true) unless images.empty?
    end

    # Gets the default working dir of the container
    def working_dir(container)
      container.json['Config']['WorkingDir']
    end

    # Copies the source path on your local machine to the destination path on the container
    def copy_to_container(container, source_path, dest_path)
      dest_path = File.join(working_dir(container), dest_path) unless dest_path.start_with?(File::SEPARATOR)
      LOG.info "Copying #{source_path} to #{dest_path}... "

      container.archive_in(source_path, dest_path, overwrite: true)
      return unless File.directory?(source_path)

      dest_file = File.basename(source_path)
      # TODO: Can we find a better solution for this? Seems pretty brittle
      retcode = container.exec(['bash', '-c', "cd #{dest_path}; tar -xf #{dest_file}; rm -f #{dest_file}"])[-1]
      raise 'Unable to unpack on container' unless retcode.zero?
    end

    # Copies the source path on the container to the destination path on your local machine
    # If required is set to true, the command will fail if the source path does not exist on the container
    def copy_from_container(container, source_path, dest_path, required: true)
      source_path = File.join(working_dir(container), source_path) unless source_path.start_with?(File::SEPARATOR)
      LOG.info "Copying #{source_path} to #{dest_path}... "

      tar = StringIO.new
      begin
        container.archive_out(source_path) do |chunk|
          tar.write(chunk)
        end
      rescue => e
        raise e if required

        puts "#{source_path} Not Found"
      end

      Dev::Tar.new(tar).unpack(source_path, dest_path)
    end

    # rubocop:disable Metrics/ParameterLists
    # Display a nicely formatted table of images and their associated information
    def print_images
      reposize   = 70
      tagsize    = 70
      archsize   = 9
      imagesize  = 15
      createsize = 20
      sizesize   = 10
      total = reposize + tagsize + archsize + imagesize + createsize + sizesize

      # If there is additional width available, add it to the repo and tag columns
      additional = [((Rake.application.terminal_width - total) / 2).floor, 0].max
      reposize += additional
      tagsize += additional

      format = "%-#{reposize}s%-#{tagsize}s%-#{archsize}s%-#{imagesize}s%-#{createsize}s%s"
      puts format(format, :REPOSITORY, :TAG, :ARCH, :'IMAGE ID', :CREATED, :SIZE)
      ::Docker::Image.all.each do |image|
        image_info(image).each do |repo, tag, arch, id, created, size|
          puts format(format, repo, tag, arch, id, created, size)
        end
      end
    end
    # rubocop:enable Metrics/ParameterLists

    # rubocop:disable Metrics/CyclomaticComplexity
    # Take the given image and grab all of the parts of it which will be used to display the image info
    private def image_info(image)
      [].tap do |ary|
        arch = image.json&.dig('Architecture')
        variant = image.json&.dig('Variant')
        arch = "#{arch}/#{variant}" if variant
        id = image.info&.dig('id')&.split(':')&.last&.slice(0..11)
        created = timesince(Time.at(image.info&.dig('Created')))
        size = Dev::Common.new.filesize(image.info&.dig('Size'))

        repo_urls = image.info&.dig('RepoTags')
        repo_urls ||= ["#{image.info&.dig('RepoDigests')&.first&.split(':')&.first&.split('@')&.first}:<none>"]
        repo_urls.each do |repo_url|
          repo, tag = repo_url.split(':')
          tag ||= '<none>'
          ary << [repo, tag, arch, id, created, size]
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Display a nicely formatted table of containers and their associated information
    def print_containers
      idsize = 15
      imagesize = 20
      archsize = 7
      commandsize = 20
      createsize = 15
      statussize = 15
      portsize = 20
      namesize = 16
      total = idsize + imagesize + archsize + commandsize + createsize + statussize + portsize + namesize

      # If there is additional width available, add it to the repo and tag columns
      additional = [((Rake.application.terminal_width - total) / 3).floor, 0].max

      # If there's enough extra, give some to the name as well
      if additional > 40
        namesize += 15
        additional -= 5
      end
      imagesize += additional
      commandsize += additional
      portsize += additional

      format = "%-#{idsize}s%-#{imagesize}s%-#{archsize}s%-#{commandsize}s%-#{createsize}s%-#{statussize}s%-#{portsize}s%-#{namesize}s"
      puts format(format, :'CONTAINER ID', :IMAGE, :ARCH, :COMMAND, :CREATED, :STATUS, :PORTS, :NAMES)
      ::Docker::Container.all.each do |container|
        id, image, arch, command, created, status, ports, names = container_info(container)
        puts format(format, id, image.truncate(imagesize - 5), arch, command.truncate(commandsize - 5), created, status, ports.truncate(portsize - 5), names)
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # Take the given container and grab all of the parts of it which will be used to display the container info
    private def container_info(container)
      id = container.id&.slice(0..11)
      image = container.info&.dig('Image')
      image_json = ::Docker::Image.get(image).json
      arch = image_json&.dig('Architecture')
      variant = image_json&.dig('Variant')
      arch = "#{arch}/#{variant}" if variant
      command = container.info&.dig('Command')
      created = timesince(Time.at(container.info&.dig('Created')))
      status = container.info&.dig('Status')

      ports = container.info&.dig('Ports')&.map do |port_info|
        ip = port_info['IP']
        private_port = port_info['PrivatePort']
        public_port = port_info['PublicPort']
        type = port_info['Type']
        next "#{private_port}/#{type}" unless ip && public_port

        "#{ip}:#{public_port}->#{private_port}/#{type}"
      end&.join(', ')
      names = container.info&.dig('Names')&.map { |name| name.split('/').last }&.join(', ')

      [id, image, arch, command, created, status, ports, names]
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Print the time since the given time in the most appropriate unit
    private def timesince(time)
      return '' unless time && time.is_a?(Time)

      time_since = (Time.now - time).to_i
      return "#{time_since} seconds ago" if time_since <= Dev::Second::PER_MINUTE
      return "#{(time_since / Dev::Second::PER_MINUTE).ceil} minutes ago" if time_since <= Dev::Second::PER_HOUR
      return "#{(time_since / Dev::Second::PER_HOUR).ceil} hours ago" if time_since <= Dev::Second::PER_DAY
      return "#{(time_since / Dev::Second::PER_DAY).ceil} days ago" if time_since <= Dev::Second::PER_WEEK
      return "#{(time_since / Dev::Second::PER_WEEK).ceil} weeks ago" if time_since <= Dev::Second::PER_MONTH
      return "#{(time_since / Dev::Second::PER_MONTH).ceil} months ago" if time_since <= Dev::Second::PER_YEAR

      "#{(time_since / Dev::Second::PER_YEAR).ceil} years ago"
    end
  end
end
