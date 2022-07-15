nginx-proxy:
	docker run -d \
	--name nginx-proxy \
	-p 80:80 \
	-v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
	docker run -d --name site-a -e VIRTUAL_HOST=a.designsos.org nginx
	docker run -d --name site-b -e VIRTUAL_HOST=b.designsos.org httpd

nginx-proxy-https:
	# stop any previous running containers
	docker stop site-a
	docker stop site-b
	docker stop nginx-proxy
	# remove any previous containers
	docker rm site-a
	docker rm site-b
	docker rm nginx-proxy
	# make ssl certificates directory
	mkdir certs
	# run nginx proxy 
	docker run -d -p 80:80 -p 443:443 \
	--name nginx-proxy \
	-v ${HOME}/certs:/etc/nginx/certs:ro \
	-v /etc/nginx/vhost.d \
	-v /usr/share/nginx/html \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true \
	jwilder/nginx-proxy
	# run LetsEncrypt companion
	docker run -d \
	--name nginx-letsencrypt \
	--volumes-from nginx-proxy \
	-v ${HOME}/certs:/etc/nginx/certs:rw \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	jrcs/letsencrypt-nginx-proxy-companion
	# run site-a
	docker run -d \
	--name site-a \
	-e 'LETSENCRYPT_EMAIL=hillarywando@gmail.com' \
	-e 'LETSENCRYPT_HOST=a.designsos.org' \
	-e 'VIRTUAL_HOST=a.designsos.org' nginx
	# run site-b
	docker run -d \
	--name site-b \
	-e 'LETSENCRYPT_EMAIL=hillarywando@gmail.com' \
	-e 'LETSENCRYPT_HOST=b.designsos.org' \
	-e 'VIRTUAL_HOST=b.designsos.org' httpd

nginx-proxy-compose:
	# make ssl certificates directory
	mkdir certs
	# run nginx-proxy
	docker run -d -p 80:80 -p 443:443 \
	--name nginx-proxy \
	--net reverse-proxy \
	-v ${HOME}/certs:/etc/nginx/certs:ro \
	-v /etc/nginx/vhost.d \
	-v /usr/share/nginx/html \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	--label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true \
	jwilder/nginx-proxy
	# run LetsEncrypt companion
	docker run -d \
	--name nginx-letsencrypt \
	--net reverse-proxy \
	--volumes-from nginx-proxy \
	-v ${HOME}/certs:/etc/nginx/certs:rw \
	-v /var/run/docker.sock:/var/run/docker.sock:ro \
	jrcs/letsencrypt-nginx-proxy-companion
	# build site-a image
	cd site-a && $(MAKE) build
	# build site-b image
	cd site-b && $(MAKE) build
	# run containers
	docker-compose up
