// This file is part of Instance Stixels:
// https://github.com/tudelft-iv/instance-stixels
//
// Originally, it was part of stixels:
// https://github.com/dhernandez0/stixels
//
// Copyright (c) 2016 Daniel Hernandez Juarez.
// Copyright (c) 2019 Thomas Hehn.
//
// Instance Stixels is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Instance Stixels is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Instance Stixels. If not, see <http://www.gnu.org/licenses/>.

#ifndef CONFIGURATION_H_
#define CONFIGURATION_H_

#include <math_constants.h> // CUDART_INF_F

// Must be macro.
#define MAX_LOGPROB                  CUDART_INF_F
constexpr int LOG_LUT_SIZE           = 1000000;
constexpr int DOWNSAMPLE_FACTOR      = 8;
constexpr int MAX_STIXELS_PER_COLUMN = 200;

typedef float pixel_t;

#endif /* CONFIGURATION_H_ */
