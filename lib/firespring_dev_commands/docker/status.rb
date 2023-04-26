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
    end
  end
end
