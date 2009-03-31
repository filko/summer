#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/index_page'
require 'summer/repository_page'
require 'summer/category_page'
require 'summer/package_page'
require 'Paludis'

include Paludis

EnvironmentSpec = ":summer"
OutputDir = "./output/"
ExtraFiles = %w[screen.css summer.css zebrapig-headbox.png]
Platforms = %w[amd64 ia64 ppc64 x86]

def find_elibible_ids_and_repos env
    # Only consider repositories that have a summary, or that are fancy.
    repos = []
    env.package_database.repositories.each do | repo |
        if repo['summary'] or repo['format'].value == "unwritten"
            repos << repo
        end
    end

    ids = []
    repos.each do | repo |
        ids.concat env[Selection::AllVersionsUnsorted.new(Generator::InRepository.new(repo.name))]
    end

    [ ids, repos ]
end

env = EnvironmentFactory.instance.create(EnvironmentSpec)

print "Querying"
ids, repos = find_elibible_ids_and_repos(env)
puts

index_page = IndexPage.new
repository_pages, category_pages, package_pages = {}, {}, {}

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
            repository_pages[repo.name].add_id id
        end
    end
end

puts

print "Writing"
[{ nil => index_page }, repository_pages, category_pages, package_pages].each do | set |
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

