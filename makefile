SHELL := /bin/bash -e

# if STACK_SUFFIX is set then the ?= make sure it doesn't override it.
ifdef BRANCH_NAME
	# Convert / to - for branches like feature/new and remove master from suffix.
	STACK_SUFFIX ?= $(if $(filter-out master,$(BRANCH_NAME)),-$(subst /,-,$(BRANCH_NAME)))
else ifdef USER
	STACK_SUFFIX ?= -$(shell echo "$(USER)"| cut -d'.' -f 2)
else ifdef USERNAME
	STACK_SUFFIX ?= -$(USERNAME)
endif

CFN_STACK_SUFFIX = $(STACK_SUFFIX)

ifeq ($(BRANCH_NAME), master)
	CFN_MASTER_STACK := true
	TERMINATION_PROTECTION := yes
	DELETION_POLICY := Snapshot
else
	CFN_MASTER_STACK := false
	TERMINATION_PROTECTION := no
	DELETION_POLICY := Delete
endif

IAM_STACK_NAME      = cv-iam$(STACK_SUFFIX)
SECURITY_STACK_NAME = cv-security$(STACK_SUFFIX)
BUCKET_STACK_NAME   = cv-bucket$(STACK_SUFFIX)
ENI_STACK_NAME			= cv-eni$(STACK_SUFFIX)
NODES_STACK_NAME		= cv-nodes$(STACK_SUFFIX)
VOLUMES_STACK_NAME  = cv-volumes$(STACK-SUFFIX)

COMMIT_SHA 					= $(shell git rev-parse --short HEAD)


export

.PHONY: all deploy test clean

all:
	@$(MAKE) -f Makefile.test
	@$(MAKE) -f Makefile.deploy

deploy:
	@$(MAKE) -f Makefile.deploy

test:
	@$(MAKE) -f Makefile.test

clean:
	@$(MAKE) -f Makefile.clean

include Makefile.deploy Makefile.clean Makefile.test

makefile.clean
SHELL := /bin/bash -e

CLEAN_TARGETS := clean-iam clean-security clean-eni clean-nodes clean-volumes

.PHONY: env-vars $(CLEAN_TARGETS)

all-clean: $(CLEAN_TARGETS)

clean-iam: env-vars clean-nodes
	@echo "--- Clean $(ENVIRONMENT) cv-iam cloudformation stack"
	CFN_STATE=absent ansible-playbook ./playbooks/iam.yaml

clean-security: env-vars clean-eni #clean-nodes
	@echo "--- Clean $(ENVIRONMENT) cv-security cloudformation stack"
	CFN_STATE=absent ansible-playbook ./playbooks/security.yaml

clean-eni: env-vars clean-nodes
	@echo "--- Clean $(ENVIRONMENT) cv-eni cloudformation stack"
	CFN_STATE=absent ansible-playbook ./playbooks/eni.yaml

clean-volumes: env-vars clean-nodes
	@echo "--- Clean $(ENVIRONMENT) cv-volumes cloudformation stack"
	CFN_STATE=absent ansible-playbook ./playbooks/volumes.yaml

clean-nodes: env-vars clean-volumes
	@echo "--- Clean $(ENVIRONMENT) cv-nodes cloudformation stack"
	CFN_STATE=absent ansible-playbook ./playbooks/nodes.yaml

clean-bucket: env-vars
	@echo "--- Clean $(ENVIRONMENT) cv-bucket cloudformation stack"
	CFN_STATE=absent ansible-playbook ./playbooks/bucket.yaml

env-vars:
ifndef ENVIRONMENT
	$(error ENVIRONMENT is undefined)
endif