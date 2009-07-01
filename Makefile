all :
	ruby summer.rb

clean :
	rm -fr output/

upload :
	rsync --recursive --verbose --progress output/./ /var/www/localhost/htdocs/summer/./ -c --delete-after
