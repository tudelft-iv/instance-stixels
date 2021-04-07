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

#ifndef STIXELSKERNELS_H_
#define STIXELSKERNELS_H_

#include <stdint.h>
#include "Stixels.hpp"
#include "types.h"
#include "util.h"
#include "configuration.h"
#include "Cityscapes.h"

template <bool PAIRWISE>
__global__ void StixelsKernel(
        const pixel_t* __restrict__ d_disparity,
        int32_t* __restrict__ d_segmentation,
        const StixelParameters params,
        const float* __restrict__ d_ground_function,
        const float* __restrict__ d_normalization_ground,
        const float* __restrict__ d_inv_sigma2_ground,
        const float* __restrict__ d_object_disparity_range,
        const float* __restrict__ d_object_lut,
        Section* __restrict__ d_stixels,
        float* d_instance_centerofmass,
        int32_t* d_instance_indices,
        bool* d_instance_core_candidates,
        int32_t* d_instances_per_class,
        int64_t* d_instance_meansx_ps);

__global__ void JoinColumns(
        pixel_t* __restrict__ d_disparity,
        pixel_t* __restrict__ d_out,
        const int step_size,
        const bool median,
        const int width_margin,
        const int rows,
        const int cols,
        const int real_cols,
        const float invalid_disparity);

__global__ void ComputeObjectLUT(
        const pixel_t* __restrict__ d_disparity,
        const float* __restrict__ d_obj_cost_lut,
        float* __restrict__ d_object_lut,
        const StixelParameters params,
        const int n_power2);

//Example.
//Input:
//0: 1    1: 2    2: 3    3: 4    4: 5    5: 6    6: 7    7: 8
//Output:
//0: 0    1: 1    2: 3    3: 6    4: 10   5: 15   6: 21   7: 28
template<typename T>
__inline__ __device__ void ComputePrefixSum(T *arr, const int n) {
    int offset = 1;

    for (int d = n>>1; d > 0; d >>= 1) {
        __syncthreads();
        if (threadIdx.x < d) {
            int ai = offset * (2*threadIdx.x + 1) - 1;
            int bi = offset * (2*threadIdx.x + 2) - 1;
            arr[bi] += arr[ai];
        }
        offset *= 2;
    }

    if (threadIdx.x == 0) {
        arr[n - 1] = 0;
    }

    for (int d = 1; d < n; d *= 2) {
        offset >>= 1;
        __syncthreads();
        if (threadIdx.x < d) {
            int ai = offset * (2*threadIdx.x + 1) - 1;
            int bi = offset * (2*threadIdx.x + 2) - 1;

            T tmp = arr[ai];
            arr[ai] = arr[bi];
            arr[bi] += tmp;
        }
    }
}

#endif /* STIXELSKERNELS_H_ */
