// picogk_ffi.h — C-compatible PicoGK API header for cgo.
// Combines PicoGKApiTypes.h and PicoGK.h into one C-only file.
#ifndef PICOGK_FFI_H_
#define PICOGK_FFI_H_

#include <stdint.h>
#include <stdbool.h>

#pragma pack(1)
typedef struct PKTriangle { int32_t A, B, C; } PKTriangle;
typedef struct PKCoord    { int32_t X, Y, Z; } PKCoord;
typedef struct PKVector2  { float X, Y; } PKVector2;
typedef struct PKVector3  { float X, Y, Z; } PKVector3;
typedef struct PKVector4  { float X, Y, Z, W; } PKVector4;
typedef struct PKBBox3   { PKVector3 vecMin, vecMax; } PKBBox3;
typedef struct PKMatrix4x4 { PKVector4 vec1, vec2, vec3, vec4; } PKMatrix4x4;
typedef struct PKColorFloat { float R, G, B, A; } PKColorFloat;
#pragma pack()

typedef uint64_t PKHANDLE;
typedef PKHANDLE PKINSTANCE, PKMESH, PKLATTICE, PKPOLYLINE, PKVOXELS;
typedef PKHANDLE PKVDBFILE, PKSCALARFIELD, PKVECTORFIELD, PKMETADATA, PKFILEINFO;
typedef void* PKVIEWER;
typedef PKHANDLE PKGPUTEX, PKQUAD, PKGUI;

typedef float (*PKPFnfSdf)(const PKVector3*);
typedef void   (*PKFnTraverseActiveS)(const PKVector3*, float);
typedef void   (*PKFnTraverseActiveV)(const PKVector3*, const PKVector3*);
typedef void   (*PKFInfo)(const char*, bool);
typedef void   (*PKPFUpdateRequested)(void*, const PKVector2*, PKColorFloat*, PKMatrix4x4*, PKVector3*);
typedef void   (*PKPFKeyPressed)(void*, int32_t, int32_t, int32_t, int32_t);
typedef void   (*PKPFMouseMoved)(void*, const PKVector2*, bool, bool, bool, bool);
typedef void   (*PKPFMouseButton)(void*, int32_t, int32_t, int32_t, const PKVector2*);
typedef void   (*PKPFScrollWheel)(void*, const PKVector2*, const PKVector2*, bool, bool, bool, bool);
typedef void   (*PKPFWindowSize)(void*, const PKVector2*);

#define PKINFOSTRINGLEN 255

// Library
extern void Library_GetName(char psz[PKINFOSTRINGLEN]);
extern void Library_GetVersion(char psz[PKINFOSTRINGLEN]);
extern void Library_GetBuildInfo(char psz[PKINFOSTRINGLEN]);
extern PKINSTANCE Library_hCreateInstance(float fVoxelSizeMM);
extern void Library_DestroyInstance(PKINSTANCE hThis);
extern int64_t Library_nTotalMemUsage(PKINSTANCE hThis);
extern int64_t Library_nMeshesMemUsage(PKINSTANCE);
extern int64_t Library_nLatticesMemUsage(PKINSTANCE);
extern int64_t Library_nPolyLinesMemUsage(PKINSTANCE);
extern int64_t Library_nVoxelsMemUsage(PKINSTANCE);
extern int64_t Library_nVdbFilesMemUsage(PKINSTANCE);
extern int64_t Library_nScalarFieldsMemUsage(PKINSTANCE);
extern int64_t Library_nVectorFieldsMemUsage(PKINSTANCE);
extern int64_t Library_nVdbMetasMemUsage(PKINSTANCE);
extern int64_t Library_nMeshesAllocated(PKINSTANCE);
extern int64_t Library_nLatticesAllocated(PKINSTANCE);
extern int64_t Library_nPolyLinesAllocated(PKINSTANCE);
extern int64_t Library_nVoxelsAllocated(PKINSTANCE);
extern int64_t Library_nVdbFilesAllocated(PKINSTANCE);
extern int64_t Library_nScalarFieldsAllocated(PKINSTANCE);
extern int64_t Library_nVectorFieldsAllocated(PKINSTANCE);
extern int64_t Library_nVdbMetasAllocated(PKINSTANCE);
extern void Library_VoxelsToMm(PKINSTANCE, const PKVector3*, PKVector3*);
extern void Library_MmToVoxels(PKINSTANCE, const PKVector3*, PKVector3*);

