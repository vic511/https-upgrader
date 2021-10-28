# Docker image name
IMAGE := vic/https-upgrader

# Container name
NAME ?= https-upgrader
# Port mapping on host
PORT ?= 8080

# Configurable docker-run(1) options
DOCKER_OPTIONS ?=

# Upgrade bypass configuration to generate
PATTERN_LISTS := $(wildcard conf/bypass/*.txt)
PATTERN_CONFIGS := $(PATTERN_LISTS:.txt=.conf)
# Every generated configuration file
GEN_CONFIGS = $(PATTERN_CONFIGS) conf/bypass/all.conf conf/resolver.conf


define log
	@printf "%5s  %s\n" "$(1)" "$(2)"
endef


run: build stop
	$(call log,RUN,$(PORT))
	@docker run --name $(NAME) \
	       	-p $(PORT):80 -v $(PWD)/conf:/etc/nginx/conf:ro \
		$(DOCKER_OPTIONS) \
		-t $(IMAGE)

build: conf
	$(call log,BUILD,$(IMAGE))
	@docker build -t $(IMAGE) .

# Generate configuration
conf: conf/resolver.conf conf/bypass/all.conf

ifneq (,$(wildcard /etc/resolv.conf))
# Use host configuration
conf/resolver.conf: /etc/resolv.conf
	$(call log,GEN,$@)
	@awk '\
		BEGIN { printf "resolver "; } \
		/nameserver/ { printf "%s ", $$2; } \
		END { printf "ipv6=off;\n"; } \
	' $^ > $@
else
# Defaults to Google DNS servers
conf/resolver.conf:
	$(call log,GEN,$@)
	@echo "resolver 8.8.8.8 8.8.4.4 ipv6=off;" > $@
endif

conf/bypass/all.conf: $(PATTERN_CONFIGS)
	$(call log,GEN,$@)
	@for file in $^; do \
		echo "include $${file#conf/};"; \
	done > $@

# Generate domain whitelisting logic from pattern file
conf/bypass/%.conf: conf/bypass/%.txt
	$(call log,GEN,$@)
	@awk '!/^#/ { \
		($$0 ~ /^\^/) ? cond = "~" : cond = "="; \
		printf "if ($$http_host %s \"%s\") { return 502; }\n", cond, $$0; \
	}' $^ > $@

clean:
	$(RM) $(GEN_CONFIGS)

stop:
	$(call log,STOP,$(NAME))
	@-docker stop $(NAME)
	@docker rm -f $(NAME)

.PHONY: run build conf stop
