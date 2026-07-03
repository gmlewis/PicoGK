#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

typedef struct { float X, Y; } PKVector2;
typedef struct { float X, Y, Z; } PKVector3;
typedef struct { float X, Y, Z, W; } PKVector4;
typedef struct { int32_t A, B, C; } PKTriangle;
typedef struct { PKVector3 vecMin, vecMax; } PKBBox3;
typedef struct { PKVector4 vec1, vec2, vec3, vec4; } PKMatrix4x4;
typedef struct { float R, G, B, A; } PKColorFloat;
typedef uint64_t PKHANDLE;
typedef PKHANDLE PKINSTANCE, PKMESH, PKLATTICE, PKPOLYLINE, PKVOXELS;
typedef PKHANDLE PKVDBFILE, PKSCALARFIELD, PKVECTORFIELD, PKMETADATA;
typedef void* PKVIEWER;
typedef PKHANDLE PKGPUTEX, PKQUAD, PKGUI;
typedef float (*PKPFnfSdf)(const PKVector3*);
typedef void (*PKFnTraverseActiveS)(const PKVector3*, float);
typedef void (*PKFnTraverseActiveV)(const PKVector3*, const PKVector3*);
typedef void (*PKFInfo)(const char*, bool);
typedef void (*PKPFUpdateRequested)(void*, const PKVector2*, PKColorFloat*, PKMatrix4x4*, PKVector3*);
typedef void (*PKPFKeyPressed)(void*, int32_t, int32_t, int32_t, int32_t);
typedef void (*PKPFMouseMoved)(void*, const PKVector2*, bool, bool, bool, bool);
typedef void (*PKPFMouseButton)(void*, int32_t, int32_t, int32_t, const PKVector2*);
typedef void (*PKPFScrollWheel)(void*, const PKVector2*, const PKVector2*, bool, bool, bool, bool);
typedef void (*PKPFWindowSize)(void*, const PKVector2*);
typedef const PKVector3* const_PKVector3_ptr;
typedef const PKVector2* const_PKVector2_ptr;
typedef const char* const_char_ptr;
typedef const PKBBox3* const_PKBBox3_ptr;
typedef const PKMatrix4x4* const_PKMatrix4x4_ptr;
typedef const PKColorFloat* const_PKColorFloat_ptr;
typedef const PKTriangle* const_PKTriangle_ptr;

static void* g_picogk_lib = NULL;

int picogk_dlopen(const char* path) {
    g_picogk_lib = dlopen(path, RTLD_NOW | RTLD_GLOBAL);
    return g_picogk_lib ? 0 : -1;
}

typedef void (*pfn_Library_GetName)(char*);
static pfn_Library_GetName p_Library_GetName = NULL;
void Library_GetName(char* psz) {
    if (!p_Library_GetName) p_Library_GetName = (pfn_Library_GetName)dlsym(g_picogk_lib, "Library_GetName");
    if (p_Library_GetName) p_Library_GetName(psz);
}

typedef void (*pfn_Library_GetVersion)(char*);
static pfn_Library_GetVersion p_Library_GetVersion = NULL;
void Library_GetVersion(char* psz) {
    if (!p_Library_GetVersion) p_Library_GetVersion = (pfn_Library_GetVersion)dlsym(g_picogk_lib, "Library_GetVersion");
    if (p_Library_GetVersion) p_Library_GetVersion(psz);
}

typedef void (*pfn_Library_GetBuildInfo)(char*);
static pfn_Library_GetBuildInfo p_Library_GetBuildInfo = NULL;
void Library_GetBuildInfo(char* psz) {
    if (!p_Library_GetBuildInfo) p_Library_GetBuildInfo = (pfn_Library_GetBuildInfo)dlsym(g_picogk_lib, "Library_GetBuildInfo");
    if (p_Library_GetBuildInfo) p_Library_GetBuildInfo(psz);
}

typedef PKINSTANCE (*pfn_Library_hCreateInstance)(float);
static pfn_Library_hCreateInstance p_Library_hCreateInstance = NULL;
PKINSTANCE Library_hCreateInstance(float fVoxelSizeMM) {
    if (!p_Library_hCreateInstance) p_Library_hCreateInstance = (pfn_Library_hCreateInstance)dlsym(g_picogk_lib, "Library_hCreateInstance");
    return p_Library_hCreateInstance ? p_Library_hCreateInstance(fVoxelSizeMM) : (PKINSTANCE)0;
}

typedef void (*pfn_Library_DestroyInstance)(PKINSTANCE);
static pfn_Library_DestroyInstance p_Library_DestroyInstance = NULL;
void Library_DestroyInstance(PKINSTANCE hThis) {
    if (!p_Library_DestroyInstance) p_Library_DestroyInstance = (pfn_Library_DestroyInstance)dlsym(g_picogk_lib, "Library_DestroyInstance");
    if (p_Library_DestroyInstance) p_Library_DestroyInstance(hThis);
}

typedef int64_t (*pfn_Library_nTotalMemUsage)(PKINSTANCE);
static pfn_Library_nTotalMemUsage p_Library_nTotalMemUsage = NULL;
int64_t Library_nTotalMemUsage(PKINSTANCE hThis) {
    if (!p_Library_nTotalMemUsage) p_Library_nTotalMemUsage = (pfn_Library_nTotalMemUsage)dlsym(g_picogk_lib, "Library_nTotalMemUsage");
    return p_Library_nTotalMemUsage ? p_Library_nTotalMemUsage(hThis) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nMeshesMemUsage)(PKINSTANCE);
static pfn_Library_nMeshesMemUsage p_Library_nMeshesMemUsage = NULL;
int64_t Library_nMeshesMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nMeshesMemUsage) p_Library_nMeshesMemUsage = (pfn_Library_nMeshesMemUsage)dlsym(g_picogk_lib, "Library_nMeshesMemUsage");
    return p_Library_nMeshesMemUsage ? p_Library_nMeshesMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nLatticesMemUsage)(PKINSTANCE);
static pfn_Library_nLatticesMemUsage p_Library_nLatticesMemUsage = NULL;
int64_t Library_nLatticesMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nLatticesMemUsage) p_Library_nLatticesMemUsage = (pfn_Library_nLatticesMemUsage)dlsym(g_picogk_lib, "Library_nLatticesMemUsage");
    return p_Library_nLatticesMemUsage ? p_Library_nLatticesMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nPolyLinesMemUsage)(PKINSTANCE);
static pfn_Library_nPolyLinesMemUsage p_Library_nPolyLinesMemUsage = NULL;
int64_t Library_nPolyLinesMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nPolyLinesMemUsage) p_Library_nPolyLinesMemUsage = (pfn_Library_nPolyLinesMemUsage)dlsym(g_picogk_lib, "Library_nPolyLinesMemUsage");
    return p_Library_nPolyLinesMemUsage ? p_Library_nPolyLinesMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVoxelsMemUsage)(PKINSTANCE);
static pfn_Library_nVoxelsMemUsage p_Library_nVoxelsMemUsage = NULL;
int64_t Library_nVoxelsMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nVoxelsMemUsage) p_Library_nVoxelsMemUsage = (pfn_Library_nVoxelsMemUsage)dlsym(g_picogk_lib, "Library_nVoxelsMemUsage");
    return p_Library_nVoxelsMemUsage ? p_Library_nVoxelsMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVdbFilesMemUsage)(PKINSTANCE);
static pfn_Library_nVdbFilesMemUsage p_Library_nVdbFilesMemUsage = NULL;
int64_t Library_nVdbFilesMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nVdbFilesMemUsage) p_Library_nVdbFilesMemUsage = (pfn_Library_nVdbFilesMemUsage)dlsym(g_picogk_lib, "Library_nVdbFilesMemUsage");
    return p_Library_nVdbFilesMemUsage ? p_Library_nVdbFilesMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nScalarFieldsMemUsage)(PKINSTANCE);
static pfn_Library_nScalarFieldsMemUsage p_Library_nScalarFieldsMemUsage = NULL;
int64_t Library_nScalarFieldsMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nScalarFieldsMemUsage) p_Library_nScalarFieldsMemUsage = (pfn_Library_nScalarFieldsMemUsage)dlsym(g_picogk_lib, "Library_nScalarFieldsMemUsage");
    return p_Library_nScalarFieldsMemUsage ? p_Library_nScalarFieldsMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVectorFieldsMemUsage)(PKINSTANCE);
static pfn_Library_nVectorFieldsMemUsage p_Library_nVectorFieldsMemUsage = NULL;
int64_t Library_nVectorFieldsMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nVectorFieldsMemUsage) p_Library_nVectorFieldsMemUsage = (pfn_Library_nVectorFieldsMemUsage)dlsym(g_picogk_lib, "Library_nVectorFieldsMemUsage");
    return p_Library_nVectorFieldsMemUsage ? p_Library_nVectorFieldsMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVdbMetasMemUsage)(PKINSTANCE);
