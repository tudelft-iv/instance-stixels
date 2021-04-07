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

echo -e "\n--- Running semantic evaluation"
#cd $(dirname $0)
# Expand wildcards using ($@)
ARGS=($@)
if [ -z ${CONDA_SHLVL+x} ];
then
  conda activate instance_stixels
else
  source activate instance_stixels
fi
echo "python -m cityscapesscripts.evaluation.evalPixelLevelSemanticLabeling $@"
python -m cityscapesscripts.evaluation.evalPixelLevelSemanticLabeling\
  ${ARGS[@]}
conda deactivate
#cd ..

