#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'

class RepositoryPage < TemplatedPage
    def initialize repo
        super "repositories/" + repo.name
        @repository = repo
    end

    def page_title
        return @repository.name
    end

    def self.content_template_filename
        return "summer/repository_page.rhtml"
    end

    def self.get_template_variables_hash
        {
            :metadata_keys             => :get_interesting_metadata_keys,
            :summary                   => :get_summary_key_value,
            :key_value                 => :metadata_key_value_to_html
        }
    end

    def top_uri
        return "../../"
    end

    def is_interesting_key? key
        if key.type == MetadataKeyType::Significant
            not %w{location summary}.include? key.human_name
        else
            %w{sync}.include? key.human_name
        end
    end

    def get_interesting_metadata_keys
        result = []
        @repository.each_metadata do | key |
            result << key if is_interesting_key? key
        end
        result.sort_by do | key |
            [ key.type, key.human_name ]
        end
    end

    def get_summary_key_value
        if @repository['summary']
            @repository['summary'].value
        else
            nil
        end
    end
end