static pfn_Library_nVdbMetasMemUsage p_Library_nVdbMetasMemUsage = NULL;
int64_t Library_nVdbMetasMemUsage(PKINSTANCE arg0) {
    if (!p_Library_nVdbMetasMemUsage) p_Library_nVdbMetasMemUsage = (pfn_Library_nVdbMetasMemUsage)dlsym(g_picogk_lib, "Library_nVdbMetasMemUsage");
    return p_Library_nVdbMetasMemUsage ? p_Library_nVdbMetasMemUsage(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nMeshesAllocated)(PKINSTANCE);
static pfn_Library_nMeshesAllocated p_Library_nMeshesAllocated = NULL;
int64_t Library_nMeshesAllocated(PKINSTANCE arg0) {
    if (!p_Library_nMeshesAllocated) p_Library_nMeshesAllocated = (pfn_Library_nMeshesAllocated)dlsym(g_picogk_lib, "Library_nMeshesAllocated");
    return p_Library_nMeshesAllocated ? p_Library_nMeshesAllocated(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nLatticesAllocated)(PKINSTANCE);
static pfn_Library_nLatticesAllocated p_Library_nLatticesAllocated = NULL;
int64_t Library_nLatticesAllocated(PKINSTANCE arg0) {
    if (!p_Library_nLatticesAllocated) p_Library_nLatticesAllocated = (pfn_Library_nLatticesAllocated)dlsym(g_picogk_lib, "Library_nLatticesAllocated");
    return p_Library_nLatticesAllocated ? p_Library_nLatticesAllocated(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nPolyLinesAllocated)(PKINSTANCE);
static pfn_Library_nPolyLinesAllocated p_Library_nPolyLinesAllocated = NULL;
int64_t Library_nPolyLinesAllocated(PKINSTANCE arg0) {
    if (!p_Library_nPolyLinesAllocated) p_Library_nPolyLinesAllocated = (pfn_Library_nPolyLinesAllocated)dlsym(g_picogk_lib, "Library_nPolyLinesAllocated");
    return p_Library_nPolyLinesAllocated ? p_Library_nPolyLinesAllocated(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVoxelsAllocated)(PKINSTANCE);
static pfn_Library_nVoxelsAllocated p_Library_nVoxelsAllocated = NULL;
int64_t Library_nVoxelsAllocated(PKINSTANCE arg0) {
    if (!p_Library_nVoxelsAllocated) p_Library_nVoxelsAllocated = (pfn_Library_nVoxelsAllocated)dlsym(g_picogk_lib, "Library_nVoxelsAllocated");
    return p_Library_nVoxelsAllocated ? p_Library_nVoxelsAllocated(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVdbFilesAllocated)(PKINSTANCE);
static pfn_Library_nVdbFilesAllocated p_Library_nVdbFilesAllocated = NULL;
int64_t Library_nVdbFilesAllocated(PKINSTANCE arg0) {
    if (!p_Library_nVdbFilesAllocated) p_Library_nVdbFilesAllocated = (pfn_Library_nVdbFilesAllocated)dlsym(g_picogk_lib, "Library_nVdbFilesAllocated");
    return p_Library_nVdbFilesAllocated ? p_Library_nVdbFilesAllocated(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nScalarFieldsAllocated)(PKINSTANCE);
static pfn_Library_nScalarFieldsAllocated p_Library_nScalarFieldsAllocated = NULL;
int64_t Library_nScalarFieldsAllocated(PKINSTANCE arg0) {
    if (!p_Library_nScalarFieldsAllocated) p_Library_nScalarFieldsAllocated = (pfn_Library_nScalarFieldsAllocated)dlsym(g_picogk_lib, "Library_nScalarFieldsAllocated");
    return p_Library_nScalarFieldsAllocated ? p_Library_nScalarFieldsAllocated(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVectorFieldsAllocated)(PKINSTANCE);
static pfn_Library_nVectorFieldsAllocated p_Library_nVectorFieldsAllocated = NULL;
int64_t Library_nVectorFieldsAllocated(PKINSTANCE arg0) {
    if (!p_Library_nVectorFieldsAllocated) p_Library_nVectorFieldsAllocated = (pfn_Library_nVectorFieldsAllocated)dlsym(g_picogk_lib, "Library_nVectorFieldsAllocated");
    return p_Library_nVectorFieldsAllocated ? p_Library_nVectorFieldsAllocated(arg0) : (int64_t)0;
}

typedef int64_t (*pfn_Library_nVdbMetasAllocated)(PKINSTANCE);
static pfn_Library_nVdbMetasAllocated p_Library_nVdbMetasAllocated = NULL;
int64_t Library_nVdbMetasAllocated(PKINSTANCE arg0) {
    if (!p_Library_nVdbMetasAllocated) p_Library_nVdbMetasAllocated = (pfn_Library_nVdbMetasAllocated)dlsym(g_picogk_lib, "Library_nVdbMetasAllocated");
    return p_Library_nVdbMetasAllocated ? p_Library_nVdbMetasAllocated(arg0) : (int64_t)0;
}

typedef void (*pfn_Library_VoxelsToMm)(PKINSTANCE, const_PKVector3_ptr, PKVector3*);
static pfn_Library_VoxelsToMm p_Library_VoxelsToMm = NULL;
void Library_VoxelsToMm(PKINSTANCE arg0, const_PKVector3_ptr arg1, PKVector3* arg2) {
    if (!p_Library_VoxelsToMm) p_Library_VoxelsToMm = (pfn_Library_VoxelsToMm)dlsym(g_picogk_lib, "Library_VoxelsToMm");
    if (p_Library_VoxelsToMm) p_Library_VoxelsToMm(arg0, arg1, arg2);
}

typedef void (*pfn_Library_MmToVoxels)(PKINSTANCE, const_PKVector3_ptr, PKVector3*);
static pfn_Library_MmToVoxels p_Library_MmToVoxels = NULL;
void Library_MmToVoxels(PKINSTANCE arg0, const_PKVector3_ptr arg1, PKVector3* arg2) {
    if (!p_Library_MmToVoxels) p_Library_MmToVoxels = (pfn_Library_MmToVoxels)dlsym(g_picogk_lib, "Library_MmToVoxels");
    if (p_Library_MmToVoxels) p_Library_MmToVoxels(arg0, arg1, arg2);
}

typedef PKMESH (*pfn_Mesh_hCreate)(PKINSTANCE);
static pfn_Mesh_hCreate p_Mesh_hCreate = NULL;
PKMESH Mesh_hCreate(PKINSTANCE arg0) {
    if (!p_Mesh_hCreate) p_Mesh_hCreate = (pfn_Mesh_hCreate)dlsym(g_picogk_lib, "Mesh_hCreate");
    return p_Mesh_hCreate ? p_Mesh_hCreate(arg0) : (PKMESH)0;
}

typedef PKMESH (*pfn_Mesh_hCreateFromVoxels)(PKINSTANCE, PKVOXELS);
static pfn_Mesh_hCreateFromVoxels p_Mesh_hCreateFromVoxels = NULL;
PKMESH Mesh_hCreateFromVoxels(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Mesh_hCreateFromVoxels) p_Mesh_hCreateFromVoxels = (pfn_Mesh_hCreateFromVoxels)dlsym(g_picogk_lib, "Mesh_hCreateFromVoxels");
    return p_Mesh_hCreateFromVoxels ? p_Mesh_hCreateFromVoxels(arg0, arg1) : (PKMESH)0;
}

typedef bool (*pfn_Mesh_bIsValid)(PKINSTANCE, PKMESH);
static pfn_Mesh_bIsValid p_Mesh_bIsValid = NULL;
bool Mesh_bIsValid(PKINSTANCE arg0, PKMESH arg1) {
    if (!p_Mesh_bIsValid) p_Mesh_bIsValid = (pfn_Mesh_bIsValid)dlsym(g_picogk_lib, "Mesh_bIsValid");
    return p_Mesh_bIsValid ? p_Mesh_bIsValid(arg0, arg1) : (bool)0;
}

typedef void (*pfn_Mesh_Destroy)(PKINSTANCE, PKMESH);
static pfn_Mesh_Destroy p_Mesh_Destroy = NULL;
void Mesh_Destroy(PKINSTANCE arg0, PKMESH arg1) {
    if (!p_Mesh_Destroy) p_Mesh_Destroy = (pfn_Mesh_Destroy)dlsym(g_picogk_lib, "Mesh_Destroy");
    if (p_Mesh_Destroy) p_Mesh_Destroy(arg0, arg1);
}

typedef int64_t (*pfn_Mesh_nMemUsage)(PKINSTANCE, PKMESH);
static pfn_Mesh_nMemUsage p_Mesh_nMemUsage = NULL;
int64_t Mesh_nMemUsage(PKINSTANCE arg0, PKMESH arg1) {
    if (!p_Mesh_nMemUsage) p_Mesh_nMemUsage = (pfn_Mesh_nMemUsage)dlsym(g_picogk_lib, "Mesh_nMemUsage");
    return p_Mesh_nMemUsage ? p_Mesh_nMemUsage(arg0, arg1) : (int64_t)0;
}

typedef int32_t (*pfn_Mesh_nAddVertex)(PKINSTANCE, PKMESH, const_PKVector3_ptr);
static pfn_Mesh_nAddVertex p_Mesh_nAddVertex = NULL;
int32_t Mesh_nAddVertex(PKINSTANCE arg0, PKMESH arg1, const_PKVector3_ptr arg2) {
    if (!p_Mesh_nAddVertex) p_Mesh_nAddVertex = (pfn_Mesh_nAddVertex)dlsym(g_picogk_lib, "Mesh_nAddVertex");
    return p_Mesh_nAddVertex ? p_Mesh_nAddVertex(arg0, arg1, arg2) : (int32_t)0;
}

typedef int32_t (*pfn_Mesh_nVertexCount)(PKINSTANCE, PKMESH);
static pfn_Mesh_nVertexCount p_Mesh_nVertexCount = NULL;
int32_t Mesh_nVertexCount(PKINSTANCE arg0, PKMESH arg1) {
    if (!p_Mesh_nVertexCount) p_Mesh_nVertexCount = (pfn_Mesh_nVertexCount)dlsym(g_picogk_lib, "Mesh_nVertexCount");
    return p_Mesh_nVertexCount ? p_Mesh_nVertexCount(arg0, arg1) : (int32_t)0;
}

typedef void (*pfn_Mesh_GetVertex)(PKINSTANCE, PKMESH, int32_t, PKVector3*);
static pfn_Mesh_GetVertex p_Mesh_GetVertex = NULL;
void Mesh_GetVertex(PKINSTANCE arg0, PKMESH arg1, int32_t arg2, PKVector3* arg3) {
    if (!p_Mesh_GetVertex) p_Mesh_GetVertex = (pfn_Mesh_GetVertex)dlsym(g_picogk_lib, "Mesh_GetVertex");
    if (p_Mesh_GetVertex) p_Mesh_GetVertex(arg0, arg1, arg2, arg3);
}

typedef int32_t (*pfn_Mesh_nAddTriangle)(PKINSTANCE, PKMESH, const_PKTriangle_ptr);
static pfn_Mesh_nAddTriangle p_Mesh_nAddTriangle = NULL;
int32_t Mesh_nAddTriangle(PKINSTANCE arg0, PKMESH arg1, const_PKTriangle_ptr arg2) {
    if (!p_Mesh_nAddTriangle) p_Mesh_nAddTriangle = (pfn_Mesh_nAddTriangle)dlsym(g_picogk_lib, "Mesh_nAddTriangle");
    return p_Mesh_nAddTriangle ? p_Mesh_nAddTriangle(arg0, arg1, arg2) : (int32_t)0;
}

typedef int32_t (*pfn_Mesh_nTriangleCount)(PKINSTANCE, PKMESH);
static pfn_Mesh_nTriangleCount p_Mesh_nTriangleCount = NULL;
int32_t Mesh_nTriangleCount(PKINSTANCE arg0, PKMESH arg1) {
    if (!p_Mesh_nTriangleCount) p_Mesh_nTriangleCount = (pfn_Mesh_nTriangleCount)dlsym(g_picogk_lib, "Mesh_nTriangleCount");
    return p_Mesh_nTriangleCount ? p_Mesh_nTriangleCount(arg0, arg1) : (int32_t)0;
}

typedef void (*pfn_Mesh_GetTriangle)(PKINSTANCE, PKMESH, int32_t, PKTriangle*);
static pfn_Mesh_GetTriangle p_Mesh_GetTriangle = NULL;
void Mesh_GetTriangle(PKINSTANCE arg0, PKMESH arg1, int32_t arg2, PKTriangle* arg3) {
    if (!p_Mesh_GetTriangle) p_Mesh_GetTriangle = (pfn_Mesh_GetTriangle)dlsym(g_picogk_lib, "Mesh_GetTriangle");
    if (p_Mesh_GetTriangle) p_Mesh_GetTriangle(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Mesh_GetTriangleV)(PKINSTANCE, PKMESH, int32_t, PKVector3*, PKVector3*, PKVector3*);
static pfn_Mesh_GetTriangleV p_Mesh_GetTriangleV = NULL;
void Mesh_GetTriangleV(PKINSTANCE arg0, PKMESH arg1, int32_t arg2, PKVector3* arg3, PKVector3* arg4, PKVector3* arg5) {
    if (!p_Mesh_GetTriangleV) p_Mesh_GetTriangleV = (pfn_Mesh_GetTriangleV)dlsym(g_picogk_lib, "Mesh_GetTriangleV");
    if (p_Mesh_GetTriangleV) p_Mesh_GetTriangleV(arg0, arg1, arg2, arg3, arg4, arg5);
}

typedef void (*pfn_Mesh_GetBoundingBox)(PKINSTANCE, PKMESH, PKBBox3*);
static pfn_Mesh_GetBoundingBox p_Mesh_GetBoundingBox = NULL;
void Mesh_GetBoundingBox(PKINSTANCE arg0, PKMESH arg1, PKBBox3* arg2) {
    if (!p_Mesh_GetBoundingBox) p_Mesh_GetBoundingBox = (pfn_Mesh_GetBoundingBox)dlsym(g_picogk_lib, "Mesh_GetBoundingBox");
    if (p_Mesh_GetBoundingBox) p_Mesh_GetBoundingBox(arg0, arg1, arg2);
}

typedef PKLATTICE (*pfn_Lattice_hCreate)(PKINSTANCE);
static pfn_Lattice_hCreate p_Lattice_hCreate = NULL;
PKLATTICE Lattice_hCreate(PKINSTANCE arg0) {
    if (!p_Lattice_hCreate) p_Lattice_hCreate = (pfn_Lattice_hCreate)dlsym(g_picogk_lib, "Lattice_hCreate");
    return p_Lattice_hCreate ? p_Lattice_hCreate(arg0) : (PKLATTICE)0;
}

typedef int64_t (*pfn_Lattice_nMemUsage)(PKINSTANCE, PKLATTICE);
static pfn_Lattice_nMemUsage p_Lattice_nMemUsage = NULL;
int64_t Lattice_nMemUsage(PKINSTANCE arg0, PKLATTICE arg1) {
    if (!p_Lattice_nMemUsage) p_Lattice_nMemUsage = (pfn_Lattice_nMemUsage)dlsym(g_picogk_lib, "Lattice_nMemUsage");
    return p_Lattice_nMemUsage ? p_Lattice_nMemUsage(arg0, arg1) : (int64_t)0;
}

typedef bool (*pfn_Lattice_bIsValid)(PKINSTANCE, PKLATTICE);
static pfn_Lattice_bIsValid p_Lattice_bIsValid = NULL;
bool Lattice_bIsValid(PKINSTANCE arg0, PKLATTICE arg1) {
    if (!p_Lattice_bIsValid) p_Lattice_bIsValid = (pfn_Lattice_bIsValid)dlsym(g_picogk_lib, "Lattice_bIsValid");
    return p_Lattice_bIsValid ? p_Lattice_bIsValid(arg0, arg1) : (bool)0;
}

typedef void (*pfn_Lattice_Destroy)(PKINSTANCE, PKLATTICE);
static pfn_Lattice_Destroy p_Lattice_Destroy = NULL;
void Lattice_Destroy(PKINSTANCE arg0, PKLATTICE arg1) {
    if (!p_Lattice_Destroy) p_Lattice_Destroy = (pfn_Lattice_Destroy)dlsym(g_picogk_lib, "Lattice_Destroy");
    if (p_Lattice_Destroy) p_Lattice_Destroy(arg0, arg1);
}

typedef void (*pfn_Lattice_AddSphere)(PKINSTANCE, PKLATTICE, const_PKVector3_ptr, float);
static pfn_Lattice_AddSphere p_Lattice_AddSphere = NULL;
void Lattice_AddSphere(PKINSTANCE arg0, PKLATTICE arg1, const_PKVector3_ptr arg2, float arg3) {
    if (!p_Lattice_AddSphere) p_Lattice_AddSphere = (pfn_Lattice_AddSphere)dlsym(g_picogk_lib, "Lattice_AddSphere");
    if (p_Lattice_AddSphere) p_Lattice_AddSphere(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Lattice_AddBeam)(PKINSTANCE, PKLATTICE, const_PKVector3_ptr, const_PKVector3_ptr, float, float, bool);
static pfn_Lattice_AddBeam p_Lattice_AddBeam = NULL;
void Lattice_AddBeam(PKINSTANCE arg0, PKLATTICE arg1, const_PKVector3_ptr arg2, const_PKVector3_ptr arg3, float arg4, float arg5, bool arg6) {
    if (!p_Lattice_AddBeam) p_Lattice_AddBeam = (pfn_Lattice_AddBeam)dlsym(g_picogk_lib, "Lattice_AddBeam");
    if (p_Lattice_AddBeam) p_Lattice_AddBeam(arg0, arg1, arg2, arg3, arg4, arg5, arg6);
}

typedef PKVOXELS (*pfn_Voxels_hCreate)(PKINSTANCE);
static pfn_Voxels_hCreate p_Voxels_hCreate = NULL;
PKVOXELS Voxels_hCreate(PKINSTANCE arg0) {
    if (!p_Voxels_hCreate) p_Voxels_hCreate = (pfn_Voxels_hCreate)dlsym(g_picogk_lib, "Voxels_hCreate");
    return p_Voxels_hCreate ? p_Voxels_hCreate(arg0) : (PKVOXELS)0;
}

typedef PKVOXELS (*pfn_Voxels_hCreateCopy)(PKINSTANCE, PKVOXELS);
static pfn_Voxels_hCreateCopy p_Voxels_hCreateCopy = NULL;
PKVOXELS Voxels_hCreateCopy(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Voxels_hCreateCopy) p_Voxels_hCreateCopy = (pfn_Voxels_hCreateCopy)dlsym(g_picogk_lib, "Voxels_hCreateCopy");
    return p_Voxels_hCreateCopy ? p_Voxels_hCreateCopy(arg0, arg1) : (PKVOXELS)0;
}

typedef PKVOXELS (*pfn_Voxels_hCreateSphere)(PKINSTANCE, const_PKVector3_ptr, float);
static pfn_Voxels_hCreateSphere p_Voxels_hCreateSphere = NULL;
PKVOXELS Voxels_hCreateSphere(PKINSTANCE arg0, const_PKVector3_ptr arg1, float arg2) {
    if (!p_Voxels_hCreateSphere) p_Voxels_hCreateSphere = (pfn_Voxels_hCreateSphere)dlsym(g_picogk_lib, "Voxels_hCreateSphere");
    return p_Voxels_hCreateSphere ? p_Voxels_hCreateSphere(arg0, arg1, arg2) : (PKVOXELS)0;
}

typedef PKVOXELS (*pfn_Voxels_hCreateCapsule)(PKINSTANCE, const_PKVector3_ptr, const_PKVector3_ptr, float, float);
static pfn_Voxels_hCreateCapsule p_Voxels_hCreateCapsule = NULL;
PKVOXELS Voxels_hCreateCapsule(PKINSTANCE arg0, const_PKVector3_ptr arg1, const_PKVector3_ptr arg2, float arg3, float arg4) {
    if (!p_Voxels_hCreateCapsule) p_Voxels_hCreateCapsule = (pfn_Voxels_hCreateCapsule)dlsym(g_picogk_lib, "Voxels_hCreateCapsule");
    return p_Voxels_hCreateCapsule ? p_Voxels_hCreateCapsule(arg0, arg1, arg2, arg3, arg4) : (PKVOXELS)0;
}

typedef PKVOXELS (*pfn_Voxels_hCreateMeshShell)(PKINSTANCE, PKMESH, float);
static pfn_Voxels_hCreateMeshShell p_Voxels_hCreateMeshShell = NULL;
PKVOXELS Voxels_hCreateMeshShell(PKINSTANCE arg0, PKMESH arg1, float arg2) {
    if (!p_Voxels_hCreateMeshShell) p_Voxels_hCreateMeshShell = (pfn_Voxels_hCreateMeshShell)dlsym(g_picogk_lib, "Voxels_hCreateMeshShell");
    return p_Voxels_hCreateMeshShell ? p_Voxels_hCreateMeshShell(arg0, arg1, arg2) : (PKVOXELS)0;
}

typedef bool (*pfn_Voxels_bIsValid)(PKINSTANCE, PKVOXELS);
static pfn_Voxels_bIsValid p_Voxels_bIsValid = NULL;
bool Voxels_bIsValid(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Voxels_bIsValid) p_Voxels_bIsValid = (pfn_Voxels_bIsValid)dlsym(g_picogk_lib, "Voxels_bIsValid");
    return p_Voxels_bIsValid ? p_Voxels_bIsValid(arg0, arg1) : (bool)0;
}

typedef void (*pfn_Voxels_Destroy)(PKINSTANCE, PKVOXELS);
static pfn_Voxels_Destroy p_Voxels_Destroy = NULL;
void Voxels_Destroy(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Voxels_Destroy) p_Voxels_Destroy = (pfn_Voxels_Destroy)dlsym(g_picogk_lib, "Voxels_Destroy");
    if (p_Voxels_Destroy) p_Voxels_Destroy(arg0, arg1);
}

typedef bool (*pfn_Voxels_bDiagnose)(PKINSTANCE, PKVOXELS, char*);
static pfn_Voxels_bDiagnose p_Voxels_bDiagnose = NULL;
bool Voxels_bDiagnose(PKINSTANCE arg0, PKVOXELS arg1, char* psz) {
    if (!p_Voxels_bDiagnose) p_Voxels_bDiagnose = (pfn_Voxels_bDiagnose)dlsym(g_picogk_lib, "Voxels_bDiagnose");
    return p_Voxels_bDiagnose ? p_Voxels_bDiagnose(arg0, arg1, psz) : (bool)0;
}

typedef bool (*pfn_Voxels_bIsEmpty)(PKINSTANCE, PKVOXELS);
static pfn_Voxels_bIsEmpty p_Voxels_bIsEmpty = NULL;
bool Voxels_bIsEmpty(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Voxels_bIsEmpty) p_Voxels_bIsEmpty = (pfn_Voxels_bIsEmpty)dlsym(g_picogk_lib, "Voxels_bIsEmpty");
    return p_Voxels_bIsEmpty ? p_Voxels_bIsEmpty(arg0, arg1) : (bool)0;
}

typedef int64_t (*pfn_Voxels_nMemUsage)(PKINSTANCE, PKVOXELS);
static pfn_Voxels_nMemUsage p_Voxels_nMemUsage = NULL;
int64_t Voxels_nMemUsage(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Voxels_nMemUsage) p_Voxels_nMemUsage = (pfn_Voxels_nMemUsage)dlsym(g_picogk_lib, "Voxels_nMemUsage");
    return p_Voxels_nMemUsage ? p_Voxels_nMemUsage(arg0, arg1) : (int64_t)0;
}

typedef float (*pfn_Voxels_fVoxelSize)(PKINSTANCE, PKVOXELS);
static pfn_Voxels_fVoxelSize p_Voxels_fVoxelSize = NULL;
float Voxels_fVoxelSize(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Voxels_fVoxelSize) p_Voxels_fVoxelSize = (pfn_Voxels_fVoxelSize)dlsym(g_picogk_lib, "Voxels_fVoxelSize");
    return p_Voxels_fVoxelSize ? p_Voxels_fVoxelSize(arg0, arg1) : (float)0;
}

typedef void (*pfn_Voxels_BoolAdd)(PKINSTANCE, PKVOXELS, PKVOXELS);
static pfn_Voxels_BoolAdd p_Voxels_BoolAdd = NULL;
void Voxels_BoolAdd(PKINSTANCE arg0, PKVOXELS arg1, PKVOXELS arg2) {
    if (!p_Voxels_BoolAdd) p_Voxels_BoolAdd = (pfn_Voxels_BoolAdd)dlsym(g_picogk_lib, "Voxels_BoolAdd");
    if (p_Voxels_BoolAdd) p_Voxels_BoolAdd(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_BoolSubtract)(PKINSTANCE, PKVOXELS, PKVOXELS);
static pfn_Voxels_BoolSubtract p_Voxels_BoolSubtract = NULL;
void Voxels_BoolSubtract(PKINSTANCE arg0, PKVOXELS arg1, PKVOXELS arg2) {
    if (!p_Voxels_BoolSubtract) p_Voxels_BoolSubtract = (pfn_Voxels_BoolSubtract)dlsym(g_picogk_lib, "Voxels_BoolSubtract");
    if (p_Voxels_BoolSubtract) p_Voxels_BoolSubtract(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_BoolIntersect)(PKINSTANCE, PKVOXELS, PKVOXELS);
static pfn_Voxels_BoolIntersect p_Voxels_BoolIntersect = NULL;
void Voxels_BoolIntersect(PKINSTANCE arg0, PKVOXELS arg1, PKVOXELS arg2) {
    if (!p_Voxels_BoolIntersect) p_Voxels_BoolIntersect = (pfn_Voxels_BoolIntersect)dlsym(g_picogk_lib, "Voxels_BoolIntersect");
    if (p_Voxels_BoolIntersect) p_Voxels_BoolIntersect(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_Offset)(PKINSTANCE, PKVOXELS, float);
static pfn_Voxels_Offset p_Voxels_Offset = NULL;
void Voxels_Offset(PKINSTANCE arg0, PKVOXELS arg1, float arg2) {
    if (!p_Voxels_Offset) p_Voxels_Offset = (pfn_Voxels_Offset)dlsym(g_picogk_lib, "Voxels_Offset");
    if (p_Voxels_Offset) p_Voxels_Offset(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_DoubleOffset)(PKINSTANCE, PKVOXELS, float, float);
static pfn_Voxels_DoubleOffset p_Voxels_DoubleOffset = NULL;
void Voxels_DoubleOffset(PKINSTANCE arg0, PKVOXELS arg1, float arg2, float arg3) {
    if (!p_Voxels_DoubleOffset) p_Voxels_DoubleOffset = (pfn_Voxels_DoubleOffset)dlsym(g_picogk_lib, "Voxels_DoubleOffset");
    if (p_Voxels_DoubleOffset) p_Voxels_DoubleOffset(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Voxels_TripleOffset)(PKINSTANCE, PKVOXELS, float);
static pfn_Voxels_TripleOffset p_Voxels_TripleOffset = NULL;
void Voxels_TripleOffset(PKINSTANCE arg0, PKVOXELS arg1, float arg2) {
    if (!p_Voxels_TripleOffset) p_Voxels_TripleOffset = (pfn_Voxels_TripleOffset)dlsym(g_picogk_lib, "Voxels_TripleOffset");
    if (p_Voxels_TripleOffset) p_Voxels_TripleOffset(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_RenderMesh)(PKINSTANCE, PKVOXELS, PKMESH);
static pfn_Voxels_RenderMesh p_Voxels_RenderMesh = NULL;
void Voxels_RenderMesh(PKINSTANCE arg0, PKVOXELS arg1, PKMESH arg2) {
    if (!p_Voxels_RenderMesh) p_Voxels_RenderMesh = (pfn_Voxels_RenderMesh)dlsym(g_picogk_lib, "Voxels_RenderMesh");
    if (p_Voxels_RenderMesh) p_Voxels_RenderMesh(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_RenderImplicit)(PKINSTANCE, PKVOXELS, const_PKBBox3_ptr, PKPFnfSdf);
static pfn_Voxels_RenderImplicit p_Voxels_RenderImplicit = NULL;
void Voxels_RenderImplicit(PKINSTANCE arg0, PKVOXELS arg1, const_PKBBox3_ptr arg2, PKPFnfSdf arg3) {
    if (!p_Voxels_RenderImplicit) p_Voxels_RenderImplicit = (pfn_Voxels_RenderImplicit)dlsym(g_picogk_lib, "Voxels_RenderImplicit");
    if (p_Voxels_RenderImplicit) p_Voxels_RenderImplicit(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Voxels_IntersectImplicit)(PKINSTANCE, PKVOXELS, PKPFnfSdf);
static pfn_Voxels_IntersectImplicit p_Voxels_IntersectImplicit = NULL;
void Voxels_IntersectImplicit(PKINSTANCE arg0, PKVOXELS arg1, PKPFnfSdf arg2) {
    if (!p_Voxels_IntersectImplicit) p_Voxels_IntersectImplicit = (pfn_Voxels_IntersectImplicit)dlsym(g_picogk_lib, "Voxels_IntersectImplicit");
    if (p_Voxels_IntersectImplicit) p_Voxels_IntersectImplicit(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_RenderLattice)(PKINSTANCE, PKVOXELS, PKLATTICE);
static pfn_Voxels_RenderLattice p_Voxels_RenderLattice = NULL;
void Voxels_RenderLattice(PKINSTANCE arg0, PKVOXELS arg1, PKLATTICE arg2) {
    if (!p_Voxels_RenderLattice) p_Voxels_RenderLattice = (pfn_Voxels_RenderLattice)dlsym(g_picogk_lib, "Voxels_RenderLattice");
    if (p_Voxels_RenderLattice) p_Voxels_RenderLattice(arg0, arg1, arg2);
}

typedef void (*pfn_Voxels_ProjectZSlice)(PKINSTANCE, PKVOXELS, float, float);
static pfn_Voxels_ProjectZSlice p_Voxels_ProjectZSlice = NULL;
void Voxels_ProjectZSlice(PKINSTANCE arg0, PKVOXELS arg1, float arg2, float arg3) {
    if (!p_Voxels_ProjectZSlice) p_Voxels_ProjectZSlice = (pfn_Voxels_ProjectZSlice)dlsym(g_picogk_lib, "Voxels_ProjectZSlice");
    if (p_Voxels_ProjectZSlice) p_Voxels_ProjectZSlice(arg0, arg1, arg2, arg3);
}

typedef bool (*pfn_Voxels_bIsInside)(PKINSTANCE, PKVOXELS, const_PKVector3_ptr);
static pfn_Voxels_bIsInside p_Voxels_bIsInside = NULL;
bool Voxels_bIsInside(PKINSTANCE arg0, PKVOXELS arg1, const_PKVector3_ptr arg2) {
    if (!p_Voxels_bIsInside) p_Voxels_bIsInside = (pfn_Voxels_bIsInside)dlsym(g_picogk_lib, "Voxels_bIsInside");
    return p_Voxels_bIsInside ? p_Voxels_bIsInside(arg0, arg1, arg2) : (bool)0;
}

typedef bool (*pfn_Voxels_bIsEqual)(PKINSTANCE, PKVOXELS, PKVOXELS);
static pfn_Voxels_bIsEqual p_Voxels_bIsEqual = NULL;
bool Voxels_bIsEqual(PKINSTANCE arg0, PKVOXELS arg1, PKVOXELS arg2) {
    if (!p_Voxels_bIsEqual) p_Voxels_bIsEqual = (pfn_Voxels_bIsEqual)dlsym(g_picogk_lib, "Voxels_bIsEqual");
    return p_Voxels_bIsEqual ? p_Voxels_bIsEqual(arg0, arg1, arg2) : (bool)0;
}

typedef float (*pfn_Voxels_fCalculateVolume)(PKINSTANCE, PKVOXELS);
static pfn_Voxels_fCalculateVolume p_Voxels_fCalculateVolume = NULL;
float Voxels_fCalculateVolume(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Voxels_fCalculateVolume) p_Voxels_fCalculateVolume = (pfn_Voxels_fCalculateVolume)dlsym(g_picogk_lib, "Voxels_fCalculateVolume");
    return p_Voxels_fCalculateVolume ? p_Voxels_fCalculateVolume(arg0, arg1) : (float)0;
}

typedef void (*pfn_Voxels_GetSurfaceNormal)(PKINSTANCE, PKVOXELS, const_PKVector3_ptr, PKVector3*);
static pfn_Voxels_GetSurfaceNormal p_Voxels_GetSurfaceNormal = NULL;
void Voxels_GetSurfaceNormal(PKINSTANCE arg0, PKVOXELS arg1, const_PKVector3_ptr arg2, PKVector3* arg3) {
    if (!p_Voxels_GetSurfaceNormal) p_Voxels_GetSurfaceNormal = (pfn_Voxels_GetSurfaceNormal)dlsym(g_picogk_lib, "Voxels_GetSurfaceNormal");
    if (p_Voxels_GetSurfaceNormal) p_Voxels_GetSurfaceNormal(arg0, arg1, arg2, arg3);
}

typedef bool (*pfn_Voxels_bClosestPointOnSurface)(PKINSTANCE, PKVOXELS, const_PKVector3_ptr, PKVector3*);
static pfn_Voxels_bClosestPointOnSurface p_Voxels_bClosestPointOnSurface = NULL;
bool Voxels_bClosestPointOnSurface(PKINSTANCE arg0, PKVOXELS arg1, const_PKVector3_ptr arg2, PKVector3* arg3) {
    if (!p_Voxels_bClosestPointOnSurface) p_Voxels_bClosestPointOnSurface = (pfn_Voxels_bClosestPointOnSurface)dlsym(g_picogk_lib, "Voxels_bClosestPointOnSurface");
    return p_Voxels_bClosestPointOnSurface ? p_Voxels_bClosestPointOnSurface(arg0, arg1, arg2, arg3) : (bool)0;
}

typedef bool (*pfn_Voxels_bRayCastToSurface)(PKINSTANCE, PKVOXELS, const_PKVector3_ptr, const_PKVector3_ptr, PKVector3*);
static pfn_Voxels_bRayCastToSurface p_Voxels_bRayCastToSurface = NULL;
bool Voxels_bRayCastToSurface(PKINSTANCE arg0, PKVOXELS arg1, const_PKVector3_ptr arg2, const_PKVector3_ptr arg3, PKVector3* arg4) {
    if (!p_Voxels_bRayCastToSurface) p_Voxels_bRayCastToSurface = (pfn_Voxels_bRayCastToSurface)dlsym(g_picogk_lib, "Voxels_bRayCastToSurface");
    return p_Voxels_bRayCastToSurface ? p_Voxels_bRayCastToSurface(arg0, arg1, arg2, arg3, arg4) : (bool)0;
}

typedef void (*pfn_Voxels_GetVoxelDimensions)(PKINSTANCE, PKVOXELS, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*);
static pfn_Voxels_GetVoxelDimensions p_Voxels_GetVoxelDimensions = NULL;
void Voxels_GetVoxelDimensions(PKINSTANCE arg0, PKVOXELS arg1, int32_t* arg2, int32_t* arg3, int32_t* arg4, int32_t* arg5, int32_t* arg6, int32_t* arg7) {
    if (!p_Voxels_GetVoxelDimensions) p_Voxels_GetVoxelDimensions = (pfn_Voxels_GetVoxelDimensions)dlsym(g_picogk_lib, "Voxels_GetVoxelDimensions");
    if (p_Voxels_GetVoxelDimensions) p_Voxels_GetVoxelDimensions(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
}

typedef void (*pfn_Voxels_GetXSlice)(PKINSTANCE, PKVOXELS, int32_t, float*, float*);
static pfn_Voxels_GetXSlice p_Voxels_GetXSlice = NULL;
void Voxels_GetXSlice(PKINSTANCE arg0, PKVOXELS arg1, int32_t arg2, float* arg3, float* arg4) {
    if (!p_Voxels_GetXSlice) p_Voxels_GetXSlice = (pfn_Voxels_GetXSlice)dlsym(g_picogk_lib, "Voxels_GetXSlice");
    if (p_Voxels_GetXSlice) p_Voxels_GetXSlice(arg0, arg1, arg2, arg3, arg4);
}

typedef void (*pfn_Voxels_GetYSlice)(PKINSTANCE, PKVOXELS, int32_t, float*, float*);
static pfn_Voxels_GetYSlice p_Voxels_GetYSlice = NULL;
void Voxels_GetYSlice(PKINSTANCE arg0, PKVOXELS arg1, int32_t arg2, float* arg3, float* arg4) {
    if (!p_Voxels_GetYSlice) p_Voxels_GetYSlice = (pfn_Voxels_GetYSlice)dlsym(g_picogk_lib, "Voxels_GetYSlice");
    if (p_Voxels_GetYSlice) p_Voxels_GetYSlice(arg0, arg1, arg2, arg3, arg4);
}

typedef void (*pfn_Voxels_GetZSlice)(PKINSTANCE, PKVOXELS, int32_t, float*, float*);
static pfn_Voxels_GetZSlice p_Voxels_GetZSlice = NULL;
void Voxels_GetZSlice(PKINSTANCE arg0, PKVOXELS arg1, int32_t arg2, float* arg3, float* arg4) {
    if (!p_Voxels_GetZSlice) p_Voxels_GetZSlice = (pfn_Voxels_GetZSlice)dlsym(g_picogk_lib, "Voxels_GetZSlice");
    if (p_Voxels_GetZSlice) p_Voxels_GetZSlice(arg0, arg1, arg2, arg3, arg4);
}

typedef void (*pfn_Voxels_GetInterpolatedZSlice)(PKINSTANCE, PKVOXELS, float, float*, float*);
static pfn_Voxels_GetInterpolatedZSlice p_Voxels_GetInterpolatedZSlice = NULL;
void Voxels_GetInterpolatedZSlice(PKINSTANCE arg0, PKVOXELS arg1, float arg2, float* arg3, float* arg4) {
    if (!p_Voxels_GetInterpolatedZSlice) p_Voxels_GetInterpolatedZSlice = (pfn_Voxels_GetInterpolatedZSlice)dlsym(g_picogk_lib, "Voxels_GetInterpolatedZSlice");
    if (p_Voxels_GetInterpolatedZSlice) p_Voxels_GetInterpolatedZSlice(arg0, arg1, arg2, arg3, arg4);
}

typedef PKPOLYLINE (*pfn_PolyLine_hCreate)(PKINSTANCE, const_PKColorFloat_ptr);
static pfn_PolyLine_hCreate p_PolyLine_hCreate = NULL;
PKPOLYLINE PolyLine_hCreate(PKINSTANCE arg0, const_PKColorFloat_ptr arg1) {
    if (!p_PolyLine_hCreate) p_PolyLine_hCreate = (pfn_PolyLine_hCreate)dlsym(g_picogk_lib, "PolyLine_hCreate");
    return p_PolyLine_hCreate ? p_PolyLine_hCreate(arg0, arg1) : (PKPOLYLINE)0;
}

typedef bool (*pfn_PolyLine_bIsValid)(PKINSTANCE, PKPOLYLINE);
static pfn_PolyLine_bIsValid p_PolyLine_bIsValid = NULL;
bool PolyLine_bIsValid(PKINSTANCE arg0, PKPOLYLINE arg1) {
    if (!p_PolyLine_bIsValid) p_PolyLine_bIsValid = (pfn_PolyLine_bIsValid)dlsym(g_picogk_lib, "PolyLine_bIsValid");
    return p_PolyLine_bIsValid ? p_PolyLine_bIsValid(arg0, arg1) : (bool)0;
}

typedef void (*pfn_PolyLine_Destroy)(PKINSTANCE, PKPOLYLINE);
static pfn_PolyLine_Destroy p_PolyLine_Destroy = NULL;
void PolyLine_Destroy(PKINSTANCE arg0, PKPOLYLINE arg1) {
    if (!p_PolyLine_Destroy) p_PolyLine_Destroy = (pfn_PolyLine_Destroy)dlsym(g_picogk_lib, "PolyLine_Destroy");
    if (p_PolyLine_Destroy) p_PolyLine_Destroy(arg0, arg1);
}

typedef int64_t (*pfn_PolyLine_nMemUsage)(PKINSTANCE, PKPOLYLINE);
static pfn_PolyLine_nMemUsage p_PolyLine_nMemUsage = NULL;
int64_t PolyLine_nMemUsage(PKINSTANCE arg0, PKPOLYLINE arg1) {
    if (!p_PolyLine_nMemUsage) p_PolyLine_nMemUsage = (pfn_PolyLine_nMemUsage)dlsym(g_picogk_lib, "PolyLine_nMemUsage");
    return p_PolyLine_nMemUsage ? p_PolyLine_nMemUsage(arg0, arg1) : (int64_t)0;
}

typedef int32_t (*pfn_PolyLine_nAddVertex)(PKINSTANCE, PKPOLYLINE, const_PKVector3_ptr);
static pfn_PolyLine_nAddVertex p_PolyLine_nAddVertex = NULL;
int32_t PolyLine_nAddVertex(PKINSTANCE arg0, PKPOLYLINE arg1, const_PKVector3_ptr arg2) {
    if (!p_PolyLine_nAddVertex) p_PolyLine_nAddVertex = (pfn_PolyLine_nAddVertex)dlsym(g_picogk_lib, "PolyLine_nAddVertex");
    return p_PolyLine_nAddVertex ? p_PolyLine_nAddVertex(arg0, arg1, arg2) : (int32_t)0;
}

typedef int32_t (*pfn_PolyLine_nVertexCount)(PKINSTANCE, PKPOLYLINE);
static pfn_PolyLine_nVertexCount p_PolyLine_nVertexCount = NULL;
int32_t PolyLine_nVertexCount(PKINSTANCE arg0, PKPOLYLINE arg1) {
    if (!p_PolyLine_nVertexCount) p_PolyLine_nVertexCount = (pfn_PolyLine_nVertexCount)dlsym(g_picogk_lib, "PolyLine_nVertexCount");
    return p_PolyLine_nVertexCount ? p_PolyLine_nVertexCount(arg0, arg1) : (int32_t)0;
}

typedef void (*pfn_PolyLine_GetVertex)(PKINSTANCE, PKPOLYLINE, int32_t, PKVector3*);
static pfn_PolyLine_GetVertex p_PolyLine_GetVertex = NULL;
void PolyLine_GetVertex(PKINSTANCE arg0, PKPOLYLINE arg1, int32_t arg2, PKVector3* arg3) {
    if (!p_PolyLine_GetVertex) p_PolyLine_GetVertex = (pfn_PolyLine_GetVertex)dlsym(g_picogk_lib, "PolyLine_GetVertex");
    if (p_PolyLine_GetVertex) p_PolyLine_GetVertex(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_PolyLine_GetColor)(PKINSTANCE, PKPOLYLINE, PKColorFloat*);
static pfn_PolyLine_GetColor p_PolyLine_GetColor = NULL;
void PolyLine_GetColor(PKINSTANCE arg0, PKPOLYLINE arg1, PKColorFloat* arg2) {
    if (!p_PolyLine_GetColor) p_PolyLine_GetColor = (pfn_PolyLine_GetColor)dlsym(g_picogk_lib, "PolyLine_GetColor");
    if (p_PolyLine_GetColor) p_PolyLine_GetColor(arg0, arg1, arg2);
}

typedef void (*pfn_PolyLine_GetBoundingBox)(PKINSTANCE, PKPOLYLINE, PKBBox3*);
static pfn_PolyLine_GetBoundingBox p_PolyLine_GetBoundingBox = NULL;
void PolyLine_GetBoundingBox(PKINSTANCE arg0, PKPOLYLINE arg1, PKBBox3* arg2) {
    if (!p_PolyLine_GetBoundingBox) p_PolyLine_GetBoundingBox = (pfn_PolyLine_GetBoundingBox)dlsym(g_picogk_lib, "PolyLine_GetBoundingBox");
    if (p_PolyLine_GetBoundingBox) p_PolyLine_GetBoundingBox(arg0, arg1, arg2);
}

typedef PKVDBFILE (*pfn_VdbFile_hCreate)(PKINSTANCE);
static pfn_VdbFile_hCreate p_VdbFile_hCreate = NULL;
PKVDBFILE VdbFile_hCreate(PKINSTANCE arg0) {
    if (!p_VdbFile_hCreate) p_VdbFile_hCreate = (pfn_VdbFile_hCreate)dlsym(g_picogk_lib, "VdbFile_hCreate");
    return p_VdbFile_hCreate ? p_VdbFile_hCreate(arg0) : (PKVDBFILE)0;
}

typedef PKVDBFILE (*pfn_VdbFile_hCreateFromFile)(PKINSTANCE, const_char_ptr);
static pfn_VdbFile_hCreateFromFile p_VdbFile_hCreateFromFile = NULL;
PKVDBFILE VdbFile_hCreateFromFile(PKINSTANCE arg0, const_char_ptr arg1) {
    if (!p_VdbFile_hCreateFromFile) p_VdbFile_hCreateFromFile = (pfn_VdbFile_hCreateFromFile)dlsym(g_picogk_lib, "VdbFile_hCreateFromFile");
    return p_VdbFile_hCreateFromFile ? p_VdbFile_hCreateFromFile(arg0, arg1) : (PKVDBFILE)0;
}

typedef bool (*pfn_VdbFile_bIsValid)(PKINSTANCE, PKVDBFILE);
static pfn_VdbFile_bIsValid p_VdbFile_bIsValid = NULL;
bool VdbFile_bIsValid(PKINSTANCE arg0, PKVDBFILE arg1) {
    if (!p_VdbFile_bIsValid) p_VdbFile_bIsValid = (pfn_VdbFile_bIsValid)dlsym(g_picogk_lib, "VdbFile_bIsValid");
    return p_VdbFile_bIsValid ? p_VdbFile_bIsValid(arg0, arg1) : (bool)0;
}

typedef void (*pfn_VdbFile_Destroy)(PKINSTANCE, PKVDBFILE);
static pfn_VdbFile_Destroy p_VdbFile_Destroy = NULL;
void VdbFile_Destroy(PKINSTANCE arg0, PKVDBFILE arg1) {
    if (!p_VdbFile_Destroy) p_VdbFile_Destroy = (pfn_VdbFile_Destroy)dlsym(g_picogk_lib, "VdbFile_Destroy");
    if (p_VdbFile_Destroy) p_VdbFile_Destroy(arg0, arg1);
}

typedef int64_t (*pfn_VdbFile_nMemUsage)(PKINSTANCE, PKVDBFILE);
static pfn_VdbFile_nMemUsage p_VdbFile_nMemUsage = NULL;
int64_t VdbFile_nMemUsage(PKINSTANCE arg0, PKVDBFILE arg1) {
    if (!p_VdbFile_nMemUsage) p_VdbFile_nMemUsage = (pfn_VdbFile_nMemUsage)dlsym(g_picogk_lib, "VdbFile_nMemUsage");
    return p_VdbFile_nMemUsage ? p_VdbFile_nMemUsage(arg0, arg1) : (int64_t)0;
}

typedef bool (*pfn_VdbFile_bSaveToFile)(PKINSTANCE, PKVDBFILE, const_char_ptr);
static pfn_VdbFile_bSaveToFile p_VdbFile_bSaveToFile = NULL;
bool VdbFile_bSaveToFile(PKINSTANCE arg0, PKVDBFILE arg1, const_char_ptr arg2) {
    if (!p_VdbFile_bSaveToFile) p_VdbFile_bSaveToFile = (pfn_VdbFile_bSaveToFile)dlsym(g_picogk_lib, "VdbFile_bSaveToFile");
    return p_VdbFile_bSaveToFile ? p_VdbFile_bSaveToFile(arg0, arg1, arg2) : (bool)0;
}

typedef PKVOXELS (*pfn_VdbFile_hGetVoxels)(PKINSTANCE, PKVDBFILE, int32_t);
static pfn_VdbFile_hGetVoxels p_VdbFile_hGetVoxels = NULL;
PKVOXELS VdbFile_hGetVoxels(PKINSTANCE arg0, PKVDBFILE arg1, int32_t arg2) {
    if (!p_VdbFile_hGetVoxels) p_VdbFile_hGetVoxels = (pfn_VdbFile_hGetVoxels)dlsym(g_picogk_lib, "VdbFile_hGetVoxels");
    return p_VdbFile_hGetVoxels ? p_VdbFile_hGetVoxels(arg0, arg1, arg2) : (PKVOXELS)0;
}

typedef int32_t (*pfn_VdbFile_nAddVoxels)(PKINSTANCE, PKVDBFILE, const_char_ptr, PKVOXELS);
static pfn_VdbFile_nAddVoxels p_VdbFile_nAddVoxels = NULL;
int32_t VdbFile_nAddVoxels(PKINSTANCE arg0, PKVDBFILE arg1, const_char_ptr arg2, PKVOXELS arg3) {
    if (!p_VdbFile_nAddVoxels) p_VdbFile_nAddVoxels = (pfn_VdbFile_nAddVoxels)dlsym(g_picogk_lib, "VdbFile_nAddVoxels");
    return p_VdbFile_nAddVoxels ? p_VdbFile_nAddVoxels(arg0, arg1, arg2, arg3) : (int32_t)0;
}

typedef PKSCALARFIELD (*pfn_VdbFile_hGetScalarField)(PKINSTANCE, PKVDBFILE, int32_t);
static pfn_VdbFile_hGetScalarField p_VdbFile_hGetScalarField = NULL;
PKSCALARFIELD VdbFile_hGetScalarField(PKINSTANCE arg0, PKVDBFILE arg1, int32_t arg2) {
    if (!p_VdbFile_hGetScalarField) p_VdbFile_hGetScalarField = (pfn_VdbFile_hGetScalarField)dlsym(g_picogk_lib, "VdbFile_hGetScalarField");
    return p_VdbFile_hGetScalarField ? p_VdbFile_hGetScalarField(arg0, arg1, arg2) : (PKSCALARFIELD)0;
}

typedef int32_t (*pfn_VdbFile_nAddScalarField)(PKINSTANCE, PKVDBFILE, const_char_ptr, PKSCALARFIELD);
static pfn_VdbFile_nAddScalarField p_VdbFile_nAddScalarField = NULL;
int32_t VdbFile_nAddScalarField(PKINSTANCE arg0, PKVDBFILE arg1, const_char_ptr arg2, PKSCALARFIELD arg3) {
    if (!p_VdbFile_nAddScalarField) p_VdbFile_nAddScalarField = (pfn_VdbFile_nAddScalarField)dlsym(g_picogk_lib, "VdbFile_nAddScalarField");
    return p_VdbFile_nAddScalarField ? p_VdbFile_nAddScalarField(arg0, arg1, arg2, arg3) : (int32_t)0;
}

typedef PKVECTORFIELD (*pfn_VdbFile_hGetVectorField)(PKINSTANCE, PKVDBFILE, int32_t);
static pfn_VdbFile_hGetVectorField p_VdbFile_hGetVectorField = NULL;
PKVECTORFIELD VdbFile_hGetVectorField(PKINSTANCE arg0, PKVDBFILE arg1, int32_t arg2) {
    if (!p_VdbFile_hGetVectorField) p_VdbFile_hGetVectorField = (pfn_VdbFile_hGetVectorField)dlsym(g_picogk_lib, "VdbFile_hGetVectorField");
    return p_VdbFile_hGetVectorField ? p_VdbFile_hGetVectorField(arg0, arg1, arg2) : (PKVECTORFIELD)0;
}

typedef int32_t (*pfn_VdbFile_nAddVectorField)(PKINSTANCE, PKVDBFILE, const_char_ptr, PKVECTORFIELD);
static pfn_VdbFile_nAddVectorField p_VdbFile_nAddVectorField = NULL;
int32_t VdbFile_nAddVectorField(PKINSTANCE arg0, PKVDBFILE arg1, const_char_ptr arg2, PKVECTORFIELD arg3) {
    if (!p_VdbFile_nAddVectorField) p_VdbFile_nAddVectorField = (pfn_VdbFile_nAddVectorField)dlsym(g_picogk_lib, "VdbFile_nAddVectorField");
    return p_VdbFile_nAddVectorField ? p_VdbFile_nAddVectorField(arg0, arg1, arg2, arg3) : (int32_t)0;
}

typedef int32_t (*pfn_VdbFile_nFieldCount)(PKINSTANCE, PKVDBFILE);
static pfn_VdbFile_nFieldCount p_VdbFile_nFieldCount = NULL;
int32_t VdbFile_nFieldCount(PKINSTANCE arg0, PKVDBFILE arg1) {
    if (!p_VdbFile_nFieldCount) p_VdbFile_nFieldCount = (pfn_VdbFile_nFieldCount)dlsym(g_picogk_lib, "VdbFile_nFieldCount");
    return p_VdbFile_nFieldCount ? p_VdbFile_nFieldCount(arg0, arg1) : (int32_t)0;
}

typedef void (*pfn_VdbFile_GetFieldName)(PKINSTANCE, PKVDBFILE, int32_t, char*);
static pfn_VdbFile_GetFieldName p_VdbFile_GetFieldName = NULL;
void VdbFile_GetFieldName(PKINSTANCE arg0, PKVDBFILE arg1, int32_t arg2, char* psz) {
    if (!p_VdbFile_GetFieldName) p_VdbFile_GetFieldName = (pfn_VdbFile_GetFieldName)dlsym(g_picogk_lib, "VdbFile_GetFieldName");
    if (p_VdbFile_GetFieldName) p_VdbFile_GetFieldName(arg0, arg1, arg2, psz);
}

typedef int32_t (*pfn_VdbFile_nFieldType)(PKINSTANCE, PKVDBFILE, int32_t);
static pfn_VdbFile_nFieldType p_VdbFile_nFieldType = NULL;
int32_t VdbFile_nFieldType(PKINSTANCE arg0, PKVDBFILE arg1, int32_t arg2) {
    if (!p_VdbFile_nFieldType) p_VdbFile_nFieldType = (pfn_VdbFile_nFieldType)dlsym(g_picogk_lib, "VdbFile_nFieldType");
    return p_VdbFile_nFieldType ? p_VdbFile_nFieldType(arg0, arg1, arg2) : (int32_t)0;
}

typedef PKSCALARFIELD (*pfn_ScalarField_hCreate)(PKINSTANCE);
static pfn_ScalarField_hCreate p_ScalarField_hCreate = NULL;
PKSCALARFIELD ScalarField_hCreate(PKINSTANCE arg0) {
    if (!p_ScalarField_hCreate) p_ScalarField_hCreate = (pfn_ScalarField_hCreate)dlsym(g_picogk_lib, "ScalarField_hCreate");
    return p_ScalarField_hCreate ? p_ScalarField_hCreate(arg0) : (PKSCALARFIELD)0;
}

typedef PKSCALARFIELD (*pfn_ScalarField_hCreateCopy)(PKINSTANCE, PKSCALARFIELD);
static pfn_ScalarField_hCreateCopy p_ScalarField_hCreateCopy = NULL;
PKSCALARFIELD ScalarField_hCreateCopy(PKINSTANCE arg0, PKSCALARFIELD arg1) {
    if (!p_ScalarField_hCreateCopy) p_ScalarField_hCreateCopy = (pfn_ScalarField_hCreateCopy)dlsym(g_picogk_lib, "ScalarField_hCreateCopy");
    return p_ScalarField_hCreateCopy ? p_ScalarField_hCreateCopy(arg0, arg1) : (PKSCALARFIELD)0;
}

typedef PKSCALARFIELD (*pfn_ScalarField_hCreateFromVoxels)(PKINSTANCE, PKVOXELS);
static pfn_ScalarField_hCreateFromVoxels p_ScalarField_hCreateFromVoxels = NULL;
PKSCALARFIELD ScalarField_hCreateFromVoxels(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_ScalarField_hCreateFromVoxels) p_ScalarField_hCreateFromVoxels = (pfn_ScalarField_hCreateFromVoxels)dlsym(g_picogk_lib, "ScalarField_hCreateFromVoxels");
    return p_ScalarField_hCreateFromVoxels ? p_ScalarField_hCreateFromVoxels(arg0, arg1) : (PKSCALARFIELD)0;
}

typedef PKSCALARFIELD (*pfn_ScalarField_hBuildFromVoxels)(PKINSTANCE, PKVOXELS, float, float);
static pfn_ScalarField_hBuildFromVoxels p_ScalarField_hBuildFromVoxels = NULL;
PKSCALARFIELD ScalarField_hBuildFromVoxels(PKINSTANCE arg0, PKVOXELS arg1, float arg2, float arg3) {
    if (!p_ScalarField_hBuildFromVoxels) p_ScalarField_hBuildFromVoxels = (pfn_ScalarField_hBuildFromVoxels)dlsym(g_picogk_lib, "ScalarField_hBuildFromVoxels");
    return p_ScalarField_hBuildFromVoxels ? p_ScalarField_hBuildFromVoxels(arg0, arg1, arg2, arg3) : (PKSCALARFIELD)0;
}

typedef bool (*pfn_ScalarField_bIsValid)(PKINSTANCE, PKSCALARFIELD);
static pfn_ScalarField_bIsValid p_ScalarField_bIsValid = NULL;
bool ScalarField_bIsValid(PKINSTANCE arg0, PKSCALARFIELD arg1) {
    if (!p_ScalarField_bIsValid) p_ScalarField_bIsValid = (pfn_ScalarField_bIsValid)dlsym(g_picogk_lib, "ScalarField_bIsValid");
    return p_ScalarField_bIsValid ? p_ScalarField_bIsValid(arg0, arg1) : (bool)0;
}

typedef void (*pfn_ScalarField_Destroy)(PKINSTANCE, PKSCALARFIELD);
static pfn_ScalarField_Destroy p_ScalarField_Destroy = NULL;
void ScalarField_Destroy(PKINSTANCE arg0, PKSCALARFIELD arg1) {
    if (!p_ScalarField_Destroy) p_ScalarField_Destroy = (pfn_ScalarField_Destroy)dlsym(g_picogk_lib, "ScalarField_Destroy");
    if (p_ScalarField_Destroy) p_ScalarField_Destroy(arg0, arg1);
}

typedef int64_t (*pfn_ScalarField_nMemUsage)(PKINSTANCE, PKSCALARFIELD);
static pfn_ScalarField_nMemUsage p_ScalarField_nMemUsage = NULL;
int64_t ScalarField_nMemUsage(PKINSTANCE arg0, PKSCALARFIELD arg1) {
    if (!p_ScalarField_nMemUsage) p_ScalarField_nMemUsage = (pfn_ScalarField_nMemUsage)dlsym(g_picogk_lib, "ScalarField_nMemUsage");
    return p_ScalarField_nMemUsage ? p_ScalarField_nMemUsage(arg0, arg1) : (int64_t)0;
}

typedef void (*pfn_ScalarField_SetValue)(PKINSTANCE, PKSCALARFIELD, const_PKVector3_ptr, float);
static pfn_ScalarField_SetValue p_ScalarField_SetValue = NULL;
void ScalarField_SetValue(PKINSTANCE arg0, PKSCALARFIELD arg1, const_PKVector3_ptr arg2, float arg3) {
    if (!p_ScalarField_SetValue) p_ScalarField_SetValue = (pfn_ScalarField_SetValue)dlsym(g_picogk_lib, "ScalarField_SetValue");
    if (p_ScalarField_SetValue) p_ScalarField_SetValue(arg0, arg1, arg2, arg3);
}

typedef bool (*pfn_ScalarField_bGetValue)(PKINSTANCE, PKSCALARFIELD, const_PKVector3_ptr, float*);
static pfn_ScalarField_bGetValue p_ScalarField_bGetValue = NULL;
bool ScalarField_bGetValue(PKINSTANCE arg0, PKSCALARFIELD arg1, const_PKVector3_ptr arg2, float* arg3) {
    if (!p_ScalarField_bGetValue) p_ScalarField_bGetValue = (pfn_ScalarField_bGetValue)dlsym(g_picogk_lib, "ScalarField_bGetValue");
    return p_ScalarField_bGetValue ? p_ScalarField_bGetValue(arg0, arg1, arg2, arg3) : (bool)0;
}

typedef void (*pfn_ScalarField_RemoveValue)(PKINSTANCE, PKSCALARFIELD, const_PKVector3_ptr);
static pfn_ScalarField_RemoveValue p_ScalarField_RemoveValue = NULL;
void ScalarField_RemoveValue(PKINSTANCE arg0, PKSCALARFIELD arg1, const_PKVector3_ptr arg2) {
    if (!p_ScalarField_RemoveValue) p_ScalarField_RemoveValue = (pfn_ScalarField_RemoveValue)dlsym(g_picogk_lib, "ScalarField_RemoveValue");
    if (p_ScalarField_RemoveValue) p_ScalarField_RemoveValue(arg0, arg1, arg2);
}

typedef void (*pfn_ScalarField_GetVoxelDimensions)(PKINSTANCE, PKSCALARFIELD, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*, int32_t*);
static pfn_ScalarField_GetVoxelDimensions p_ScalarField_GetVoxelDimensions = NULL;
void ScalarField_GetVoxelDimensions(PKINSTANCE arg0, PKSCALARFIELD arg1, int32_t* arg2, int32_t* arg3, int32_t* arg4, int32_t* arg5, int32_t* arg6, int32_t* arg7) {
    if (!p_ScalarField_GetVoxelDimensions) p_ScalarField_GetVoxelDimensions = (pfn_ScalarField_GetVoxelDimensions)dlsym(g_picogk_lib, "ScalarField_GetVoxelDimensions");
    if (p_ScalarField_GetVoxelDimensions) p_ScalarField_GetVoxelDimensions(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
}

typedef void (*pfn_ScalarField_GetSlice)(PKINSTANCE, PKSCALARFIELD, int32_t, float*);
static pfn_ScalarField_GetSlice p_ScalarField_GetSlice = NULL;
void ScalarField_GetSlice(PKINSTANCE arg0, PKSCALARFIELD arg1, int32_t arg2, float* arg3) {
    if (!p_ScalarField_GetSlice) p_ScalarField_GetSlice = (pfn_ScalarField_GetSlice)dlsym(g_picogk_lib, "ScalarField_GetSlice");
    if (p_ScalarField_GetSlice) p_ScalarField_GetSlice(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_ScalarField_TraverseActive)(PKINSTANCE, PKSCALARFIELD, PKFnTraverseActiveS);
static pfn_ScalarField_TraverseActive p_ScalarField_TraverseActive = NULL;
void ScalarField_TraverseActive(PKINSTANCE arg0, PKSCALARFIELD arg1, PKFnTraverseActiveS arg2) {
    if (!p_ScalarField_TraverseActive) p_ScalarField_TraverseActive = (pfn_ScalarField_TraverseActive)dlsym(g_picogk_lib, "ScalarField_TraverseActive");
    if (p_ScalarField_TraverseActive) p_ScalarField_TraverseActive(arg0, arg1, arg2);
}

typedef PKVECTORFIELD (*pfn_VectorField_hCreate)(PKINSTANCE);
static pfn_VectorField_hCreate p_VectorField_hCreate = NULL;
PKVECTORFIELD VectorField_hCreate(PKINSTANCE arg0) {
    if (!p_VectorField_hCreate) p_VectorField_hCreate = (pfn_VectorField_hCreate)dlsym(g_picogk_lib, "VectorField_hCreate");
    return p_VectorField_hCreate ? p_VectorField_hCreate(arg0) : (PKVECTORFIELD)0;
}

typedef PKVECTORFIELD (*pfn_VectorField_hCreateCopy)(PKINSTANCE, PKVECTORFIELD);
static pfn_VectorField_hCreateCopy p_VectorField_hCreateCopy = NULL;
PKVECTORFIELD VectorField_hCreateCopy(PKINSTANCE arg0, PKVECTORFIELD arg1) {
    if (!p_VectorField_hCreateCopy) p_VectorField_hCreateCopy = (pfn_VectorField_hCreateCopy)dlsym(g_picogk_lib, "VectorField_hCreateCopy");
    return p_VectorField_hCreateCopy ? p_VectorField_hCreateCopy(arg0, arg1) : (PKVECTORFIELD)0;
}

typedef PKVECTORFIELD (*pfn_VectorField_hCreateFromVoxels)(PKINSTANCE, PKVOXELS);
static pfn_VectorField_hCreateFromVoxels p_VectorField_hCreateFromVoxels = NULL;
PKVECTORFIELD VectorField_hCreateFromVoxels(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_VectorField_hCreateFromVoxels) p_VectorField_hCreateFromVoxels = (pfn_VectorField_hCreateFromVoxels)dlsym(g_picogk_lib, "VectorField_hCreateFromVoxels");
    return p_VectorField_hCreateFromVoxels ? p_VectorField_hCreateFromVoxels(arg0, arg1) : (PKVECTORFIELD)0;
}

typedef PKVECTORFIELD (*pfn_VectorField_hBuildFromVoxels)(PKINSTANCE, PKVOXELS, const_PKVector3_ptr, float);
static pfn_VectorField_hBuildFromVoxels p_VectorField_hBuildFromVoxels = NULL;
PKVECTORFIELD VectorField_hBuildFromVoxels(PKINSTANCE arg0, PKVOXELS arg1, const_PKVector3_ptr arg2, float arg3) {
    if (!p_VectorField_hBuildFromVoxels) p_VectorField_hBuildFromVoxels = (pfn_VectorField_hBuildFromVoxels)dlsym(g_picogk_lib, "VectorField_hBuildFromVoxels");
    return p_VectorField_hBuildFromVoxels ? p_VectorField_hBuildFromVoxels(arg0, arg1, arg2, arg3) : (PKVECTORFIELD)0;
}

typedef bool (*pfn_VectorField_bIsValid)(PKINSTANCE, PKVECTORFIELD);
static pfn_VectorField_bIsValid p_VectorField_bIsValid = NULL;
bool VectorField_bIsValid(PKINSTANCE arg0, PKVECTORFIELD arg1) {
    if (!p_VectorField_bIsValid) p_VectorField_bIsValid = (pfn_VectorField_bIsValid)dlsym(g_picogk_lib, "VectorField_bIsValid");
    return p_VectorField_bIsValid ? p_VectorField_bIsValid(arg0, arg1) : (bool)0;
}

typedef void (*pfn_VectorField_Destroy)(PKINSTANCE, PKVECTORFIELD);
static pfn_VectorField_Destroy p_VectorField_Destroy = NULL;
void VectorField_Destroy(PKINSTANCE arg0, PKVECTORFIELD arg1) {
    if (!p_VectorField_Destroy) p_VectorField_Destroy = (pfn_VectorField_Destroy)dlsym(g_picogk_lib, "VectorField_Destroy");
    if (p_VectorField_Destroy) p_VectorField_Destroy(arg0, arg1);
}

typedef int64_t (*pfn_VectorField_nMemUsage)(PKINSTANCE, PKVECTORFIELD);
static pfn_VectorField_nMemUsage p_VectorField_nMemUsage = NULL;
int64_t VectorField_nMemUsage(PKINSTANCE arg0, PKVECTORFIELD arg1) {
    if (!p_VectorField_nMemUsage) p_VectorField_nMemUsage = (pfn_VectorField_nMemUsage)dlsym(g_picogk_lib, "VectorField_nMemUsage");
    return p_VectorField_nMemUsage ? p_VectorField_nMemUsage(arg0, arg1) : (int64_t)0;
}

typedef void (*pfn_VectorField_SetValue)(PKINSTANCE, PKVECTORFIELD, const_PKVector3_ptr, const_PKVector3_ptr);
static pfn_VectorField_SetValue p_VectorField_SetValue = NULL;
void VectorField_SetValue(PKINSTANCE arg0, PKVECTORFIELD arg1, const_PKVector3_ptr arg2, const_PKVector3_ptr arg3) {
    if (!p_VectorField_SetValue) p_VectorField_SetValue = (pfn_VectorField_SetValue)dlsym(g_picogk_lib, "VectorField_SetValue");
    if (p_VectorField_SetValue) p_VectorField_SetValue(arg0, arg1, arg2, arg3);
}

typedef bool (*pfn_VectorField_bGetValue)(PKINSTANCE, PKVECTORFIELD, const_PKVector3_ptr, PKVector3*);
static pfn_VectorField_bGetValue p_VectorField_bGetValue = NULL;
bool VectorField_bGetValue(PKINSTANCE arg0, PKVECTORFIELD arg1, const_PKVector3_ptr arg2, PKVector3* arg3) {
    if (!p_VectorField_bGetValue) p_VectorField_bGetValue = (pfn_VectorField_bGetValue)dlsym(g_picogk_lib, "VectorField_bGetValue");
    return p_VectorField_bGetValue ? p_VectorField_bGetValue(arg0, arg1, arg2, arg3) : (bool)0;
}

typedef void (*pfn_VectorField_RemoveValue)(PKINSTANCE, PKVECTORFIELD, const_PKVector3_ptr);
static pfn_VectorField_RemoveValue p_VectorField_RemoveValue = NULL;
void VectorField_RemoveValue(PKINSTANCE arg0, PKVECTORFIELD arg1, const_PKVector3_ptr arg2) {
    if (!p_VectorField_RemoveValue) p_VectorField_RemoveValue = (pfn_VectorField_RemoveValue)dlsym(g_picogk_lib, "VectorField_RemoveValue");
    if (p_VectorField_RemoveValue) p_VectorField_RemoveValue(arg0, arg1, arg2);
}

typedef void (*pfn_VectorField_TraverseActive)(PKINSTANCE, PKVECTORFIELD, PKFnTraverseActiveV);
static pfn_VectorField_TraverseActive p_VectorField_TraverseActive = NULL;
void VectorField_TraverseActive(PKINSTANCE arg0, PKVECTORFIELD arg1, PKFnTraverseActiveV arg2) {
    if (!p_VectorField_TraverseActive) p_VectorField_TraverseActive = (pfn_VectorField_TraverseActive)dlsym(g_picogk_lib, "VectorField_TraverseActive");
    if (p_VectorField_TraverseActive) p_VectorField_TraverseActive(arg0, arg1, arg2);
}

typedef PKMETADATA (*pfn_Metadata_hFromVoxels)(PKINSTANCE, PKVOXELS);
static pfn_Metadata_hFromVoxels p_Metadata_hFromVoxels = NULL;
PKMETADATA Metadata_hFromVoxels(PKINSTANCE arg0, PKVOXELS arg1) {
    if (!p_Metadata_hFromVoxels) p_Metadata_hFromVoxels = (pfn_Metadata_hFromVoxels)dlsym(g_picogk_lib, "Metadata_hFromVoxels");
    return p_Metadata_hFromVoxels ? p_Metadata_hFromVoxels(arg0, arg1) : (PKMETADATA)0;
}

typedef PKMETADATA (*pfn_Metadata_hFromScalarField)(PKINSTANCE, PKSCALARFIELD);
static pfn_Metadata_hFromScalarField p_Metadata_hFromScalarField = NULL;
PKMETADATA Metadata_hFromScalarField(PKINSTANCE arg0, PKSCALARFIELD arg1) {
    if (!p_Metadata_hFromScalarField) p_Metadata_hFromScalarField = (pfn_Metadata_hFromScalarField)dlsym(g_picogk_lib, "Metadata_hFromScalarField");
    return p_Metadata_hFromScalarField ? p_Metadata_hFromScalarField(arg0, arg1) : (PKMETADATA)0;
}

typedef PKMETADATA (*pfn_Metadata_hFromVectorField)(PKINSTANCE, PKVECTORFIELD);
static pfn_Metadata_hFromVectorField p_Metadata_hFromVectorField = NULL;
PKMETADATA Metadata_hFromVectorField(PKINSTANCE arg0, PKVECTORFIELD arg1) {
    if (!p_Metadata_hFromVectorField) p_Metadata_hFromVectorField = (pfn_Metadata_hFromVectorField)dlsym(g_picogk_lib, "Metadata_hFromVectorField");
    return p_Metadata_hFromVectorField ? p_Metadata_hFromVectorField(arg0, arg1) : (PKMETADATA)0;
}

typedef void (*pfn_Metadata_Destroy)(PKINSTANCE, PKMETADATA);
static pfn_Metadata_Destroy p_Metadata_Destroy = NULL;
void Metadata_Destroy(PKINSTANCE arg0, PKMETADATA arg1) {
    if (!p_Metadata_Destroy) p_Metadata_Destroy = (pfn_Metadata_Destroy)dlsym(g_picogk_lib, "Metadata_Destroy");
    if (p_Metadata_Destroy) p_Metadata_Destroy(arg0, arg1);
}

typedef int32_t (*pfn_Metadata_nCount)(PKINSTANCE, PKMETADATA);
static pfn_Metadata_nCount p_Metadata_nCount = NULL;
int32_t Metadata_nCount(PKINSTANCE arg0, PKMETADATA arg1) {
    if (!p_Metadata_nCount) p_Metadata_nCount = (pfn_Metadata_nCount)dlsym(g_picogk_lib, "Metadata_nCount");
    return p_Metadata_nCount ? p_Metadata_nCount(arg0, arg1) : (int32_t)0;
}

typedef int32_t (*pfn_Metadata_nNameLengthAt)(PKINSTANCE, PKMETADATA, int32_t);
static pfn_Metadata_nNameLengthAt p_Metadata_nNameLengthAt = NULL;
int32_t Metadata_nNameLengthAt(PKINSTANCE arg0, PKMETADATA arg1, int32_t arg2) {
    if (!p_Metadata_nNameLengthAt) p_Metadata_nNameLengthAt = (pfn_Metadata_nNameLengthAt)dlsym(g_picogk_lib, "Metadata_nNameLengthAt");
    return p_Metadata_nNameLengthAt ? p_Metadata_nNameLengthAt(arg0, arg1, arg2) : (int32_t)0;
}

typedef bool (*pfn_Metadata_bGetNameAt)(PKINSTANCE, PKMETADATA, int32_t, char*, int32_t);
static pfn_Metadata_bGetNameAt p_Metadata_bGetNameAt = NULL;
bool Metadata_bGetNameAt(PKINSTANCE arg0, PKMETADATA arg1, int32_t arg2, char* arg3, int32_t arg4) {
    if (!p_Metadata_bGetNameAt) p_Metadata_bGetNameAt = (pfn_Metadata_bGetNameAt)dlsym(g_picogk_lib, "Metadata_bGetNameAt");
    return p_Metadata_bGetNameAt ? p_Metadata_bGetNameAt(arg0, arg1, arg2, arg3, arg4) : (bool)0;
}

typedef int32_t (*pfn_Metadata_nTypeAt)(PKINSTANCE, PKMETADATA, const_char_ptr);
static pfn_Metadata_nTypeAt p_Metadata_nTypeAt = NULL;
int32_t Metadata_nTypeAt(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2) {
    if (!p_Metadata_nTypeAt) p_Metadata_nTypeAt = (pfn_Metadata_nTypeAt)dlsym(g_picogk_lib, "Metadata_nTypeAt");
    return p_Metadata_nTypeAt ? p_Metadata_nTypeAt(arg0, arg1, arg2) : (int32_t)0;
}

typedef int32_t (*pfn_Metadata_nStringLengthAt)(PKINSTANCE, PKMETADATA, const_char_ptr);
static pfn_Metadata_nStringLengthAt p_Metadata_nStringLengthAt = NULL;
int32_t Metadata_nStringLengthAt(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2) {
    if (!p_Metadata_nStringLengthAt) p_Metadata_nStringLengthAt = (pfn_Metadata_nStringLengthAt)dlsym(g_picogk_lib, "Metadata_nStringLengthAt");
    return p_Metadata_nStringLengthAt ? p_Metadata_nStringLengthAt(arg0, arg1, arg2) : (int32_t)0;
}

typedef bool (*pfn_Metadata_bGetStringAt)(PKINSTANCE, PKMETADATA, const_char_ptr, char*, int32_t);
static pfn_Metadata_bGetStringAt p_Metadata_bGetStringAt = NULL;
bool Metadata_bGetStringAt(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2, char* arg3, int32_t arg4) {
    if (!p_Metadata_bGetStringAt) p_Metadata_bGetStringAt = (pfn_Metadata_bGetStringAt)dlsym(g_picogk_lib, "Metadata_bGetStringAt");
    return p_Metadata_bGetStringAt ? p_Metadata_bGetStringAt(arg0, arg1, arg2, arg3, arg4) : (bool)0;
}

typedef bool (*pfn_Metadata_bGetFloatAt)(PKINSTANCE, PKMETADATA, const_char_ptr, float*);
static pfn_Metadata_bGetFloatAt p_Metadata_bGetFloatAt = NULL;
bool Metadata_bGetFloatAt(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2, float* arg3) {
    if (!p_Metadata_bGetFloatAt) p_Metadata_bGetFloatAt = (pfn_Metadata_bGetFloatAt)dlsym(g_picogk_lib, "Metadata_bGetFloatAt");
    return p_Metadata_bGetFloatAt ? p_Metadata_bGetFloatAt(arg0, arg1, arg2, arg3) : (bool)0;
}

typedef bool (*pfn_Metadata_bGetVectorAt)(PKINSTANCE, PKMETADATA, const_char_ptr, PKVector3*);
static pfn_Metadata_bGetVectorAt p_Metadata_bGetVectorAt = NULL;
bool Metadata_bGetVectorAt(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2, PKVector3* arg3) {
    if (!p_Metadata_bGetVectorAt) p_Metadata_bGetVectorAt = (pfn_Metadata_bGetVectorAt)dlsym(g_picogk_lib, "Metadata_bGetVectorAt");
    return p_Metadata_bGetVectorAt ? p_Metadata_bGetVectorAt(arg0, arg1, arg2, arg3) : (bool)0;
}

typedef void (*pfn_Metadata_SetStringValue)(PKINSTANCE, PKMETADATA, const_char_ptr, const_char_ptr);
static pfn_Metadata_SetStringValue p_Metadata_SetStringValue = NULL;
void Metadata_SetStringValue(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2, const_char_ptr arg3) {
    if (!p_Metadata_SetStringValue) p_Metadata_SetStringValue = (pfn_Metadata_SetStringValue)dlsym(g_picogk_lib, "Metadata_SetStringValue");
    if (p_Metadata_SetStringValue) p_Metadata_SetStringValue(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Metadata_SetFloatValue)(PKINSTANCE, PKMETADATA, const_char_ptr, float);
static pfn_Metadata_SetFloatValue p_Metadata_SetFloatValue = NULL;
void Metadata_SetFloatValue(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2, float arg3) {
    if (!p_Metadata_SetFloatValue) p_Metadata_SetFloatValue = (pfn_Metadata_SetFloatValue)dlsym(g_picogk_lib, "Metadata_SetFloatValue");
    if (p_Metadata_SetFloatValue) p_Metadata_SetFloatValue(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Metadata_SetVectorValue)(PKINSTANCE, PKMETADATA, const_char_ptr, const_PKVector3_ptr);
static pfn_Metadata_SetVectorValue p_Metadata_SetVectorValue = NULL;
void Metadata_SetVectorValue(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2, const_PKVector3_ptr arg3) {
    if (!p_Metadata_SetVectorValue) p_Metadata_SetVectorValue = (pfn_Metadata_SetVectorValue)dlsym(g_picogk_lib, "Metadata_SetVectorValue");
    if (p_Metadata_SetVectorValue) p_Metadata_SetVectorValue(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_MetaData_RemoveValue)(PKINSTANCE, PKMETADATA, const_char_ptr);
static pfn_MetaData_RemoveValue p_MetaData_RemoveValue = NULL;
void MetaData_RemoveValue(PKINSTANCE arg0, PKMETADATA arg1, const_char_ptr arg2) {
    if (!p_MetaData_RemoveValue) p_MetaData_RemoveValue = (pfn_MetaData_RemoveValue)dlsym(g_picogk_lib, "MetaData_RemoveValue");
    if (p_MetaData_RemoveValue) p_MetaData_RemoveValue(arg0, arg1, arg2);
}

typedef PKVIEWER (*pfn_Viewer_hCreate)(const_char_ptr, const_PKVector2_ptr, PKFInfo, PKPFUpdateRequested, PKPFKeyPressed, PKPFMouseMoved, PKPFMouseButton, PKPFScrollWheel, PKPFWindowSize);
static pfn_Viewer_hCreate p_Viewer_hCreate = NULL;
PKVIEWER Viewer_hCreate(const_char_ptr arg0, const_PKVector2_ptr arg1, PKFInfo arg2, PKPFUpdateRequested arg3, PKPFKeyPressed arg4, PKPFMouseMoved arg5, PKPFMouseButton arg6, PKPFScrollWheel arg7, PKPFWindowSize arg8) {
    if (!p_Viewer_hCreate) p_Viewer_hCreate = (pfn_Viewer_hCreate)dlsym(g_picogk_lib, "Viewer_hCreate");
    return p_Viewer_hCreate ? p_Viewer_hCreate(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8) : (PKVIEWER)0;
}

typedef bool (*pfn_Viewer_bIsValid)(PKVIEWER);
static pfn_Viewer_bIsValid p_Viewer_bIsValid = NULL;
bool Viewer_bIsValid(PKVIEWER arg0) {
    if (!p_Viewer_bIsValid) p_Viewer_bIsValid = (pfn_Viewer_bIsValid)dlsym(g_picogk_lib, "Viewer_bIsValid");
    return p_Viewer_bIsValid ? p_Viewer_bIsValid(arg0) : (bool)0;
}

typedef void (*pfn_Viewer_Destroy)(PKVIEWER);
static pfn_Viewer_Destroy p_Viewer_Destroy = NULL;
void Viewer_Destroy(PKVIEWER arg0) {
    if (!p_Viewer_Destroy) p_Viewer_Destroy = (pfn_Viewer_Destroy)dlsym(g_picogk_lib, "Viewer_Destroy");
    if (p_Viewer_Destroy) p_Viewer_Destroy(arg0);
}

typedef void (*pfn_Viewer_RequestUpdate)(PKVIEWER);
static pfn_Viewer_RequestUpdate p_Viewer_RequestUpdate = NULL;
void Viewer_RequestUpdate(PKVIEWER arg0) {
    if (!p_Viewer_RequestUpdate) p_Viewer_RequestUpdate = (pfn_Viewer_RequestUpdate)dlsym(g_picogk_lib, "Viewer_RequestUpdate");
    if (p_Viewer_RequestUpdate) p_Viewer_RequestUpdate(arg0);
}

typedef bool (*pfn_Viewer_bPoll)(PKVIEWER);
static pfn_Viewer_bPoll p_Viewer_bPoll = NULL;
bool Viewer_bPoll(PKVIEWER arg0) {
    if (!p_Viewer_bPoll) p_Viewer_bPoll = (pfn_Viewer_bPoll)dlsym(g_picogk_lib, "Viewer_bPoll");
    return p_Viewer_bPoll ? p_Viewer_bPoll(arg0) : (bool)0;
}

typedef void (*pfn_Viewer_RequestScreenShot)(PKVIEWER, const_char_ptr);
static pfn_Viewer_RequestScreenShot p_Viewer_RequestScreenShot = NULL;
void Viewer_RequestScreenShot(PKVIEWER arg0, const_char_ptr arg1) {
    if (!p_Viewer_RequestScreenShot) p_Viewer_RequestScreenShot = (pfn_Viewer_RequestScreenShot)dlsym(g_picogk_lib, "Viewer_RequestScreenShot");
    if (p_Viewer_RequestScreenShot) p_Viewer_RequestScreenShot(arg0, arg1);
}

typedef void (*pfn_Viewer_EnableExperimental)(PKVIEWER, bool);
static pfn_Viewer_EnableExperimental p_Viewer_EnableExperimental = NULL;
void Viewer_EnableExperimental(PKVIEWER arg0, bool arg1) {
    if (!p_Viewer_EnableExperimental) p_Viewer_EnableExperimental = (pfn_Viewer_EnableExperimental)dlsym(g_picogk_lib, "Viewer_EnableExperimental");
    if (p_Viewer_EnableExperimental) p_Viewer_EnableExperimental(arg0, arg1);
}

typedef void (*pfn_Viewer_RequestClose)(PKVIEWER);
static pfn_Viewer_RequestClose p_Viewer_RequestClose = NULL;
void Viewer_RequestClose(PKVIEWER arg0) {
    if (!p_Viewer_RequestClose) p_Viewer_RequestClose = (pfn_Viewer_RequestClose)dlsym(g_picogk_lib, "Viewer_RequestClose");
    if (p_Viewer_RequestClose) p_Viewer_RequestClose(arg0);
}

typedef bool (*pfn_Viewer_bLoadLightSetup)(PKVIEWER, const_char_ptr, int32_t, const_char_ptr, int32_t);
static pfn_Viewer_bLoadLightSetup p_Viewer_bLoadLightSetup = NULL;
bool Viewer_bLoadLightSetup(PKVIEWER arg0, const_char_ptr arg1, int32_t arg2, const_char_ptr arg3, int32_t arg4) {
    if (!p_Viewer_bLoadLightSetup) p_Viewer_bLoadLightSetup = (pfn_Viewer_bLoadLightSetup)dlsym(g_picogk_lib, "Viewer_bLoadLightSetup");
    return p_Viewer_bLoadLightSetup ? p_Viewer_bLoadLightSetup(arg0, arg1, arg2, arg3, arg4) : (bool)0;
}

typedef void (*pfn_Viewer_AddMesh)(PKINSTANCE, PKVIEWER, int32_t, PKMESH);
static pfn_Viewer_AddMesh p_Viewer_AddMesh = NULL;
void Viewer_AddMesh(PKINSTANCE arg0, PKVIEWER arg1, int32_t arg2, PKMESH arg3) {
    if (!p_Viewer_AddMesh) p_Viewer_AddMesh = (pfn_Viewer_AddMesh)dlsym(g_picogk_lib, "Viewer_AddMesh");
    if (p_Viewer_AddMesh) p_Viewer_AddMesh(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Viewer_RemoveMesh)(PKINSTANCE, PKVIEWER, PKMESH);
static pfn_Viewer_RemoveMesh p_Viewer_RemoveMesh = NULL;
void Viewer_RemoveMesh(PKINSTANCE arg0, PKVIEWER arg1, PKMESH arg2) {
    if (!p_Viewer_RemoveMesh) p_Viewer_RemoveMesh = (pfn_Viewer_RemoveMesh)dlsym(g_picogk_lib, "Viewer_RemoveMesh");
    if (p_Viewer_RemoveMesh) p_Viewer_RemoveMesh(arg0, arg1, arg2);
}

typedef void (*pfn_Viewer_SetMeshMatrix)(PKINSTANCE, PKVIEWER, PKMESH, const_PKMatrix4x4_ptr);
static pfn_Viewer_SetMeshMatrix p_Viewer_SetMeshMatrix = NULL;
void Viewer_SetMeshMatrix(PKINSTANCE arg0, PKVIEWER arg1, PKMESH arg2, const_PKMatrix4x4_ptr arg3) {
    if (!p_Viewer_SetMeshMatrix) p_Viewer_SetMeshMatrix = (pfn_Viewer_SetMeshMatrix)dlsym(g_picogk_lib, "Viewer_SetMeshMatrix");
    if (p_Viewer_SetMeshMatrix) p_Viewer_SetMeshMatrix(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Viewer_AddVoxels)(PKINSTANCE, PKVIEWER, int32_t, PKVOXELS);
static pfn_Viewer_AddVoxels p_Viewer_AddVoxels = NULL;
void Viewer_AddVoxels(PKINSTANCE arg0, PKVIEWER arg1, int32_t arg2, PKVOXELS arg3) {
    if (!p_Viewer_AddVoxels) p_Viewer_AddVoxels = (pfn_Viewer_AddVoxels)dlsym(g_picogk_lib, "Viewer_AddVoxels");
    if (p_Viewer_AddVoxels) p_Viewer_AddVoxels(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Viewer_RemoveVoxels)(PKINSTANCE, PKVIEWER, PKVOXELS);
static pfn_Viewer_RemoveVoxels p_Viewer_RemoveVoxels = NULL;
void Viewer_RemoveVoxels(PKINSTANCE arg0, PKVIEWER arg1, PKVOXELS arg2) {
    if (!p_Viewer_RemoveVoxels) p_Viewer_RemoveVoxels = (pfn_Viewer_RemoveVoxels)dlsym(g_picogk_lib, "Viewer_RemoveVoxels");
    if (p_Viewer_RemoveVoxels) p_Viewer_RemoveVoxels(arg0, arg1, arg2);
}

typedef void (*pfn_Viewer_SetVoxelsMatrix)(PKINSTANCE, PKVIEWER, PKVOXELS, const_PKMatrix4x4_ptr);
static pfn_Viewer_SetVoxelsMatrix p_Viewer_SetVoxelsMatrix = NULL;
void Viewer_SetVoxelsMatrix(PKINSTANCE arg0, PKVIEWER arg1, PKVOXELS arg2, const_PKMatrix4x4_ptr arg3) {
    if (!p_Viewer_SetVoxelsMatrix) p_Viewer_SetVoxelsMatrix = (pfn_Viewer_SetVoxelsMatrix)dlsym(g_picogk_lib, "Viewer_SetVoxelsMatrix");
    if (p_Viewer_SetVoxelsMatrix) p_Viewer_SetVoxelsMatrix(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Viewer_AddPolyLine)(PKINSTANCE, PKVIEWER, int32_t, PKPOLYLINE);
static pfn_Viewer_AddPolyLine p_Viewer_AddPolyLine = NULL;
void Viewer_AddPolyLine(PKINSTANCE arg0, PKVIEWER arg1, int32_t arg2, PKPOLYLINE arg3) {
    if (!p_Viewer_AddPolyLine) p_Viewer_AddPolyLine = (pfn_Viewer_AddPolyLine)dlsym(g_picogk_lib, "Viewer_AddPolyLine");
    if (p_Viewer_AddPolyLine) p_Viewer_AddPolyLine(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Viewer_RemovePolyLine)(PKINSTANCE, PKVIEWER, PKPOLYLINE);
static pfn_Viewer_RemovePolyLine p_Viewer_RemovePolyLine = NULL;
void Viewer_RemovePolyLine(PKINSTANCE arg0, PKVIEWER arg1, PKPOLYLINE arg2) {
    if (!p_Viewer_RemovePolyLine) p_Viewer_RemovePolyLine = (pfn_Viewer_RemovePolyLine)dlsym(g_picogk_lib, "Viewer_RemovePolyLine");
    if (p_Viewer_RemovePolyLine) p_Viewer_RemovePolyLine(arg0, arg1, arg2);
}

typedef void (*pfn_Viewer_SetPolyLineMatrix)(PKINSTANCE, PKVIEWER, PKPOLYLINE, const_PKMatrix4x4_ptr);
static pfn_Viewer_SetPolyLineMatrix p_Viewer_SetPolyLineMatrix = NULL;
void Viewer_SetPolyLineMatrix(PKINSTANCE arg0, PKVIEWER arg1, PKPOLYLINE arg2, const_PKMatrix4x4_ptr arg3) {
    if (!p_Viewer_SetPolyLineMatrix) p_Viewer_SetPolyLineMatrix = (pfn_Viewer_SetPolyLineMatrix)dlsym(g_picogk_lib, "Viewer_SetPolyLineMatrix");
    if (p_Viewer_SetPolyLineMatrix) p_Viewer_SetPolyLineMatrix(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Viewer_RemoveAllObjects)(PKVIEWER);
static pfn_Viewer_RemoveAllObjects p_Viewer_RemoveAllObjects = NULL;
void Viewer_RemoveAllObjects(PKVIEWER arg0) {
    if (!p_Viewer_RemoveAllObjects) p_Viewer_RemoveAllObjects = (pfn_Viewer_RemoveAllObjects)dlsym(g_picogk_lib, "Viewer_RemoveAllObjects");
    if (p_Viewer_RemoveAllObjects) p_Viewer_RemoveAllObjects(arg0);
}

typedef void (*pfn_Viewer_SetGroupVisible)(PKVIEWER, int32_t, bool);
static pfn_Viewer_SetGroupVisible p_Viewer_SetGroupVisible = NULL;
void Viewer_SetGroupVisible(PKVIEWER arg0, int32_t arg1, bool arg2) {
    if (!p_Viewer_SetGroupVisible) p_Viewer_SetGroupVisible = (pfn_Viewer_SetGroupVisible)dlsym(g_picogk_lib, "Viewer_SetGroupVisible");
    if (p_Viewer_SetGroupVisible) p_Viewer_SetGroupVisible(arg0, arg1, arg2);
}

typedef void (*pfn_Viewer_SetGroupMaterial)(PKVIEWER, int32_t, const_PKColorFloat_ptr, float, float);
static pfn_Viewer_SetGroupMaterial p_Viewer_SetGroupMaterial = NULL;
void Viewer_SetGroupMaterial(PKVIEWER arg0, int32_t arg1, const_PKColorFloat_ptr arg2, float arg3, float arg4) {
    if (!p_Viewer_SetGroupMaterial) p_Viewer_SetGroupMaterial = (pfn_Viewer_SetGroupMaterial)dlsym(g_picogk_lib, "Viewer_SetGroupMaterial");
    if (p_Viewer_SetGroupMaterial) p_Viewer_SetGroupMaterial(arg0, arg1, arg2, arg3, arg4);
}

typedef void (*pfn_Viewer_SetGroupMatrix)(PKVIEWER, int32_t, const_PKMatrix4x4_ptr);
static pfn_Viewer_SetGroupMatrix p_Viewer_SetGroupMatrix = NULL;
void Viewer_SetGroupMatrix(PKVIEWER arg0, int32_t arg1, const_PKMatrix4x4_ptr arg2) {
    if (!p_Viewer_SetGroupMatrix) p_Viewer_SetGroupMatrix = (pfn_Viewer_SetGroupMatrix)dlsym(g_picogk_lib, "Viewer_SetGroupMatrix");
    if (p_Viewer_SetGroupMatrix) p_Viewer_SetGroupMatrix(arg0, arg1, arg2);
}

typedef void (*pfn_Viewer_EnableGroupWarnOverhang)(PKVIEWER, int32_t, float, float);
static pfn_Viewer_EnableGroupWarnOverhang p_Viewer_EnableGroupWarnOverhang = NULL;
void Viewer_EnableGroupWarnOverhang(PKVIEWER arg0, int32_t arg1, float arg2, float arg3) {
    if (!p_Viewer_EnableGroupWarnOverhang) p_Viewer_EnableGroupWarnOverhang = (pfn_Viewer_EnableGroupWarnOverhang)dlsym(g_picogk_lib, "Viewer_EnableGroupWarnOverhang");
    if (p_Viewer_EnableGroupWarnOverhang) p_Viewer_EnableGroupWarnOverhang(arg0, arg1, arg2, arg3);
}

typedef void (*pfn_Viewer_DisableGroupWarnOverhang)(PKVIEWER, int32_t);
static pfn_Viewer_DisableGroupWarnOverhang p_Viewer_DisableGroupWarnOverhang = NULL;
void Viewer_DisableGroupWarnOverhang(PKVIEWER arg0, int32_t arg1) {
    if (!p_Viewer_DisableGroupWarnOverhang) p_Viewer_DisableGroupWarnOverhang = (pfn_Viewer_DisableGroupWarnOverhang)dlsym(g_picogk_lib, "Viewer_DisableGroupWarnOverhang");
    if (p_Viewer_DisableGroupWarnOverhang) p_Viewer_DisableGroupWarnOverhang(arg0, arg1);
}

typedef void (*pfn_Viewer_GetBoundingBox)(PKVIEWER, PKBBox3*);
static pfn_Viewer_GetBoundingBox p_Viewer_GetBoundingBox = NULL;
void Viewer_GetBoundingBox(PKVIEWER arg0, PKBBox3* arg1) {
    if (!p_Viewer_GetBoundingBox) p_Viewer_GetBoundingBox = (pfn_Viewer_GetBoundingBox)dlsym(g_picogk_lib, "Viewer_GetBoundingBox");
    if (p_Viewer_GetBoundingBox) p_Viewer_GetBoundingBox(arg0, arg1);
}

typedef PKGPUTEX (*pfn_Viewer_GpuTex_hCreate)(PKVIEWER, int, int, const_char_ptr);
static pfn_Viewer_GpuTex_hCreate p_Viewer_GpuTex_hCreate = NULL;
PKGPUTEX Viewer_GpuTex_hCreate(PKVIEWER arg0, int arg1, int arg2, const_char_ptr arg3) {
    if (!p_Viewer_GpuTex_hCreate) p_Viewer_GpuTex_hCreate = (pfn_Viewer_GpuTex_hCreate)dlsym(g_picogk_lib, "Viewer_GpuTex_hCreate");
    return p_Viewer_GpuTex_hCreate ? p_Viewer_GpuTex_hCreate(arg0, arg1, arg2, arg3) : (PKGPUTEX)0;
}

typedef void (*pfn_Viewer_GpuTex_Refresh)(PKVIEWER, PKGPUTEX, const_char_ptr);
static pfn_Viewer_GpuTex_Refresh p_Viewer_GpuTex_Refresh = NULL;
void Viewer_GpuTex_Refresh(PKVIEWER arg0, PKGPUTEX arg1, const_char_ptr arg2) {
    if (!p_Viewer_GpuTex_Refresh) p_Viewer_GpuTex_Refresh = (pfn_Viewer_GpuTex_Refresh)dlsym(g_picogk_lib, "Viewer_GpuTex_Refresh");
    if (p_Viewer_GpuTex_Refresh) p_Viewer_GpuTex_Refresh(arg0, arg1, arg2);
}

typedef void (*pfn_Viewer_GpuTex_MarkForCleanup)(PKVIEWER, PKGPUTEX);
static pfn_Viewer_GpuTex_MarkForCleanup p_Viewer_GpuTex_MarkForCleanup = NULL;
void Viewer_GpuTex_MarkForCleanup(PKVIEWER arg0, PKGPUTEX arg1) {
    if (!p_Viewer_GpuTex_MarkForCleanup) p_Viewer_GpuTex_MarkForCleanup = (pfn_Viewer_GpuTex_MarkForCleanup)dlsym(g_picogk_lib, "Viewer_GpuTex_MarkForCleanup");
    if (p_Viewer_GpuTex_MarkForCleanup) p_Viewer_GpuTex_MarkForCleanup(arg0, arg1);
}

typedef PKQUAD (*pfn_Viewer_Quad_hCreate)(PKVIEWER, PKGPUTEX, PKColorFloat, float, const_PKMatrix4x4_ptr, bool, bool, bool);
static pfn_Viewer_Quad_hCreate p_Viewer_Quad_hCreate = NULL;
PKQUAD Viewer_Quad_hCreate(PKVIEWER arg0, PKGPUTEX arg1, PKColorFloat arg2, float arg3, const_PKMatrix4x4_ptr arg4, bool arg5, bool arg6, bool arg7) {
    if (!p_Viewer_Quad_hCreate) p_Viewer_Quad_hCreate = (pfn_Viewer_Quad_hCreate)dlsym(g_picogk_lib, "Viewer_Quad_hCreate");
    return p_Viewer_Quad_hCreate ? p_Viewer_Quad_hCreate(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) : (PKQUAD)0;
}

typedef void (*pfn_Viewer_Quad_Destroy)(PKVIEWER, PKQUAD);
static pfn_Viewer_Quad_Destroy p_Viewer_Quad_Destroy = NULL;
void Viewer_Quad_Destroy(PKVIEWER arg0, PKQUAD arg1) {
    if (!p_Viewer_Quad_Destroy) p_Viewer_Quad_Destroy = (pfn_Viewer_Quad_Destroy)dlsym(g_picogk_lib, "Viewer_Quad_Destroy");
    if (p_Viewer_Quad_Destroy) p_Viewer_Quad_Destroy(arg0, arg1);
}

typedef void (*pfn_Viewer_Quad_SetMatrix)(PKVIEWER, PKQUAD, const_PKMatrix4x4_ptr);
static pfn_Viewer_Quad_SetMatrix p_Viewer_Quad_SetMatrix = NULL;
void Viewer_Quad_SetMatrix(PKVIEWER arg0, PKQUAD arg1, const_PKMatrix4x4_ptr arg2) {
    if (!p_Viewer_Quad_SetMatrix) p_Viewer_Quad_SetMatrix = (pfn_Viewer_Quad_SetMatrix)dlsym(g_picogk_lib, "Viewer_Quad_SetMatrix");
    if (p_Viewer_Quad_SetMatrix) p_Viewer_Quad_SetMatrix(arg0, arg1, arg2);
}

typedef PKGUI (*pfn_Viewer_SideBar_hCreate)(PKVIEWER, bool, int, int, int, PKColorFloat, PKColorFloat);
static pfn_Viewer_SideBar_hCreate p_Viewer_SideBar_hCreate = NULL;
PKGUI Viewer_SideBar_hCreate(PKVIEWER arg0, bool arg1, int arg2, int arg3, int arg4, PKColorFloat arg5, PKColorFloat arg6) {
    if (!p_Viewer_SideBar_hCreate) p_Viewer_SideBar_hCreate = (pfn_Viewer_SideBar_hCreate)dlsym(g_picogk_lib, "Viewer_SideBar_hCreate");
    return p_Viewer_SideBar_hCreate ? p_Viewer_SideBar_hCreate(arg0, arg1, arg2, arg3, arg4, arg5, arg6) : (PKGUI)0;
}

typedef void (*pfn_Viewer_SideBar_Destroy)(PKVIEWER, PKGUI);
static pfn_Viewer_SideBar_Destroy p_Viewer_SideBar_Destroy = NULL;
void Viewer_SideBar_Destroy(PKVIEWER arg0, PKGUI arg1) {
    if (!p_Viewer_SideBar_Destroy) p_Viewer_SideBar_Destroy = (pfn_Viewer_SideBar_Destroy)dlsym(g_picogk_lib, "Viewer_SideBar_Destroy");
    if (p_Viewer_SideBar_Destroy) p_Viewer_SideBar_Destroy(arg0, arg1);
}
