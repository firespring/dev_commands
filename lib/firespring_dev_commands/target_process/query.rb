module Dev
  class TargetProcess
    class Query
      attr_accessor :where, :incl, :take

      def initialize
        @where = []
        @incl = []
        @take = 250
      end

      def <<(item)
        where << item
      end

      def where=(item)
        if item.is_a?(Array)
          where.concat(item)
        else
          where << item
        end
      end

      def include=(item)
        if item.is_a?(Array)
          incl.concat(item)
        else
          incl << item
        end
      end

      def generate
        {}.tap { |clause|
          clause[:where] = where.join(' and ') unless where.nil? || where.empty?
          clause[:include] = "[#{incl.join(',')}]" unless incl.nil? || incl.empty?
          clause[:take] = take if take.to_i.positive?
        }
      end

      def to_s
        generate
      end
    end
  end
end
