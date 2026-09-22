# frozen_string_literal: true

# Forces lutaml-model onto its plain Psych-backed StandardAdapter for
# YAML, overriding the library's own auto-detection.
#
# lutaml-model's AdapterResolver#detect_yeptris_kv_adapter picks the
# yeptris-native adapter for every :yaml/:json (de)serialization the
# moment the yeptris gem is anywhere in the bundle. It is a transitive
# dependency here (pulled in by lutaml-model itself), not something
# this repo or ammitto opted into.
#
# On this runner (ubuntu-latest, Ruby 3.3, x86_64-linux) yeptris's
# precompiled native-3.3.so cannot dlopen its own libyeptris.so.0
# dependency: the gem's shipped RUNPATH bakes in build-time-only CI
# paths, plus a $ORIGIN/.. that resolves one directory short of where
# libyeptris.so actually lives in the installed gem. So yeptris warns
# ("no precompiled native materializer ... the FFI ladder carries the
# load") and falls back to its pure FFI code path for every dump.
#
# That FFI fallback has an independent, reproducible memory-safety bug
# in Yeptris::YAML.dump / Yeptris::Document: heap corruption
# ("malloc(): invalid size (unsorted)", SIGABRT) after roughly 50
# YAML#dump round-trips in one process. Confirmed to reproduce against
# yeptris 0.6.12.1, 0.6.15.2 and 0.6.17.1 (the two failed scheduled
# runs and the current rubygems release), so no yeptris release fixes
# it, and no lutaml-model version pin routes around it either:
# lutaml-model >= 0.8.30 bumped its own rubyzip dependency to ~> 3.4,
# which conflicts with ammitto's `roo ~> 2.10` (roo needs
# rubyzip < 3.0.0), so 0.8.29 is the newest lutaml-model this bundle
# can resolve to at all. Confirmed with `bundle lock
# --update=lutaml-model` against an explicit `>= 0.8.38` constraint:
# bundler's resolver reports the rubyzip conflict and fails outright.
#
# Separately: lutaml-model PR #798 ("a configured adapter type must
# not fall through to auto-detection", first released in 0.8.37) fixed
# a real leak in AdapterResolver#adapter_for where a configured type
# with no cached resolved class still fell through to auto-detection,
# loading yeptris anyway. That is NOT the path this file exercises.
# set_adapter_type (called below, and by lutaml-model's own
# `Config.configure { |c| c.yaml_adapter_type = :standard }`) already
# populates AdapterResolver's resolved-class cache eagerly, in the
# same call, on 0.8.29 as shipped, so adapter_for's first branch
# (configured type with a cached class) returns before auto-detection
# ever runs. Verified directly: ran PR #798's own before/after repro
# (Config.configure with yaml_adapter_type = :standard, then to_yaml)
# against the installed 0.8.29 and confirmed Yeptris never gets
# defined. This file's fix is unaffected by that bug either way.
#
# This has to be a loadable file, not an inline RUBYOPT one-liner:
# RUBYOPT only accepts a fixed flag set (-r, -I, -w, ...) and rejects
# -e outright ("invalid switch in RUBYOPT"), and the override has to
# run as Ruby code inside the same process as the `ammitto` CLI,
# before anything touches YAML, since AdapterResolver's state is
# in-process and caches on first use.
require 'lutaml/model'

Lutaml::Model::AdapterResolver.set_adapter_type(:yaml, :standard)
