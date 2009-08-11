#!/bin/sh
JRUBY=${JRUBY_HOME:-/usr/local/jruby}/bin/jruby
LIB_IMPL=${GAE_HOME:-/usr/local/appengine-java-sdk}/lib/impl
${JRUBY} -J-classpath ${LIB_IMPL}/appengine-api.jar:${LIB_IMPL}/appengine-local-runtime.jar:${LIB_IMPL}/appengine-api-stubs.jar $@
