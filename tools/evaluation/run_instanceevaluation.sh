#!/usr/bin/env bash

# This file is part of Instance Stixels:
# https://github.com/tudelft-iv/instance-stixels
#
# Copyright (c) 2019 Thomas Hehn.
#
# Instance Stixels is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Instance Stixels is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Instance Stixels. If not, see <http://www.gnu.org/licenses/>.

echo -e "\n--- Running instance evaluation"
# Expand wildcards using ($@)
ARGS=($@)
if [ -z ${CONDA_SHLVL+x} ];
then
  conda activate instance_stixels
else
  source activate instance_stixels
fi

GTINSTANCE_PATH=${CONDA_PREFIX}/lib/python3.6/site-packages/cityscapesscripts/evaluation/gtInstances.json
if [ -f ${GTINSTANCE_PATH} ]
then
  echo "rm ${GTINSTANCE_PATH}"
  rm ${GTINSTANCE_PATH}
fi

echo "python evaluation/instance_eval.py $@"
python $(dirname $0)/instance_eval.py ${ARGS[@]}

conda deactivate
#cd ..

