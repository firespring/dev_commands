module Dev
  # Class contains methods for requesting a certificate from route53.
  # You must have a hosted zone defined for the desired domain
  class Certificate
    attr_accessor :domains, :email

    def initialize(domains, email)
      @domains = Array(domains)
      @email = email
      raise 'No certificate domains specified' if domains.empty?
    end

    # Request the certificate using the route53 docker image
    # Certificate is stored in /etc/letsencrypt
    def request
      puts
      puts 'Getting SSL Certs For:'
      puts domains.join("\n")
      puts
      puts 'This process can take up to 10 minutes'
      puts
      puts Time.now

      # TODO: Really should use the docker api for this
      cmd = %w(docker run -it --rm --name certbot)
      cmd << '-e' << 'AWS_ACCESS_KEY_ID'
      cmd << '-e' << 'AWS_SECRET_ACCESS_KEY'
      cmd << '-e' << 'AWS_SESSION_TOKEN'
      cmd << '-v' << '/etc/letsencrypt:/etc/letsencrypt'
      cmd << 'certbot/dns-route53:latest'
      cmd << 'certonly'
      cmd << '-n'
      cmd << '--agree-tos'
      cmd << '--dns-route53'
      cmd << '-d' << domains.join(',')
      cmd << '--email' << email
      cmd << '--server' << 'https://acme-v02.api.letsencrypt.org/directory'
      puts cmd.join(' ')
      Dev::Common.new.run_command(cmd)
    end

    # Saves the latest version of the certificate into the given dest_dir
    def save(dest_dir)
      raise "directory #{dest_dir} must be an existing directory" unless File.directory?(dest_dir)

      domain = domains.first.sub(/^\*\./, '')
      directories = Dir.glob("/etc/letsencrypt/live/#{domain}*/")
      no_suffix = directories.delete("/etc/letsencrypt/live/#{domain}/")
      biggest_suffix = directories.max
      source_dir = biggest_suffix || no_suffix
      raise "unable to determine certificate directory for #{domain}" unless source_dir

      FileUtils.cp("#{source_dir}privkey.pem", dest_dir, verbose: true)
      FileUtils.cp("#{source_dir}cert.pem", dest_dir, verbose: true)
      FileUtils.cp("#{source_dir}chain.pem", dest_dir, verbose: true)
      FileUtils.cp("#{source_dir}fullchain.pem", dest_dir, verbose: true)
    end
  end
end
