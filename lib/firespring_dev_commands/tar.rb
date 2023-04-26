require 'fileutils'

module Dev
  # Class for natively un-tar'ing a file in ruby
  class Tar
    attr_accessor :data

    def initialize(data = nil)
      @data = data
    end

    # Unpack all data in the given tar into the dest_path
    def unpack(source_path, dest_path)
      data.rewind
      extended_headers = nil
      ::Gem::Package::TarReader.new(data).each do |entry|
        # Using https://github.com/kr/tarutil/blob/master/untar.go as a template
        # Also check out https://go.googlesource.com/go/+/master/src/archive/tar/reader.go?autodive=0%2F%2F%2F
        case entry.header.typeflag
        when TypeFlag::TYPE_DIR
          merge_pax(entry, extended_headers)
          dest_name = calc_dest_name(source_path, dest_path, entry)
          create_directory(entry, dest_name)

        when TypeFlag::TYPE_REG, TypeFlag::TYPE_REG_A
          merge_pax(entry, extended_headers)
          dest_name = calc_dest_name(source_path, dest_path, entry)
          create_file(entry, dest_name)

        when TypeFlag::TYPE_LINK
          raise 'Unimplemented file type: Link'

        when TypeFlag::TYPE_SYMLINK
          merge_pax(entry, extended_headers)
          dest_name = calc_dest_name(source_path, dest_path, entry)
          create_symlink(entry, dest_name)

        when TypeFlag::TYPE_X_HEADER
          extended_headers = parse_pax(entry.read)
          next

        when TypeFlag::TYPE_CONT, TypeFlag::TYPE_X_GLOBAL_HEADER
          raise 'Unimplemented file type Cont/XGlobalHeader'

        when TypeFlag::TYPE_CHAR, TypeFlag::TYPE_BLOCK, TypeFlag::TYPE_FIFO
          raise 'Unimplemented file type: Char/Block/Fifo'

        else
          raise 'Unrecognized file type'

        end

        # If we got here we should be done with any extended headers
        extended_headers = nil
      end
    end

    # Extract headers and keep track as we extract the files using the given headers
    private def parse_pax(content)
      extended_headers = {}
      key, value = parse_pax_record(content)
      extended_headers[key] = value
      extended_headers
    end

    # Parse the PAX record and return the results
    private def parse_pax_record(content)
      # Check https://golang.org/src/archive/tar/strconv.go
      _size, keyvalue = content&.split(' ', 2)
      key, value = keyvalue&.split('=', 2)
      [key, value]
    end

    # Calculate what the appropriate destination file name is
    private def calc_dest_name(source_path, dest_path, entry)
      if File.directory?(dest_path)
        dest_path = File.dirname(dest_path) if File.basename(source_path) == File.basename(dest_path)

        return "#{dest_path.chomp('/')}/#{entry.full_name}".strip if File.directory?(dest_path)
      end

      old_name = File.basename(source_path)
      entry.full_name.sub(/^#{old_name}/, dest_path).to_s.strip
    end

    # Create the directory and leading directories
    private def create_directory(_entry, dest_name)
      FileUtils.mkdir_p(dest_name)
    end

    # Write the file contents to the destination
    private def create_file(entry, dest_name)
      FileUtils.mkdir_p(File.dirname(dest_name))
      File.write(dest_name, entry.read)
    end

    # Create a symlink to the destination
    private def create_symlink(entry, dest_name)
      FileUtils.cd(File.dirname(dest_name)) do
        FileUtils.mkdir_p(File.dirname(entry.header.linkname))
        FileUtils.symlink(entry.header.linkname, File.basename(dest_name), force: true)
      end
    end

    # Merge pax records
    private def merge_pax(entry, extended_headers)
      # Reference: https://go.googlesource.com/go/+/master/src/archive/tar/reader.go?autodive=0%2F%2F%2F
      return unless extended_headers

      extended_headers.each do |k, v|
        case k
        when PaxHeader::PAX_PATH
          entry.header.instance_variable_set(:@name, v)

        when PaxHeader::PAX_LINKPATH
          entry.header.instance_variable_set(:@linkname, v)

        when PaxHeader::PAX_UNAME
          entry.header.instance_variable_set(:@uname, v)

        when PaxHeader::PAX_GNAME
          entry.header.instance_variable_set(:@gname, v)

        when PaxHeader::PAX_UID
          entry.header.instance_variable_set(:@uid, v)

        when PaxHeader::PAX_GID
          entry.header.instance_variable_set(:@gid, v)

        when PaxHeader::PAX_ATIME
          entry.header.instance_variable_set(:@atime, v)

        when PaxHeader::PAX_MTIME
          entry.header.instance_variable_set(:@mtime, v)

        when PaxHeader::PAX_CTIME
          entry.header.instance_variable_set(:@ctime, v)

        when PaxHeader::PAX_SIZE
          entry.header.instance_variable_set(:@size, v)

        else
          raise "unsupported header #{k}"

        end
      end
    end
  end
end
