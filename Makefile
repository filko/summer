all :
	ruby summer.rb

clean :
	rm -fr output/

upload :
	rsync --recursive --verbose --progress output/./ /srv/www/git.exherbo.org/summer/./ -c --delete-after