// Mesh
extern PKMESH Mesh_hCreate(PKINSTANCE);
extern PKMESH Mesh_hCreateFromVoxels(PKINSTANCE, PKVOXELS);
extern bool Mesh_bIsValid(PKINSTANCE, PKMESH);
extern void Mesh_Destroy(PKINSTANCE, PKMESH);
extern int64_t Mesh_nMemUsage(PKINSTANCE, PKMESH);
extern int32_t Mesh_nAddVertex(PKINSTANCE, PKMESH, const PKVector3*);
extern int32_t Mesh_nVertexCount(PKINSTANCE, PKMESH);
extern void Mesh_GetVertex(PKINSTANCE, PKMESH, int32_t, PKVector3*);
extern int32_t Mesh_nAddTriangle(PKINSTANCE, PKMESH, const PKTriangle*);
extern int32_t Mesh_nTriangleCount(PKINSTANCE, PKMESH);
extern void Mesh_GetTriangle(PKINSTANCE, PKMESH, int32_t, PKTriangle*);
extern void Mesh_GetTriangleV(PKINSTANCE, PKMESH, int32_t, PKVector3*, PKVector3*, PKVector3*);
extern void Mesh_GetBoundingBox(PKINSTANCE, PKMESH, PKBBox3*);

// Lattice
extern PKLATTICE Lattice_hCreate(PKINSTANCE);
extern int64_t Lattice_nMemUsage(PKINSTANCE, PKLATTICE);
extern bool Lattice_bIsValid(PKINSTANCE, PKLATTICE);
extern void Lattice_Destroy(PKINSTANCE, PKLATTICE);
extern void Lattice_AddSphere(PKINSTANCE, PKLATTICE, const PKVector3*, float);
extern void Lattice_AddBeam(PKINSTANCE, PKLATTICE, const PKVector3*, const PKVector3*, float, float, bool);

// Voxels
extern PKVOXELS Voxels_hCreate(PKINSTANCE);
extern PKVOXELS Voxels_hCreateCopy(PKINSTANCE, PKVOXELS);
extern PKVOXELS Voxels_hCreateSphere(PKINSTANCE, const PKVector3*, float);
extern PKVOXELS Voxels_hCreateCapsule(PKINSTANCE, const PKVector3*, const PKVector3*, float, float);
extern PKVOXELS Voxels_hCreateMeshShell(PKINSTANCE, PKMESH, float);
extern bool Voxels_bIsValid(PKINSTANCE, PKVOXELS);
extern void Voxels_Destroy(PKINSTANCE, PKVOXELS);
extern bool Voxels_bDiagnose(PKINSTANCE, PKVOXELS, char psz[PKINFOSTRINGLEN]);
extern bool Voxels_bIsEmpty(PKINSTANCE, PKVOXELS);
extern int64_t Voxels_nMemUsage(PKINSTANCE, PKVOXELS);
extern float Voxels_fVoxelSize(PKINSTANCE, PKVOXELS);
extern void Voxels_BoolAdd(PKINSTANCE, PKVOXELS, PKVOXELS);
extern void Voxels_BoolSubtract(PKINSTANCE, PKVOXELS, PKVOXELS);
extern void Voxels_BoolIntersect(PKINSTANCE, PKVOXELS, PKVOXELS);
extern void Voxels_Offset(PKINSTANCE, PKVOXELS, float);
extern void Voxels_DoubleOffset(PKINSTANCE, PKVOXELS, float, float);
extern void Voxels_TripleOffset(PKINSTANCE, PKVOXELS, float);
extern void Voxels_RenderMesh(PKINSTANCE, PKVOXELS, PKMESH);
extern void Voxels_RenderImplicit(PKINSTANCE, PKVOXELS, const PKBBox3*, PKPFnfSdf);
extern void Voxels_IntersectImplicit(PKINSTANCE, PKVOXELS, PKPFnfSdf);
extern void Voxels_RenderLattice(PKINSTANCE, PKVOXELS, PKLATTICE);
extern void Voxels_ProjectZSlice(PKINSTANCE, PKVOXELS, float, float);
extern bool Voxels_bIsInside(PKINSTANCE, PKVOXELS, const PKVector3*);
extern bool Voxels_bIsEqual(PKINSTANCE, PKVOXELS, PKVOXELS);
extern float Voxels_fCalculateVolume(PKINSTANCE, PKVOXELS);
extern void Voxels_GetSurfaceNormal(PKINSTANCE, PKVOXELS, const PKVector3*, PKVector3*);
extern bool Voxels_bClosestPointOnSurface(PKINSTANCE, PKVOXELS, const PKVector3*, PKVector3*);
extern bool Voxels_bRayCastToSurface(PKINSTANCE, PKVOXELS, const PKVector3*, const PKVector3*, PKVector3*);
extern void Voxels_GetVoxelDimensions(PKINSTANCE, PKVOXELS, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*);
extern void Voxels_GetXSlice(PKINSTANCE, PKVOXELS, int32_t, float*, float*);
extern void Voxels_GetYSlice(PKINSTANCE, PKVOXELS, int32_t, float*, float*);
extern void Voxels_GetZSlice(PKINSTANCE, PKVOXELS, int32_t, float*, float*);
extern void Voxels_GetInterpolatedZSlice(PKINSTANCE, PKVOXELS, float, float*, float*);

