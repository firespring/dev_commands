require 'httparty'

class TargetProcess
  include HTTParty

  SBF_PROJECT_ID=217

  @max_results = 1000
  @ateam_id = 19003
  @thundercats_id = 19002
  @thundercats_current_velocity = 0
  @design_id = 20749
  @sbf_qa_id = 20750
  @sbf_role_id = 10
  @sbf_projects = ['infrastructure', 'St Baldricks']
  @tp_url = ENV['TP_URL'] || 'https://sbf.tpondemand.com'
  @tp_api_url = "#{@tp_url}/api/v1"

  @default_options = {
    basic_auth: {
      username: ENV['TP_USERNAME'],
      password: ENV['TP_PASSWORD']
    },
    headers: {
      'Content-Type' => 'application/json'
    }
  }

  base_uri @tp_api_url

  def self.max_results
    @max_results
  end

  def self.ateam_id
    @ateam_id
  end

  def self.thundercats_id
    @thundercats_id
  end

  def self.design_id
    @design_id
  end

  def self.sbf_qa_id
    @sbf_qa_id
  end

  def self.sbf_role_id
    @sbf_role_id
  end

  def self.sbf_projects
    @sbf_projects
  end

  def self.get_helper(url, query)
    options = {query: query.generate}
    options.merge!(@default_options)
    response = get(url, options)

    raise "Error querying #{@tp_url} [#{options.inspect}]: #{response.inspect}" unless response.response.is_a?(Net::HTTPOK)
    return response.parsed_response unless response.parsed_response.include?('Items')

    result = response.parsed_response['Items']
    while response['Next'] do
      response = get(response['Next'], @default_options)
      raise "Error querying #{@tp_url}: #{response.inspect}" unless response.response.is_a?(Net::HTTPOK)
      result.concat(response.parsed_response['Items'])
    end

    result
  end

  def self.parse_dot_net_time(string)
    Time.at(string.slice(6, 10).to_i)
  end

  def self.parse_dot_net_date(string)
    parse_dot_net_time(string).to_date
  end

  def self.truncate(string)
    return "#{string[0...37]}..." if string.length > 37
    (string + ' ' * 40)[0, 40]
  end
end
