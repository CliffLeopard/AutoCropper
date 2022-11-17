//
// This file is auto-generated. Please don't modify it!
//
#pragma once

#ifdef __cplusplus
//#import "opencv.hpp"
#import "opencv2/aruco.hpp"
#else
#define CV_EXPORTS
#endif

#import <Foundation/Foundation.h>


#import "Aruco.h"
#import "Calib3d.h"



NS_ASSUME_NONNULL_BEGIN

// C++: class EstimateParameters
/**
 * @brief
 * Pose estimation parameters
 * pattern Defines center this system and axes direction (default PatternPos::CCW_center).
 * useExtrinsicGuess Parameter used for SOLVEPNP_ITERATIVE. If true (1), the function uses the provided
 * rvec and tvec values as initial approximations of the rotation and translation vectors, respectively, and further
 * optimizes them (default false).
 * solvePnPMethod Method for solving a PnP problem: see REF: calib3d_solvePnP_flags (default SOLVEPNP_ITERATIVE).
 * @see PatternPos, solvePnP(), REF: tutorial_aruco_detection
 *
 * Member of `Aruco`
 */
CV_EXPORTS @interface EstimateParameters : NSObject


#ifdef __cplusplus
@property(readonly)cv::Ptr<cv::aruco::EstimateParameters> nativePtr;
#endif

#ifdef __cplusplus
- (instancetype)initWithNativePtr:(cv::Ptr<cv::aruco::EstimateParameters>)nativePtr;
+ (instancetype)fromNative:(cv::Ptr<cv::aruco::EstimateParameters>)nativePtr;
#endif


#pragma mark - Methods


//
// static Ptr_EstimateParameters cv::aruco::EstimateParameters::create()
//
+ (EstimateParameters*)create NS_SWIFT_NAME(create());


    //
    // C++: PatternPos cv::aruco::EstimateParameters::pattern
    //

@property PatternPos pattern;

    //
    // C++: bool cv::aruco::EstimateParameters::useExtrinsicGuess
    //

@property BOOL useExtrinsicGuess;

    //
    // C++: SolvePnPMethod cv::aruco::EstimateParameters::solvePnPMethod
    //

@property SolvePnPMethod solvePnPMethod;


@end

NS_ASSUME_NONNULL_END


