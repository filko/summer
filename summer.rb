#!/usr/bin/ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'summer/htmlstring'
require 'summer/page'
require 'Paludis'
require 'pathname'
require 'fileutils'

include Paludis

EnvironmentSpec = ":summer"
OutputDir = "./output/"
ExtraFiles = %w[screen.css summer.css zebrapig-headbox.png]
Platforms = %w[amd64 ia64 ppc64 x86]

puts "Querying..."
env = EnvironmentFactory.instance.create(EnvironmentSpec)
ids = env[Selection::AllVersionsSorted.new(Generator::All.new | Filter::SupportsAction.new(InstallAction))]

category_pages, package_pages = Hash.new, Hash.new
index_page = IndexPage.new

print "IDs"
ids.each do | id |
    print "."
    $stdout.flush

    index_page.has_repository(id.repository_name)
    index_page.has_category(id.name.category)

    cat_page = (category_pages[id.name.category] ||= CategoryPage.new(id.name.category))
    cat_page.has_package(id.name, id)
    cat_page.is_in_repository(id.repository_name)

    pkg_page = (package_pages[id.name] ||= PackagePage.new(id.name))
    pkg_page.has_id(id)
    pkg_page.is_in_repository(id.repository_name)
end
puts

print "Writing"
[[index_page], category_pages.values, package_pages.values].each do | set |
    set.each do | page |
        print "."
        $stdout.flush
        page.generate
    end
end
puts

print "Copying extra bits"
FileUtils.cp ExtraFiles, OutputDir
puts