// PolyLine
extern PKPOLYLINE PolyLine_hCreate(PKINSTANCE, const PKColorFloat*);
extern bool PolyLine_bIsValid(PKINSTANCE, PKPOLYLINE);
extern void PolyLine_Destroy(PKINSTANCE, PKPOLYLINE);
extern int64_t PolyLine_nMemUsage(PKINSTANCE, PKPOLYLINE);
extern int32_t PolyLine_nAddVertex(PKINSTANCE, PKPOLYLINE, const PKVector3*);
extern int32_t PolyLine_nVertexCount(PKINSTANCE, PKPOLYLINE);
extern void PolyLine_GetVertex(PKINSTANCE, PKPOLYLINE, int32_t, PKVector3*);
extern void PolyLine_GetColor(PKINSTANCE, PKPOLYLINE, PKColorFloat*);
extern void PolyLine_GetBoundingBox(PKINSTANCE, PKPOLYLINE, PKBBox3*);

// VdbFile
extern PKVDBFILE VdbFile_hCreate(PKINSTANCE);
extern PKVDBFILE VdbFile_hCreateFromFile(PKINSTANCE, const char*);
extern bool VdbFile_bIsValid(PKINSTANCE, PKVDBFILE);
extern void VdbFile_Destroy(PKINSTANCE, PKVDBFILE);
extern int64_t VdbFile_nMemUsage(PKINSTANCE, PKVDBFILE);
extern bool VdbFile_bSaveToFile(PKINSTANCE, PKVDBFILE, const char*);
extern PKVOXELS VdbFile_hGetVoxels(PKINSTANCE, PKVDBFILE, int32_t);
extern int32_t VdbFile_nAddVoxels(PKINSTANCE, PKVDBFILE, const char*, PKVOXELS);
extern PKSCALARFIELD VdbFile_hGetScalarField(PKINSTANCE, PKVDBFILE, int32_t);
extern int32_t VdbFile_nAddScalarField(PKINSTANCE, PKVDBFILE, const char*, PKSCALARFIELD);
extern PKVECTORFIELD VdbFile_hGetVectorField(PKINSTANCE, PKVDBFILE, int32_t);
extern int32_t VdbFile_nAddVectorField(PKINSTANCE, PKVDBFILE, const char*, PKVECTORFIELD);
extern int32_t VdbFile_nFieldCount(PKINSTANCE, PKVDBFILE);
extern void VdbFile_GetFieldName(PKINSTANCE, PKVDBFILE, int32_t, char psz[PKINFOSTRINGLEN]);
extern int32_t VdbFile_nFieldType(PKINSTANCE, PKVDBFILE, int32_t);

