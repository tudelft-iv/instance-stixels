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

#include "RoadEstimation.h"

RoadEstimation::RoadEstimation()
{}


RoadEstimation::~RoadEstimation()
{}

void RoadEstimation::Initialize(
        const float camera_center_y, const float baseline, const float focal,
        const int rows, const int cols, const int max_dis,
        const float road_vdisparity_threshold) {
    // Get camera parameters
    m_cy = camera_center_y;
    m_b = baseline;
    m_focal = focal;

    // TODO: tune parameters to get better road estimation or use provided
    // vehicle information
    // Default configuration
    m_HoughAccumThr = 25;
    //m_binThr = 0.0f;
    m_binThr = road_vdisparity_threshold;
    m_maxPitch = 50;
    m_minPitch = -50;
    /*
    m_maxCameraHeight = -1.30f;
    m_minCameraHeight = -1.90f;
     */
    m_maxCameraHeight = 1.90f;
    m_minCameraHeight = 1.30f;

    m_maxPitch = m_maxPitch * (float) CV_PI / 180.0f;
    m_minPitch = m_minPitch * (float) CV_PI / 180.0f;
    m_max_dis = max_dis;
    m_rows = rows;
    m_cols = cols;

    m_rho = 0;
    m_theta = 0;
    m_horizonPoint = 0;
    m_pitch = 0;
    m_cameraHeight = 0;

    m_vDisp = (uint8_t*) malloc(m_max_dis * m_rows * sizeof(uint8_t));

    CUDA_CHECK_RETURN(
            cudaMalloc((void**) &d_disparity, m_cols*m_rows*sizeof(float)));
    CUDA_CHECK_RETURN(
            cudaMalloc((void**) &d_vDisp, m_max_dis * m_rows * sizeof(int)));
    CUDA_CHECK_RETURN(
            cudaMalloc((void**) &d_maximum, sizeof(int)));
    CUDA_CHECK_RETURN(
            cudaMalloc((void**) &d_vDispBinary,
                       m_max_dis * m_rows * sizeof(uint8_t)));

    m_is_initialized = true;
}

void RoadEstimation::Finish() {
    CUDA_CHECK_RETURN(cudaFree(d_vDisp));
    CUDA_CHECK_RETURN(cudaFree(d_disparity));
    CUDA_CHECK_RETURN(cudaFree(d_maximum));
    CUDA_CHECK_RETURN(cudaFree(d_vDispBinary));
    free(m_vDisp);

    m_is_initialized = false;
}

bool RoadEstimation::Compute(const std::vector<pixel_t>& im) {
    CUDA_CHECK_RETURN(
            cudaMemcpy(d_disparity,
                       im.data(),
                       im.size() * sizeof(pixel_t),
                       cudaMemcpyHostToDevice));

    return Compute(d_disparity);
}

bool RoadEstimation::Compute(pixel_t* d_im){
    pixel_t* d_disparity_tmp = d_im;
    bool ok = false;

    CUDA_CHECK_RETURN(
            cudaMemset(d_maximum, 0, sizeof(int)));
    CUDA_CHECK_RETURN(
            cudaMemset(d_vDisp, 0, m_max_dis * m_rows * sizeof(int)));

    // Compute the vDisparity histogram
    ComputeHistogram<<<(m_rows*m_cols + 256 - 1)/256, 256>>>(
            d_disparity_tmp, d_vDisp, m_rows, m_cols, m_max_dis);
    ComputeMaximum<<<(m_rows*m_max_dis + 256-1)/256, 256>>>(
            d_vDisp, d_maximum, m_rows, m_max_dis);
    ComputeBinaryImage<<<(m_rows*m_max_dis + 256 - 1)/256, 256>>>(
            d_vDisp, d_vDispBinary, d_maximum, m_binThr, m_rows, m_max_dis);

    // Compute the Hough transform
    float rho, theta, horizonPoint, pitch, cameraHeight, slope;
    if( ComputeHough(d_vDispBinary, rho, theta, horizonPoint, pitch,
                     cameraHeight, slope) ){
        m_rho = rho;
        m_theta = theta;
        m_horizonPoint = (int) ceil(horizonPoint);
        m_pitch = pitch;
        m_cameraHeight = cameraHeight;
        m_slope = slope;
        ok = true;
    }

    return ok;
}

bool RoadEstimation::ComputeHough(
        uint8_t* d_vDispBinary, float& rho, float& theta, float& horizonPoint,
        float& pitch, float& cameraHeight, float& slope) {
    // Compute the Hough transform
    std::vector<cv::Vec2f> lines;
    // Note: When running with rosrun, the next line occasionally throws an
    // illegal memory access error.
    CUDA_CHECK_RETURN(
        cudaMemcpy(m_vDisp,
                   d_vDispBinary,
                   m_max_dis * m_rows * sizeof(uint8_t),
                   cudaMemcpyDeviceToHost));
    cv::Mat vDisp(m_rows, m_max_dis, CV_8UC1, m_vDisp);
    cv::HoughLines(vDisp, lines, 1.0, CV_PI/180, m_HoughAccumThr);

    // Get the best line from hough
    for (size_t i=0; i < lines.size(); i++) {
        // Get rho and theta
        rho = abs(lines[i][0]);
        theta = lines[i][1];

        // Compute camera position
        ComputeCameraProperties(vDisp, rho, theta, horizonPoint, pitch,
                                cameraHeight, slope);

        //printf("%f (%f %f) %f (%f %f)\n",
        //       pitch, m_minPitch, m_maxPitch, cameraHeight,
        //       m_minCameraHeight, m_maxCameraHeight);
        //if (pitch >= m_minPitch &&
        //    pitch <= m_maxPitch &&
        //    cameraHeight >= m_minCameraHeight &&
        //    cameraHeight <= m_maxCameraHeight) {
        if (pitch>=m_minPitch && pitch<=m_maxPitch) {
            return true;
        }
    }

    return false;
}

void RoadEstimation::ComputeCameraProperties(
        cv::Mat vDisp, const float rho, const float theta, float& horizonPoint,
        float& pitch, float& cameraHeight, float& slope) const {
    // Compute Horizon Line (2D)
    horizonPoint = rho/sinf(theta);

    // Compute pitch -> arctan((cy - y0Hough)/focal)
    // It is negative because y axis is inverted.
    pitch = -atanf((m_cy - horizonPoint)/(m_focal));

    // Compute the slope needed to compute the Camera height.
    float last_row = (float) (vDisp.rows-1);
    float vDispDown = (rho - last_row*sinf(theta)) / cosf(theta);
    slope = (0 - vDispDown) / (horizonPoint - last_row);

    // Compute the camera height -> baseline*cos(pitch)/slopeHough
    cameraHeight = m_b * cosf(pitch) / slope;
}

