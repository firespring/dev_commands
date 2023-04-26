require 'json'
require 'net/http'
require 'uri'

module Dev
  class Php
    # Class which contains commands and customizations for security audit reports
    class Audit
      attr_accessor :data

      def initialize(data)
        @data = JSON.parse(Dev::Common.new.strip_non_json(data))
      end

      # Convert the php audit data to the standardized audit report object
      def to_report
        Dev::Audit::Report.new(
          data['advisories'].map do |_, v|
            v.map do |it|
              Dev::Audit::Report::Item.new(
                id: it['advisoryId'],
                name: it['packageName'],
                severity: severity(it['cve']),
                title: it['title'],
                url: it['link'],
                version: it['affectedVersions']
              )
            end
          end.flatten
        )
      end

      # Takes the give CVE number and looks it up on the NIST api
      # Returns the highest severity reported (worst case scneario)
      def severity(cve)
        # Sleep to make sure we don't get rate limited
        sleep(6)
        url = "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=#{cve}"
        response = Net::HTTP.get_response(URI.parse(url))

        # If we can't talk to NIST, just assume the worst at 'unknown'
        raise "#{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

        # Get the cve data out of the json body
        cve_data = JSON.parse(response.body)['vulnerabilities'].first['cve']

        # Sanity check to make sure it gave us the correct information
        raise 'returned cve did not matche expected' unless cve == cve_data['id']

        # Find the max cvss reported for this vulnerability
        max_cvss = cve_data['metrics']['cvssMetricV31']&.map { |it| it['cvssData']['baseScore'] }&.max.to_f

        # Map that severity to the correct level
        cvss_to_severity(max_cvss)
      rescue => e
        LOG.error("Error looking up severity for #{cve}: #{e.message}")
        LOG.error('WARNING: Unable to determine severity - ignoring with UNKNOWN')
        Dev::Audit::Report::Level::UNKNOWN
      end

      # Take a given cvss scrore and map it to a severity string
      def cvss_to_severity(score)
        return Dev::Audit::Report::Level::LOW if score <= 3.9
        return Dev::Audit::Report::Level::MODERATE if score <= 6.9
        return Dev::Audit::Report::Level::HIGH if score <= 8.9

        Dev::Audit::Report::Level::CRITICAL
      end
    end
  end
end
