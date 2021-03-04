#! /usr/bin/env bash
#*******************************************************************************
# Copyright (c) 2018 Eclipse Foundation and others.
# This program and the accompanying materials are made available
# under the terms of the Eclipse Public License 2.0
# which is available at http://www.eclipse.org/legal/epl-v20.html,
# or the MIT License which is available at https://opensource.org/licenses/MIT.
# SPDX-License-Identifier: EPL-2.0 OR MIT
#*******************************************************************************

# * Generate <instance>/target/config.json file
# * Call gen-mvn-settings.sh script

set -o errexit
set -o nounset
set -o pipefail

IFS=$'\n\t'
SCRIPT_FOLDER="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

instance="${1:-}"

if [ -z "${instance}" ]; then
  echo "ERROR: you must provide an 'instance' name argument"
  exit 1
fi

if [ ! -d "${instance}" ]; then
  echo "ERROR: no 'instance' at '${instance}'"
  exit 1
fi

target="${instance}/target"
config="${target}/config.json"

mkdir -p "$(dirname "${config}")"
mkdir -p "$(dirname "${config}")/k8s"
mkdir -p "$(dirname "${config}")/.secrets/k8s"

jsonnet -m "${target}" "${instance}/jiro.jsonnet"

"${SCRIPT_FOLDER}/gen-mvn-settings.sh" "${instance}"
"${SCRIPT_FOLDER}/gen-gradle-properties.sh" "${instance}"
"${SCRIPT_FOLDER}/gen-sbt-properties.sh" "${instance}"

# if jiro_phase2.jsonnet file is present in instance, then use it for generation phase 2
# (to override some defaults in this phase)
if [[ -f "${instance}/jiro_phase2.jsonnet" ]]; then
  # note the -J as we will need to import config.json as generated by phase 1
  jsonnet -m "${target}" -J "${instance}/target" "${instance}/jiro_phase2.jsonnet"
else 
  # otherwise, take the one from the templates.
  # note the -J as we will need to import config.json as generated by phase 1
  jsonnet -m "${target}" -J "${instance}/target" "${SCRIPT_FOLDER}/../templates/jiro_phase2.libsonnet"
fi
