VERSION := $(shell jq -r .version <package.json)

APP      := $(shell jq -r .name <package.json)
PACKAGES := $(shell go list -f {{.Dir}} ./...)
GOFILES  := $(addsuffix /*.go,$(PACKAGES))
GOFILES  := $(wildcard $(GOFILES))

.PHONY: clean release README.md

clean:
	rm -rf binaries/
	rm -rf release/

release-exists:
	hub release show "$(VERSION)"

release: README.md zip
	git add package.json
	git add README.md
	git add Makefile
	git commit -am "Release $(VERSION)" || true
	git push
	hub release create $(VERSION) -m "$(VERSION)" -a release/$(APP)_$(VERSION)_osx_x86_64.tar.gz -a release/$(APP)_$(VERSION)_osx_arm64.tar.gz -a release/$(APP)_$(VERSION)_windows_x86_64.zip -a release/$(APP)_$(VERSION)_linux_x86_64.tar.gz -a release/$(APP)_$(VERSION)_linux_arm64.tar.gz

README.md:
	VERSION="$(VERSION)" APP="$(APP)" USAGE="$$(go get github.com/nholuongut/$(APP); $(APP) -h 2>&1)" <README.template.md envsubst > README.md

zip: release/$(APP)_$(VERSION)_osx_x86_64.tar.gz release/$(APP)_$(VERSION)_windows_x86_64.zip release/$(APP)_$(VERSION)_linux_x86_64.tar.gz release/$(APP)_$(VERSION)_linux_arm64.tar.gz release/$(APP)_$(VERSION)_osx_arm64.tar.gz

binaries: binaries/osx_x86_64/$(APP) binaries/osx_arm64/$(APP) binaries/windows_x86_64/$(APP).exe binaries/linux_x86_64/$(APP)

# Darwin (OSX) x86_64
release/$(APP)_$(VERSION)_osx_x86_64.tar.gz: binaries/osx_x86_64/$(APP)
	mkdir -p release
	tar cfz release/$(APP)_$(VERSION)_osx_x86_64.tar.gz -C binaries/osx_x86_64 $(APP)

binaries/osx_x86_64/$(APP): $(GOFILES)
	GOFLAGS=-buildvcs=false CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION) -X main.app=$(APP)" -o binaries/osx_x86_64/$(APP)  .

# Darwin (OSX) ARM64
release/$(APP)_$(VERSION)_osx_arm64.tar.gz: binaries/osx_arm64/$(APP)
	mkdir -p release
	tar cfz release/$(APP)_$(VERSION)_osx_arm64.tar.gz -C binaries/osx_arm64 $(APP)

binaries/osx_arm64/$(APP): $(GOFILES)
	GOFLAGS=-buildvcs=false CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build -ldflags "-X main.version=$(VERSION) -X main.app=$(APP)" -o binaries/osx_arm64/$(APP) .

# Windows 64 bit
release/$(APP)_$(VERSION)_windows_x86_64.zip: binaries/windows_x86_64/$(APP).exe
	mkdir -p release
	cd ./binaries/windows_x86_64 && zip -r -D ../../release/$(APP)_$(VERSION)_windows_x86_64.zip $(APP).exe

binaries/windows_x86_64/$(APP).exe: $(GOFILES)
	GOFLAGS=-buildvcs=false CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION) -X main.app=$(APP)" -o binaries/windows_x86_64/$(APP).exe .

# Linux x86_64
release/$(APP)_$(VERSION)_linux_x86_64.tar.gz: binaries/linux_x86_64/$(APP)
	mkdir -p release
	tar cfz release/$(APP)_$(VERSION)_linux_x86_64.tar.gz -C binaries/linux_x86_64 $(APP)

binaries/linux_x86_64/$(APP): $(GOFILES)
	GOFLAGS=-buildvcs=false CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION) -X main.app=$(APP)" -o binaries/linux_x86_64/$(APP) .

# Linux ARM64
release/$(APP)_$(VERSION)_linux_arm64.tar.gz: binaries/linux_arm64/$(APP)
	mkdir -p release
	tar cfz release/$(APP)_$(VERSION)_linux_arm64.tar.gz -C binaries/linux_arm64 $(APP)

binaries/linux_arm64/$(APP): $(GOFILES)
	GOFLAGS=-buildvcs=false CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "-X main.version=$(VERSION) -X main.app=$(APP)" -o binaries/linux_arm64/$(APP) .
