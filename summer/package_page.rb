#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/templated_page'
require 'summer/repository_summary'

class PackagePage < TemplatedPage
    include Summer::RepositorySummary

    def initialize pkg_name
        super "packages/" + pkg_name
        @pkg_name = pkg_name
        @ids = []
        @repositories = {}
    end

    def page_title
        return @pkg_name
    end

    def self.content_template_filename
        return "summer/package_page.rhtml"
    end

    def self.get_template_variables_hash
        {
            :summary               => :make_summary,
            :platforms             => :get_interesting_platforms,
            :ids_by_slot           => :get_ids_by_slot,
            :slot                  => :get_id_slot,
            :version               => :get_id_version,
            :repository            => :get_id_repository,
            :id_class              => :make_id_class,
            :platform_class        => :make_platform_class,
            :platform_text         => :get_platform_text,
            :repository_href       => :make_repository_href,
            :repository_summary    => :make_repository_summary_by_id,
            :repository_class      => :make_repository_class,
            :metadata_keys         => :get_interesting_metadata_keys,
            :key_value             => :metadata_key_value_to_html,
            :choices               => :get_interesting_choices,
            :choice_name           => :get_choice_name,
            :choice_values         => :get_choice_values,
            :choice_value_name     => :get_choice_value_name,
            :choice_value_desc     => :get_choice_value_description
        }
    end

    def top_uri
        return "../../../"
    end

    def add_id id
        @ids << id
    end

    def add_repository repo
        @repositories[repo.name] = repo
    end

    def make_summary
        best_id = get_best_id
        if best_id.short_description_key
            best_id.short_description_key.parse_value.sub(/\.$/, '')
        else
            @pkg_name.to_s
        end
    end

    def get_best_id
        @ids.max_by do | id |
            [ id.version.is_scm? ? 0 : 1 , id.version ]
        end
    end

    def get_interesting_platforms
        Platforms.sort
    end

    def get_id_slot id
        if id.slot_key
            id.slot_key.parse_value
        else
            "?"
        end
    end

    def get_id_repository id
        id.repository_name
    end

    def get_id_version id
        id.version
    end

    def get_ids_by_slot
        h = {}
        @ids.each do | id |
            (h[get_id_slot(id)] ||= []) << id
        end

        result = []
        h.keys.sort_by do | slot |
            h[slot].max_by do | id |
                id.version
            end.version
        end.reverse.each do | slot |
            result << h[slot].sort_by do | id |
                id.version
            end.reverse
        end

        result
    end

    def make_repository_href id
        return top_uri + "repositories/" + id.repository_name + "/index.html"
    end

    def make_repository_summary_by_id id
        make_repository_summary id.repository_name
    end

    def make_repository_class id
        repo = @repositories[id.repository_name]
        status_key = repo['status']
        if status_key
            "repo-status-" + status_key.parse_value
        else
            ""
        end
    end

    def make_id_class id
        if id == get_best_id
            "best-id"
        else
            ""
        end
    end

    def get_platform_text id, platform
        return platform + "?" unless id.keywords_key
        if id.keywords_key.parse_value.include? platform
            return platform
        elsif id.keywords_key.parse_value.include?("~" + platform)
            return "~" + platform
        elsif id.keywords_key.parse_value.include?("-*")
            return "-*"
        elsif id.keywords_key.parse_value.include?("-" + platform)
            return "-" + platform
        else
            return platform + "?"
        end
    end

    def make_platform_class id, platform
        return "platform-unkeyworded" unless id.keywords_key
        if id.keywords_key.parse_value.include? platform
            return "platform-stable"
        elsif id.keywords_key.parse_value.include?("~" + platform)
            return "platform-unstable"
        elsif id.keywords_key.parse_value.include?("-*") or id.keywords_key.parse_value.include?("-" + platform)
            return "platform-disabled"
        else
            return "platform-unkeyworded"
        end
    end

    def is_interesting_key? id, key
        case key.type
        when MetadataKeyType::Significant, MetadataKeyType::Normal, MetadataKeyType::Dependencies
            not key.raw_name == id.choices_key.raw_name
        when MetadataKeyType::Internal
            key.raw_name == "LICENCES"
        else
            false
        end
    end

    def get_interesting_metadata_keys
        result = []
        id = get_best_id
        id.each_metadata do | key |
            result << key if is_interesting_key? id, key
        end
        result.sort_by do | key |
            [ key.type, key.human_name ]
        end
    end

    def get_interesting_choices
        id = get_best_id
        result = []

        if id.choices_key
            id.choices_key.parse_value.each do | choice |
                next if choice.hidden?
                next if choice.human_name == "Build Options"

                c = [ choice, [] ]
                choice.each do | value |
                    next unless value.origin == ChoiceOrigin::Explicit
                    c.last << value
                end
                result << c unless c.last.empty?
            end
        end

        result
    end

    def get_choice_name s
        s.first.human_name
    end

    def get_choice_values s
        s.last
    end

    def get_choice_value_name c
        c.unprefixed_name
    end

    def get_choice_value_description c
        c.description
    end
end

