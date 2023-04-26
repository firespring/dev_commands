module Dev
  class Tar
    # Contains different available file types
    # From https://golang.org/src/archive/tar/common.go?s=5701:5766
    module TypeFlag
      # regular file
      TYPE_REG = '0'.freeze

      # regular file
      TYPE_REG_A = '\x00'.freeze

      # hard link
      TYPE_LINK = '1'.freeze

      # symbolic link
      TYPE_SYMLINK = '2'.freeze

      # character device node
      TYPE_CHAR = '3'.freeze

      # block device node
      TYPE_BLOCK = '4'.freeze

      # directory
      TYPE_DIR = '5'.freeze

      # fifo node
      TYPE_FIFO = '6'.freeze

      # reserved
      TYPE_CONT = '7'.freeze

      # extended header
      TYPE_X_HEADER = 'x'.freeze

      # global extended header
      TYPE_X_GLOBAL_HEADER = 'g'.freeze

      # Next file has a long name
      TYPE_GNU_LONG_NAME = 'L'.freeze

      # Next file symlinks to a file w/ a long name
      TYPE_GNU_LONG_LINK = 'K'.freeze

      # sparse file
      TYPE_GNU_SPARSE = 'S'.freeze
    end
  end
end
