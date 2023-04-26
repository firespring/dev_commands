module Dev
  class Audit
    class Report
      # This class contains audit report items and their associated data
      class Item
        attr_accessor :id, :name, :title, :url, :severity, :version

        def initialize(id:, name:, title:, url:, severity:, version:)
          @id = id
          @name = name
          @title = title
          @url = url
          @severity = severity
          @version = version
        end

        # Returns a string representation of this audit report item
        def to_s
          [
            '+-------------------+----------------------------------------------------------------------------------+',
            format('| %s | %-80s |', format('%-17s', 'Severity').green, severity),
            format('| %s | %-80s |', format('%-17s', 'Package').green, name),
            format('| %s | %-80s |', format('%-17s', 'Id').green, id),
            format('| %s | %-80s |', format('%-17s', 'Title').green, title),
            format('| %s | %-80s |', format('%-17s', 'URL').green, url),
            format('| %s | %-80s |', format('%-17s', 'Affected versions').green, version),
            '+-------------------+----------------------------------------------------------------------------------+'
          ].join("\n")
        end
      end
    end
  end
end
