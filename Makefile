### -*-Makefile-*- to prepare "The Best of Both Worlds: Using Blended
### Learning in Actuarial Science Courses - Actuarial Teaching
### Conference 2017"
##
## Copyright (C) 2017 Vincent Goulet
##
## 'make doc' compiles the slides;
## 'make release' creates a release on GitHub;
## 'make upload' attaches the slides in PDF to the release.
##
## Author: Vincent Goulet
##
## This file is part of project "The Best of Both Worlds: Using
## Blended Learning in Actuarial Science Courses - Actuarial Teaching
## Conference 2017"
## http://github.com/vigou3/atc-2017-blended-learning

## Key files
MASTER = atc-2017-blended-learning.pdf
README = README.md

## Version number
VERSION = $(shell cat VERSION)

# Toolset
TEXI2DVI = LATEX=xelatex texi2dvi -b
RM = rm -r

## GitHub repository and authentication
REPOSURL = https://api.github.com/repos/vigou3/atc-2017-blended-learning
OAUTHTOKEN = $(shell cat ~/.github/token)


doc: ${MASTER}

${MASTER}: *.tex
	${TEXI2DVI} ${MASTER:.pdf=.tex}

release:
	@echo ----- Creating release on GitHub...
	@if [ -n "$(shell git status --porcelain | grep -v '^??')" ]; then \
	    echo "uncommitted changes in repository; not creating release"; exit 2; fi	
	if [ -e relnotes.in ]; then rm relnotes.in; fi
	touch relnotes.in
	awk 'BEGIN { ORS=" "; print "{\"tag_name\": \"v${VERSION}\"," } \
	      /^$$/ { next } \
	      /^## Changelog/ { state=0; next } \
              (state==0) && /^### / { state=1; out=$$2; \
	                             for(i=3;i<=NF;i++){out=out" "$$i}; \
	                             printf "\"name\": \"Version %s\", \"body\": \"", out; \
	                             next } \
	      (state==1) && /^### / { state=2; print "\","; next } \
	      state==1 { printf "%s\\n", $$0 } \
	      END { print "\"draft\": false, \"prerelease\": false}" }' \
	      ${README} >> relnotes.in
	curl --data @relnotes.in ${REPOSURL}/releases?access_token=${OAUTHTOKEN}
	rm relnotes.in
	@echo ----- Done creating the release

upload:
	@echo ----- Getting upload URL from GitHub...
	$(eval upload_url=$(shell curl -s ${REPOSURL}/releases/latest \
	 			  | awk -F '[ {]' '/^  \"upload_url\"/ \
	                                    { print substr($$4, 2, length) }'))
	@echo ${upload_url}
	@echo ----- Uploading PDF and archive to GitHub...
	curl -H 'Content-Type: application/zip' \
	     -H 'Authorization: token ${OAUTHTOKEN}' \
	     --upload-file ${MASTER} \
             -i "${upload_url}?&name=${MASTER}" -s
	@echo ----- Done uploading files
