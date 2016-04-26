BINSRC_DIR=./bin_src
SHELLSTUB=$(BINSRC_DIR)/shell_stub.txt
BINSRC=$(BINSRC_DIR)/cmd.js
BINOUTPUT=./bin/cmd.js

all: **/*.js *.js $(BINOUTPUT)

%.js: %.coffee
	npm run coffee -- ./$<

$(BINOUTPUT): $(SHELLSTUB) $(BINSRC)
	cat $(SHELLSTUB) $(BINSRC) > $(BINOUTPUT)

