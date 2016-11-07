NAME = healthgraph-databox-driver
EXECUTABLE = main.native
DOCKER = docker $(DOCKER_OPTS)

build:
	$(DOCKER) build -f Dockerfile.build -t $(NAME):build .
	$(DOCKER) run --rm $(NAME):build /bin/sh -c 'tar -hc $(EXECUTABLE)' | tar -x
	$(DOCKER) build -t $(NAME):latest .
	rm -f $(EXECUTABLE)

clean:
	$(DOCKER) rmi $(NAME):build
