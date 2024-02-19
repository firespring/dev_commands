module Dev
  class Docker
    # Class containing constants for docker status names and groups
    class Status
      # Docker created status name
      CREATED = :created

      # Docker restarting status name
      RESTARTING = :restarting

      # Docker running status name
      RUNNING = :running

      # Docker removing status name
      REMOVING = :removing

      # Docker paused status name
      PAUSED = :paused

      # Docker exited status name
      EXITED = :exited

      # Docker dead status name
      DEAD = :dead

      # Array containing all available docker statuses
      ALL = [
        CREATED,
        RESTARTING,
        RUNNING,
        REMOVING,
        PAUSED,
        EXITED,
        DEAD
      ].freeze

      # TODO: Can we use 'curses' here and overwrite the correct line?
      def response_callback(response)
        response.split("\n").each do |line|
          data = JSON.parse(line)
          if data.include?('status')
            if data['id']
              LOG.info "#{data['id']}: #{data['status']}"
            else
              LOG.info (data['status']).to_s
            end
          elsif data.include?('errorDetail')
            raise data['errorDetail']['message']
          elsif data.include?('aux')
            next
          else
            raise "Unrecognized message from docker: #{data}"
          end
        end
      end
    end
  end
end
