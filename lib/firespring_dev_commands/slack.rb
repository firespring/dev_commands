require 'slack'

module Dev
  class Slack
    attr_accessor :client

    def initialize
      @client = ::Slack::Web::Client.new
      @client.auth_test
    end

    def post(channel:, text:)
      client.chat_postMessage(channel: channel, text: text)
    end

    def upload(channel:, title:, content:, filename: nil)
      raise 'content should be a string' unless content.is_a?(String)

      client.files_upload(
        channels: channel,
        title: title,
        file: Faraday::UploadIO.new(StringIO.new(content), 'text/plain'),
        filename: filename,
        filetype: 'text'
      )
    end
  end
end
