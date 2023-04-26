module Dev
  class Tar
    # Contains different available pax headers
    # From https://golang.org/src/archive/tar/common.go?s=5701:5766
    module PaxHeader
      # pax atime
      PAX_ATIME = 'atime'.freeze

      # pax charset
      PAX_CHARSET = 'charset'.freeze

      # pax comment
      PAX_COMMENT = 'comment'.freeze

      # pax ctime
      PAX_CTIME = 'ctime'.freeze # please note that ctime is not a valid pax header.

      # pax gid
      PAX_GID = 'gid'.freeze

      # pax gname
      PAX_GNAME = 'gname'.freeze

      # pax linkpath
      PAX_LINKPATH = 'linkpath'.freeze

      # pax mtime
      PAX_MTIME = 'mtime'.freeze

      # pax path
      PAX_PATH = 'path'.freeze

      # pax size
      PAX_SIZE = 'size'.freeze

      # pax uid
      PAX_UID = 'uid'.freeze

      # pax uname
      PAX_UNAME = 'uname'.freeze

      # pax xattr
      PAX_XATTR = 'SCHILY.xattr.'.freeze

      # pax none
      PAX_NONE = ''.freeze
    end
  end
end
