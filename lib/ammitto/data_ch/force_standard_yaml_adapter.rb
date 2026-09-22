# frozen_string_literal: true

# Forces lutaml-model onto its plain Psych-backed StandardAdapter for
# YAML, overriding the library's own auto-detection.
#
# lutaml-model's AdapterResolver#detect_yeptris_kv_adapter picks the
# yeptris-native adapter for every :yaml/:json (de)serialization the
# moment the `yeptris` gem is anywhere in the bundle — it is a
# transitive dependency here (pulled in by lutaml-model itself), not
# something this repo or ammitto opted into.
#
# On this runner (ubuntu-latest, Ruby 3.3, x86_64-linux) yeptris's
# precompiled `native-3.3.so` cannot dlopen its own `libyeptris.so.0`
# dependency (the gem's shipped RUNPATH points at build-time-only CI
# paths and a `$ORIGIN/..` that resolves one directory short of where
# libyeptris.so actually lives in the installed gem), so yeptris warns
# ("no precompiled native materializer ... the FFI ladder carries the
# load") and falls back to its pure-FFI code path for every dump.
#
# That FFI fallback has an independent, reproducible memory-safety bug
# in Yeptris::YAML.dump / Yeptris::Document: heap corruption
# ("malloc(): invalid size (unsorted)", SIGABRT) after roughly 50
# YAML#dump round-trips in one process — confirmed to reproduce
# against yeptris 0.6.12.1, 0.6.15.2 and 0.6.17.1 (the two failed
# scheduled runs and the current rubygems release), so no available
# yeptris/lutaml-model version pin avoids it.
#
# Loaded via RUBYOPT (-r) ahead of the `ammitto` CLI in fetch.yml, so
# the override is in place before any model touches YAML — it must
# run before the first `Lutaml::Model::AdapterResolver.adapter_for`
# call, since auto-detection is cached on first use.
require 'lutaml/model'

Lutaml::Model::AdapterResolver.set_adapter_type(:yaml, :standard)
