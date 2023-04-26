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
    def prune_volumes
      _prune('volumes')
    end

    # Prunes/removes all unused images
    def prune_images
      _prune('images')
    end

    # Private method which actually calls the prune endpoint on the docker api connection
    private def _prune(type)
      response = ::Docker.connection.post("/#{type.downcase}/prune", {})
      format_prune(type, response)
    rescue ::Docker::Error::ServerError => e
      # Specifically check for 'prune already running' error and retry if found
      if /already running/.match?(e.to_s)
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
      LOG.info "Total reclaimed space: #{filesize(info['SpaceReclaimed'])}"
    end

    # Print the given filesize using the most appropriate units
    private def filesize(size)
      return '0.0 B' if size.to_i.zero?

      units = %w(B KB MB GB TB Pb EB)
      exp = (Math.log(size) / Math.log(1024)).to_i
      exp = 6 if exp > 6

      format('%.1f %s', size.to_f / (1024**exp), units[exp])
    end

    # Remove docker images with the "force" option set to true
    # This will remove the images even if they are currently in use and cause unintended side effects.
    def force_remove_images(name_and_tag)
      images = ::Docker::Image.all(filter: name_and_tag)
      ::Docker::Image.remove(images[0].id, force: true) unless images.empty?
    end

    # Calls the docker compose method with the given inputs
    # @deprecated Please use {Docker::Compose#container_by_name} instead
    def container_by_name(service_name, prefix = nil, status: [Docker::Status::RUNNING])
      warn '[DEPRECATION] `Docker#container_by_name` is deprecated.  Please use `Docker::Compose#container_by_name` instead.'
      Docker::Compose.new.container_by_name(service_name, prefix, status)
    end

    # Calls the docker compose method with the given inputs
    # @deprecated Please use {Docker::Compose#mapped_public_port} instead
    def mapped_public_port(name, private_port)
      warn '[DEPRECATION] `Docker#mapped_public_port` is deprecated.  Please use `Docker::Compose#mapped_public_port` instead.'
      Docker::Compose.new.mapped_public_port(name, private_port)
    end

    # Copies the source path on your local machine to the destination path on the container
    def copy_to_container(container, source_path, dest_path)
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
      LOG.info "Copying #{source_path} to #{dest_path}... "

      tar = StringIO.new
      begin
        container.archive_out(source_path) do |chunk|
          tar.write(chunk)
        end
      rescue => e
        raise e if required

        puts 'Not Found'
      end

      Dev::Tar.new(tar).unpack(source_path, dest_path)
    end

    # Display a nicely formatted table of images and their associated information
    def print_images
      reposize   = 70
      tagsize    = 79
      imagesize  = 15
      createsize = 20
      sizesize   = 10
      total = reposize + tagsize + imagesize + createsize + sizesize

      # If there is additional width available, add it to the repo and tag columns
      additional = [((Rake.application.terminal_width - total) / 2).floor, 0].max
      reposize += additional
      tagsize += additional

      format = "%-#{reposize}s%-#{tagsize}s%-#{imagesize}s%-#{createsize}s%s"
      puts format(format, :REPOSITORY, :TAG, :'IMAGE ID', :CREATED, :SIZE)
      ::Docker::Image.all.each do |image|
        image_info(image).each do |repo, tag, id, created, size|
          puts format(format, repo, tag, id, created, size)
        end
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # Take the given image and grab all of the parts of it which will be used to display the image info
    private def image_info(image)
      [].tap do |ary|
        id = image.info&.dig('id')&.split(':')&.last&.slice(0..11)
        created = timesince(Time.at(image.info&.dig('Created')))
        size = filesize(image.info&.dig('Size'))

        repo_urls = image.info&.dig('RepoTags')
        repo_urls ||= ["#{image.info&.dig('RepoDigests')&.first&.split(':')&.first&.split('@')&.first}:<none>"]
        repo_urls.each do |repo_url|
          repo, tag = repo_url.split(':')
          tag ||= '<none>'
          ary << [repo, tag, id, created, size]
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    # Display a nicely formatted table of containers and their associated information
    def print_containers
      idsize = 15
      imagesize = 25
      commandsize = 25
      createsize = 17
      statussize = 16
      portsize = 25
      namesize = 10
      total = idsize + imagesize + commandsize + createsize + statussize + portsize + namesize

      # If there is additional width available, add it to the repo and tag columns
      additional = [((Rake.application.terminal_width - total) / 2).floor, 0].max
      imagesize += additional
      portsize += additional

      format = "%-#{idsize}s%-#{imagesize}s%-#{commandsize}s%-#{createsize}s%-#{statussize}s%-#{portsize}s%s"
      puts format(format, :'CONTAINER ID', :IMAGE, :COMMAND, :CREATED, :STATUS, :PORTS, :NAMES)
      ::Docker::Container.all.each do |container|
        id, image, command, created, status, ports, names = container_info(container)
        puts format(format, id, image, command, created, status, ports, names)
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # Take the given container and grab all of the parts of it which will be used to display the container info
    private def container_info(container)
      id = container.id&.slice(0..11)
      image = container.info&.dig('Image')

      command = container.info&.dig('Command')&.truncate(20)
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

      [id, image, command, created, status, ports, names]
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