// ScalarField
extern PKSCALARFIELD ScalarField_hCreate(PKINSTANCE);
extern PKSCALARFIELD ScalarField_hCreateCopy(PKINSTANCE, PKSCALARFIELD);
extern PKSCALARFIELD ScalarField_hCreateFromVoxels(PKINSTANCE, PKVOXELS);
extern PKSCALARFIELD ScalarField_hBuildFromVoxels(PKINSTANCE, PKVOXELS, float, float);
extern bool ScalarField_bIsValid(PKINSTANCE, PKSCALARFIELD);
extern void ScalarField_Destroy(PKINSTANCE, PKSCALARFIELD);
extern int64_t ScalarField_nMemUsage(PKINSTANCE, PKSCALARFIELD);
extern void ScalarField_SetValue(PKINSTANCE, PKSCALARFIELD, const PKVector3*, float);
extern bool ScalarField_bGetValue(PKINSTANCE, PKSCALARFIELD, const PKVector3*, float*);
extern void ScalarField_RemoveValue(PKINSTANCE, PKSCALARFIELD, const PKVector3*);
extern void ScalarField_GetVoxelDimensions(PKINSTANCE, PKSCALARFIELD, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*);
extern void ScalarField_GetSlice(PKINSTANCE, PKSCALARFIELD, int32_t, float*);
extern void ScalarField_TraverseActive(PKINSTANCE, PKSCALARFIELD, PKFnTraverseActiveS);

// VectorField
extern PKVECTORFIELD VectorField_hCreate(PKINSTANCE);
extern PKVECTORFIELD VectorField_hCreateCopy(PKINSTANCE, PKVECTORFIELD);
extern PKVECTORFIELD VectorField_hCreateFromVoxels(PKINSTANCE, PKVOXELS);
extern PKVECTORFIELD VectorField_hBuildFromVoxels(PKINSTANCE, PKVOXELS, const PKVector3*, float);
extern bool VectorField_bIsValid(PKINSTANCE, PKVECTORFIELD);
extern void VectorField_Destroy(PKINSTANCE, PKVECTORFIELD);
extern int64_t VectorField_nMemUsage(PKINSTANCE, PKVECTORFIELD);
extern void VectorField_SetValue(PKINSTANCE, PKVECTORFIELD, const PKVector3*, const PKVector3*);
extern bool VectorField_bGetValue(PKINSTANCE, PKVECTORFIELD, const PKVector3*, PKVector3*);
extern void VectorField_RemoveValue(PKINSTANCE, PKVECTORFIELD, const PKVector3*);
extern void VectorField_TraverseActive(PKINSTANCE, PKVECTORFIELD, PKFnTraverseActiveV);

// Metadata
extern PKMETADATA Metadata_hFromVoxels(PKINSTANCE, PKVOXELS);
extern PKMETADATA Metadata_hFromScalarField(PKINSTANCE, PKSCALARFIELD);
extern PKMETADATA Metadata_hFromVectorField(PKINSTANCE, PKVECTORFIELD);
extern void Metadata_Destroy(PKINSTANCE, PKMETADATA);
extern int32_t Metadata_nCount(PKINSTANCE, PKMETADATA);
extern int32_t Metadata_nNameLengthAt(PKINSTANCE, PKMETADATA, int32_t);
extern bool Metadata_bGetNameAt(PKINSTANCE, PKMETADATA, int32_t, char*, int32_t);
extern int32_t Metadata_nTypeAt(PKINSTANCE, PKMETADATA, const char*);
extern int32_t Metadata_nStringLengthAt(PKINSTANCE, PKMETADATA, const char*);
extern bool Metadata_bGetStringAt(PKINSTANCE, PKMETADATA, const char*, char*, int32_t);
extern bool Metadata_bGetFloatAt(PKINSTANCE, PKMETADATA, const char*, float*);
extern bool Metadata_bGetVectorAt(PKINSTANCE, PKMETADATA, const char*, PKVector3*);
extern void Metadata_SetStringValue(PKINSTANCE, PKMETADATA, const char*, const char*);
extern void Metadata_SetFloatValue(PKINSTANCE, PKMETADATA, const char*, float);
extern void Metadata_SetVectorValue(PKINSTANCE, PKMETADATA, const char*, const PKVector3*);
extern void MetaData_RemoveValue(PKINSTANCE, PKMETADATA, const char*);

