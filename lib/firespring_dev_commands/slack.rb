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

    def upload_text(channel:, text:, title: 'Text File', filename: 'file.txt')
      raise 'text should be a string' unless text.is_a?(String)

      file = Faraday::UploadIO.new(StringIO.new(text), 'text/plain')
      client.files_upload(channels: channel, title: title, file: file, filename: filename, filetype: 'text')
    end
  end
end
