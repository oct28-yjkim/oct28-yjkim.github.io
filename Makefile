pull:
	git pull

sub_checkout:
	git submodule update --init --recursive  

run: 
	docker run  -it --rm --name hugo -d \
		-v ${PWD}:/src \
		 --user 1000:1000 \
		-p 1313:1313 \
		klakegg/hugo:0.83.1-ext-alpine server 

server:
	docker run  -d --rm --name hugo\
		-v ${PWD}:/src \
		--user 1000:1000 \
		-p 1313:1313 \
		klakegg/hugo:0.83.1-ext-alpine server -D --theme toha --watch

log:
	docker logs hugo -f 

stop:
	docker stop hugo

exec: 
	docker exec -it hugo bash 
	
push: 
	git add . -A;
	git commit -m "update blog project `date`";
	git push -u origin source ;