// Viewer
extern PKVIEWER Viewer_hCreate(const char*, const PKVector2*, PKFInfo, PKPFUpdateRequested, PKPFKeyPressed, PKPFMouseMoved, PKPFMouseButton, PKPFScrollWheel, PKPFWindowSize);
extern bool Viewer_bIsValid(PKVIEWER);
extern void Viewer_Destroy(PKVIEWER);
extern void Viewer_RequestUpdate(PKVIEWER);
extern bool Viewer_bPoll(PKVIEWER);
extern void Viewer_RequestScreenShot(PKVIEWER, const char*);
extern void Viewer_EnableExperimental(PKVIEWER, bool);
extern void Viewer_RequestClose(PKVIEWER);
extern bool Viewer_bLoadLightSetup(PKVIEWER, const char*, int32_t, const char*, int32_t);
extern void Viewer_AddMesh(PKINSTANCE, PKVIEWER, int32_t, PKMESH);
extern void Viewer_RemoveMesh(PKINSTANCE, PKVIEWER, PKMESH);
extern void Viewer_SetMeshMatrix(PKINSTANCE, PKVIEWER, PKMESH, const PKMatrix4x4*);
extern void Viewer_AddVoxels(PKINSTANCE, PKVIEWER, int32_t, PKVOXELS);
extern void Viewer_RemoveVoxels(PKINSTANCE, PKVIEWER, PKVOXELS);
extern void Viewer_SetVoxelsMatrix(PKINSTANCE, PKVIEWER, PKVOXELS, const PKMatrix4x4*);
extern void Viewer_AddPolyLine(PKINSTANCE, PKVIEWER, int32_t, PKPOLYLINE);
extern void Viewer_RemovePolyLine(PKINSTANCE, PKVIEWER, PKPOLYLINE);
extern void Viewer_SetPolyLineMatrix(PKINSTANCE, PKVIEWER, PKPOLYLINE, const PKMatrix4x4*);
extern void Viewer_RemoveAllObjects(PKVIEWER);
extern void Viewer_SetGroupVisible(PKVIEWER, int32_t, bool);
extern void Viewer_SetGroupMaterial(PKVIEWER, int32_t, const PKColorFloat*, float, float);
extern void Viewer_SetGroupMatrix(PKVIEWER, int32_t, const PKMatrix4x4*);
extern void Viewer_EnableGroupWarnOverhang(PKVIEWER, int32_t, float, float);
extern void Viewer_DisableGroupWarnOverhang(PKVIEWER, int32_t);
extern void Viewer_GetBoundingBox(PKVIEWER, PKBBox3*);
extern PKGPUTEX Viewer_GpuTex_hCreate(PKVIEWER, int, int, const char*);
extern void Viewer_GpuTex_Refresh(PKVIEWER, PKGPUTEX, const char*);
extern void Viewer_GpuTex_MarkForCleanup(PKVIEWER, PKGPUTEX);
extern PKQUAD Viewer_Quad_hCreate(PKVIEWER, PKGPUTEX, PKColorFloat, float, const PKMatrix4x4*, bool, bool, bool);
extern void Viewer_Quad_Destroy(PKVIEWER, PKQUAD);
extern void Viewer_Quad_SetMatrix(PKVIEWER, PKQUAD, const PKMatrix4x4*);
extern PKGUI Viewer_SideBar_hCreate(PKVIEWER, bool, int, int, int, PKColorFloat, PKColorFloat);
extern void Viewer_SideBar_Destroy(PKVIEWER, PKGUI);

#endif