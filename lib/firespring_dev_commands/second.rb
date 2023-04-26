module Dev
  # Class containing constants defining the number of seconds in other frames of time
  class Second
    # Number of seconds in a minute
    PER_MINUTE = 60

    # Number of seconds in an hour
    PER_HOUR = PER_MINUTE * 60

    # Number of seconds in a day
    PER_DAY = PER_HOUR * 24

    # Number of seconds in a week
    PER_WEEK = PER_DAY * 7

    # Number of seconds in a month
    PER_MONTH = PER_DAY * 30

    # Number of seconds in a year
    PER_YEAR = PER_DAY * 365
  end
end
