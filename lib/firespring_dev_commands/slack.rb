require 'slack'

module Dev
  # The main slack class for posting/uploading messages
  class Slack
    # The attribute which contains the underlying slack web client object
    attr_accessor :client

    # Create a new slack web client and make sure it has valid credentials
    def initialize
      @client = ::Slack::Web::Client.new
      @client.auth_test
    end

    # Post the text to the given channel
    def post(channel:, text:)
      client.chat_postMessage(channel:, text:)
    end

    # Upload the text to the give channel as a text file
    def upload_text(channel:, text:, title: 'Text File', filename: 'file.txt')
      raise 'text should be a string' unless text.is_a?(String)

      file = Faraday::UploadIO.new(StringIO.new(text), 'text/plain')
      client.files_upload(channels: channel, title:, file:, filename:, filetype: 'text')
    end
  end
end
