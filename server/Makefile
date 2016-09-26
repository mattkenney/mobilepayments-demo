NAME=beanstream/mobilepay-demo
VERSION=1.0.1

build:
	docker build -t $(NAME):$(VERSION) --rm .

shell:
	docker run -it $(NAME):$(VERSION) /bin/ash

run:
	docker run -e "BIC_API_PASSCODE=<your_merchant_passcode>" -e "BIC_MERCHANT_ID=<your_merchant_id>" -d -p 80:8080 $(NAME):$(VERSION)
