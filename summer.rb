#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'getoptlong'

require 'summer/index_page'
require 'summer/repository_page'
require 'summer/category_page'
require 'summer/package_page'
require 'summer/repology_page'
require 'summer/legacy'
require 'Paludis'

include Paludis

envspec = ":summer"
OutputDir = "./output/"
ExtraFiles = %w[summer.css zebrapig-headbox.png]
Platforms = %w[amd64 arm armv7 armv8 x86]

GetoptLong.new(
    [ '--log-level',         GetoptLong::REQUIRED_ARGUMENT ],
    [ '--environment', '-E', GetoptLong::REQUIRED_ARGUMENT ]
).each do | opt, arg |
    case opt

    when '--log-level'
        Paludis::Log.instance.log_level = case arg
            when 'silent'  then  Paludis::LogLevel::Silent
            when 'warning' then  Paludis::LogLevel::Warning
            when 'qa'      then  Paludis::LogLevel::Qa
            when 'debug'   then  Paludis::LogLevel::Debug
            else die "invalid #{opt}: #{arg}"
        end

    when '--environment'
        envspec = arg
    end
end


def find_eligible_ids_and_repos env
    # Only consider repositories that have a summary, or that are fancy.
    repos = []
    env.repositories.each do | repo |
        if repo['summary'] or repo['format'].parse_value == "unwritten"
            repos << repo
        else
            $stderr << "Eek. Skipping repository " << repo.name << " because it has no summary\n"
        end
    end

    ids = []
    repos.each do | repo |
        ids.concat env[Selection::AllVersionsUnsorted.new(Generator::InRepository.new(repo.name))]
    end

    [ ids, repos ]
end

env = EnvironmentFactory.instance.create(envspec)

print "Querying"
ids, repos = find_eligible_ids_and_repos(env)
puts

index_page = IndexPage.new
repository_pages, category_pages, package_pages = {}, {}, {}
repology_page = RepologyPage.new(ids)

print "Collecting repository information"

repos.each do | repo |
    print "."
    $stdout.flush

    index_page.add_repository repo
    repository_pages[repo.name] = RepositoryPage.new(repo)
end

puts

print "Collecting ID information"

ids.each do | id |
    print "."
    $stdout.flush

    index_page.add_category_name id.name.category

    category_pages[id.name.category] ||= CategoryPage.new(id.name.category)
    category_pages[id.name.category].add_id id

    package_pages[id.name] ||= PackagePage.new(id.name)
    package_pages[id.name].add_id id
    repos.each do | repo |
        package_pages[id.name].add_repository repo
        if repo.name == id.repository_name
            category_pages[id.name.category].add_repository repo
            repository_pages[repo.name].add_id id
        end
    end
end

puts

print "Writing"
[{ nil => index_page }, repository_pages, category_pages, package_pages, {nil => repology_page}].each do | set |
    print "*"
    set.values.each do | page |
        print "."
        $stdout.flush
        page.generate
    end
end
puts

print "Copying extra bits"
FileUtils.cp ExtraFiles, OutputDir
puts

