// picogkapitypes_c.h — C-compatible version of PicoGKApiTypes.h for cgo.
// Uses stdint.h instead of cstdint (C vs C++).
#ifndef PICOGKGLAPITYPES_C_H_
#define PICOGKGLAPITYPES_C_H_

#include <stdint.h>

#pragma pack(1)
typedef struct PKTriangle {
    int32_t A;
    int32_t B;
    int32_t C;
} PKTriangle;

typedef struct PKCoord {
    int32_t X;
    int32_t Y;
    int32_t Z;
} PKCoord;

typedef struct PKVector2 {
    float X;
    float Y;
} PKVector2;

typedef struct PKVector3 {
    float X;
    float Y;
    float Z;
} PKVector3;

typedef struct PKVector4 {
    float X;
    float Y;
    float Z;
    float W;
} PKVector4;

typedef struct PKBBox3 {
    PKVector3 vecMin;
    PKVector3 vecMax;
} PKBBox3;

typedef struct PKMatrix4x4 {
    PKVector4 vec1;
    PKVector4 vec2;
    PKVector4 vec3;
    PKVector4 vec4;
} PKMatrix4x4;

typedef struct PKColorFloat {
    float R;
    float G;
    float B;
    float A;
} PKColorFloat;

#pragma pack()

// Handle types
typedef uint64_t PKHANDLE;
typedef PKHANDLE PKINSTANCE;
typedef PKHANDLE PKMESH;
typedef PKHANDLE PKLATTICE;
typedef PKHANDLE PKPOLYLINE;
typedef PKHANDLE PKVOXELS;
typedef PKHANDLE PKVDBFILE;
typedef PKHANDLE PKSCALARFIELD;
typedef PKHANDLE PKVECTORFIELD;
typedef PKHANDLE PKMETADATA;
typedef PKHANDLE PKFILEINFO;
typedef void*   PKVIEWER;
typedef PKHANDLE PKGPUTEX;
typedef PKHANDLE PKQUAD;
typedef PKHANDLE PKGUI;

// Callback typedefs
typedef float (*PKPFnfSdf)(const PKVector3* pvecCoord);
typedef void   (*PKFnTraverseActiveS)(const PKVector3* pvecCoord, float fValue);
typedef void   (*PKFnTraverseActiveV)(const PKVector3* pvecCoord, const PKVector3* pvecValue);
typedef void   (*PKFInfo)(const char* pszMessage, bool bFatalError);
typedef void   (*PKPFUpdateRequested)(void* poViewer, const PKVector2* pvecViewport, PKColorFloat* pclrBackground, PKMatrix4x4* pmatViewProjection, PKVector3* pvecEyePosition);
typedef void   (*PKPFKeyPressed)(void* poViewer, int32_t iKey, int32_t iScancode, int32_t iAction, int32_t iModifiers);
typedef void   (*PKPFMouseMoved)(void* poViewer, const PKVector2* pvecMousePos, bool bShift, bool bCtrl, bool bAlt, bool bSuper);
typedef void   (*PKPFMouseButton)(void* poViewer, int32_t iButton, int32_t iAction, int32_t iModifiers, const PKVector2* pvecMousePos);
typedef void   (*PKPFScrollWheel)(void* poViewer, const PKVector2* pvecOffset, const PKVector2* pvecMousePos, bool bShift, bool bCtrl, bool bAlt, bool bSuper);
typedef void   (*PKPFWindowSize)(void* poViewer, const PKVector2* pvecWindowSize);

#define PKINFOSTRINGLEN 255

#endif