all :
	ruby summer.rb

clean :
	rm -fr output/

upload :
	rsync --recursive --verbose --progress output/./ dev.exherbo.org:public_html/summer/./ -c --delete-after
