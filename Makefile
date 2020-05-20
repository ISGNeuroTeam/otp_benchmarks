define ANNOUNCE_BODY
Required section:
 build - build project into build directory, with configuration file and environment
 clean - clean all addition file, build directory and output archive file
 test - run all tests
 pack - make output archivne
Addition section:
endef

PROJECT_NAME=otp_benchmarks
VERSION=0.0.1

#GENERATE_VERSION = $(shell jq .version ./${PROJECT_NAME}/package.json )
GENERATE_BRANCH = $(shell git name-rev $$(git rev-parse HEAD) | cut -d\  -f2 | sed -re 's/^(remotes\/)?origin\///' | tr '/' '_')

#SET_VERSION = $(eval VERSION=$(GENERATE_VERSION))
SET_BRANCH = $(eval BRANCH=$(GENERATE_BRANCH))

#.SILENT:

COMPONENTS :

export ANNOUNCE_BODY
all:
	echo "$$ANNOUNCE_BODY"

pack: create_sfx
	$(SET_BRANCH)
	#$(SET_VERSION)
	echo Create archive \"$(PROJECT_NAME)-$(VERSION)-$(BRANCH).tar.gz\"
	cd build; tar czf ../$(PROJECT_NAME)-$(VERSION)-$(BRANCH).tar.gz $(PROJECT_NAME)*.run

build: $(COMPONENTS)
	# required section
	@echo Build!
	mkdir build
	mkdir build/$(PROJECT_NAME)
	cp -r ./$(PROJECT_NAME)/* ./build/$(PROJECT_NAME)
	cp README.md build/$(PROJECT_NAME)/
	cp CHANGELOG.md build/$(PROJECT_NAME)/
	cp LICENSE.md build/$(PROJECT_NAME)/

clean:
	# required section"
	rm -rf build $(PROJECT_NAME)-*.tar.gz

test:
	# required section
	@echo "Testing..."
	@#echo $(PROJECT_NAME)

create_sfx: build
	@echo $@
	$(SET_BRANCH)
	#$(SET_VERSION)
	cd build; makeself --notemp $(PROJECT_NAME) $(PROJECT_NAME)-$(VERSION)-$(BRANCH).run "OTP Benchmark" ./install.sh